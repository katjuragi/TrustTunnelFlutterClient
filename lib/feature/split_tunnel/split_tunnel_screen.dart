import 'package:flutter/material.dart';
import 'package:trusttunnel/common/assets/asset_icons.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/common/localization/localization.dart';
import 'package:trusttunnel/data/model/vpn_state.dart';
import 'package:trusttunnel/feature/routing/routing/widgets/scope/routing_scope.dart';
import 'package:trusttunnel/feature/server/servers/widget/scope/servers_scope.dart';
import 'package:trusttunnel/feature/settings/excluded_routes/widgets/scope/excluded_routes_scope.dart';
import 'package:trusttunnel/feature/vpn/widgets/vpn_scope.dart';
import 'package:trusttunnel/widgets/custom_app_bar.dart';
import 'package:trusttunnel/widgets/scaffold_wrapper.dart';
import 'package:vpn_plugin/split_tunnel.dart';

/// Per-app split tunneling screen.
///
/// Lets the user choose which applications the VPN applies to. Settings are
/// stored natively and picked up by the VPN service when the tunnel starts.
class SplitTunnelScreen extends StatefulWidget {
  const SplitTunnelScreen({super.key});

  @override
  State<SplitTunnelScreen> createState() => _SplitTunnelScreenState();
}

class _SplitTunnelScreenState extends State<SplitTunnelScreen> {
  static const _manager = SplitTunnelManager();

  SplitTunnelMode _mode = SplitTunnelMode.allApps;
  Set<String> _selectedPackages = {};
  List<InstalledApp>? _apps;
  bool _loadFailed = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _manager.getSettings();
      final apps = await _manager.getInstalledApps();
      if (!mounted) {
        return;
      }
      setState(() {
        _mode = settings.mode;
        _selectedPackages = {...settings.packages};
        _apps = apps;
        _loadFailed = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  Future<void> _save() async {
    await _manager.setSettings(
      SplitTunnelSettings(
        mode: _mode,
        packages: _selectedPackages,
      ),
    );
    _promptReconnectIfConnected();
  }

  /// Split rules only take effect when the tunnel is (re)built, so when a change
  /// is made while connected we offer to reconnect immediately.
  void _promptReconnectIfConnected() {
    if (!mounted) {
      return;
    }
    final vpn = VpnScope.vpnControllerMaybeOf(context, listen: false);
    if (vpn == null || vpn.state != VpnState.connected) {
      return;
    }

    context.showInfoSnackBar(
      message: context.ln.splitTunnelingReconnect,
      action: SnackBarAction(
        label: context.ln.reconnect,
        onPressed: _reconnect,
      ),
    );
  }

  Future<void> _reconnect() async {
    final vpn = VpnScope.vpnControllerOf(context, listen: false);
    final server = ServersScope.controllerOf(context, listen: false).selectedServer;
    if (server == null) {
      return;
    }
    final excludedRoutes = ExcludedRoutesScope.controllerOf(context, listen: false).excludedRoutes;
    final routingProfile = RoutingScope.controllerOf(context, listen: false).routingList.firstWhere(
      (element) => element.id == server.serverData.routingProfileId,
    );

    await vpn.stop();
    await vpn.start(
      server: server,
      routingProfile: routingProfile,
      excludedRoutes: excludedRoutes,
    );
  }

  void _setMode(SplitTunnelMode mode) {
    setState(() => _mode = mode);
    _save();
  }

  void _togglePackage(String packageName) {
    setState(() {
      if (!_selectedPackages.remove(packageName)) {
        _selectedPackages.add(packageName);
      }
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final apps = _apps;
    final selectionEnabled = _mode != SplitTunnelMode.allApps;
    final filteredApps = apps == null
        ? const <InstalledApp>[]
        : apps
              .where(
                (app) =>
                    _searchQuery.isEmpty ||
                    app.name.toLowerCase().contains(_searchQuery) ||
                    app.packageName.toLowerCase().contains(_searchQuery),
              )
              .toList();

    return ScaffoldWrapper(
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.ln.splitTunneling,
        ),
        body: Column(
          children: [
            _ModeTile(
              title: context.ln.splitTunnelingAllApps,
              subtitle: context.ln.splitTunnelingAllAppsDescription,
              selected: _mode == SplitTunnelMode.allApps,
              onTap: () => _setMode(SplitTunnelMode.allApps),
            ),
            _ModeTile(
              title: context.ln.splitTunnelingOnlySelected,
              subtitle: context.ln.splitTunnelingOnlySelectedDescription,
              selected: _mode == SplitTunnelMode.onlySelected,
              onTap: () => _setMode(SplitTunnelMode.onlySelected),
            ),
            _ModeTile(
              title: context.ln.splitTunnelingAllExcept,
              subtitle: context.ln.splitTunnelingAllExceptDescription,
              selected: _mode == SplitTunnelMode.allExceptSelected,
              onTap: () => _setMode(SplitTunnelMode.allExceptSelected),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.ln.splitTunnelingHint,
                  style: context.textTheme.bodySmall,
                ),
              ),
            ),
            const Divider(height: 1),
            if (selectionEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: context.ln.searchApps,
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                ),
              ),
            Expanded(
              child: _buildAppList(context, apps, filteredApps, selectionEnabled),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppList(
    BuildContext context,
    List<InstalledApp>? apps,
    List<InstalledApp> filteredApps,
    bool selectionEnabled,
  ) {
    if (_loadFailed) {
      return Center(
        child: Text(
          context.ln.appsLoadError,
          style: context.textTheme.bodyMedium,
        ),
      );
    }

    if (apps == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!selectionEnabled) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      itemCount: filteredApps.length,
      itemBuilder: (context, index) {
        final app = filteredApps[index];
        final checked = _selectedPackages.contains(app.packageName);

        return ListTile(
          dense: true,
          leading: app.icon.isEmpty
              ? const SizedBox.square(dimension: 36)
              : Image.memory(
                  app.icon,
                  width: 36,
                  height: 36,
                  gaplessPlayback: true,
                ),
          title: Text(
            app.name,
            style: context.textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            app.packageName,
            style: context.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            checked ? AssetIcons.checkBoxFilled : AssetIcons.checkBox,
            color: checked ? context.colors.accent : context.colors.neutralLight,
          ),
          onTap: () => _togglePackage(app.packageName),
        );
      },
    );
  }
}

class _ModeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(
      selected ? AssetIcons.radioButtonChecked : AssetIcons.radioButtonUnchecked,
      color: selected ? context.colors.accent : context.colors.neutralLight,
    ),
    title: Text(
      title,
      style: context.textTheme.bodyLarge,
    ),
    subtitle: Text(
      subtitle,
      style: context.textTheme.bodySmall,
    ),
    onTap: onTap,
  );
}
