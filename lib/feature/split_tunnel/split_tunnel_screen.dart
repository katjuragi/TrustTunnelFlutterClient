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
  bool _settingsLoaded = false;
  bool _loadFailed = false;
  bool _saving = false;
  bool _saveFailed = false;
  bool _reconnectPromptShown = false;
  int _saveRevision = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _manager.getSettings();
      if (!mounted) return;

      setState(() {
        _mode = settings.mode;
        _selectedPackages = {...settings.packages};
        _settingsLoaded = true;
        _loadFailed = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _loadFailed = true);
      }

      return;
    }

    try {
      final apps = await _manager.getInstalledApps();
      if (!mounted) return;

      setState(() {
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
    if (!_settingsLoaded) return;

    final revision = ++_saveRevision;
    final settings = SplitTunnelSettings(
      mode: _mode,
      packages: {..._selectedPackages},
    );

    setState(() {
      _saving = true;
      _saveFailed = false;
    });

    try {
      await _manager.setSettings(settings);
      if (!mounted || revision != _saveRevision) return;

      setState(() {
        _saving = false;
        _saveFailed = false;
      });
      _promptReconnectIfConnected();
    } on Object {
      if (!mounted || revision != _saveRevision) return;

      setState(() {
        _saving = false;
        _saveFailed = true;
      });
      context.showInfoSnackBar(message: context.ln.splitTunnelingSaveError);
    }
  }

  /// Split rules only take effect when the tunnel is (re)built, so when a change
  /// is made while connected we offer to reconnect immediately.
  void _promptReconnectIfConnected() {
    if (!mounted || _reconnectPromptShown) return;
    final vpn = VpnScope.vpnControllerMaybeOf(context, listen: false);
    if (vpn == null || vpn.state != VpnState.connected) return;

    _reconnectPromptShown = true;
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
    if (server == null) return;
    final excludedRoutes = ExcludedRoutesScope.controllerOf(context, listen: false).excludedRoutes;
    final routingProfile = RoutingScope.controllerOf(context, listen: false).routingList.firstWhere(
      (element) => element.id == server.serverData.routingProfileId,
    );

    try {
      await vpn.stop();
      await vpn.start(
        server: server,
        routingProfile: routingProfile,
        excludedRoutes: excludedRoutes,
      );
    } finally {
      _reconnectPromptShown = false;
    }
  }

  void _setMode(SplitTunnelMode mode) {
    if (_mode == mode) return;
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

    final selectedCount = _selectedPackages.length;

    return ScaffoldWrapper(
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.ln.splitTunneling,
          actions: [
            _SaveStatus(
              visible: _settingsLoaded,
              saving: _saving,
              failed: _saveFailed,
              onRetry: _save,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // ─── Mode selector ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _ModeSelector(
                mode: _mode,
                onModeChanged: _setMode,
              ),
            ),

            // ─── Hint ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(
                    AssetIcons.error,
                    size: 14,
                    color: context.colors.neutralDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.ln.splitTunnelingHint,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.neutralDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (selectionEnabled) ...[
              // ─── Search bar ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: context.ln.searchApps,
                          isDense: true,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: context.colors.neutralDark,
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.trim().toLowerCase()),
                      ),
                    ),
                    if (selectedCount > 0) ...[
                      const SizedBox(width: 10),
                      _CountBadge(count: selectedCount),
                    ],
                  ],
                ),
              ),
            ],

            // ─── App list ────────────────────────────────────────
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AssetIcons.error, size: 48, color: context.colors.neutralDark),
            const SizedBox(height: 12),
            Text(
              context.ln.appsLoadError,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: Text(context.ln.retry),
            ),
          ],
        ),
      );
    }

    if (apps == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!selectionEnabled) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AssetIcons.locationOff,
              size: 56,
              color: context.colors.neutralLight,
            ),
            const SizedBox(height: 12),
            Text(
              context.ln.splitTunnelingAllAppsActive,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.neutralDark,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredApps.isEmpty) {
      return Center(
        child: Text(
          context.ln.noAppsFound,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.neutralDark,
          ),
        ),
      );
    }

    // Split user / system apps
    final userApps = filteredApps.where((a) => !a.isSystem).toList();
    final systemApps = filteredApps.where((a) => a.isSystem).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 104),
      children: [
        if (userApps.isNotEmpty) ...[
          _SectionHeader(
            title: context.ln.splitTunnelingAppsSection(userApps.length),
          ),
          for (final app in userApps)
            _AppTile(
              app: app,
              checked: _selectedPackages.contains(app.packageName),
              onTap: () => _togglePackage(app.packageName),
            ),
        ],
        if (systemApps.isNotEmpty) ...[
          _SectionHeader(
            title: context.ln.splitTunnelingSystemAppsSection(systemApps.length),
          ),
          for (final app in systemApps)
            _AppTile(
              app: app,
              checked: _selectedPackages.contains(app.packageName),
              onTap: () => _togglePackage(app.packageName),
            ),
        ],
      ],
    );
  }
}

// ─── Mode Selector ─────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  final SplitTunnelMode mode;
  final ValueChanged<SplitTunnelMode> onModeChanged;

  const _ModeSelector({
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.backgroundAdditional,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            _ModeTile(
              icon: AssetIcons.locationOn,
              title: context.ln.splitTunnelingAllApps,
              subtitle: context.ln.splitTunnelingAllAppsDescription,
              selected: mode == SplitTunnelMode.allApps,
              onTap: () => onModeChanged(SplitTunnelMode.allApps),
            ),
            const SizedBox(height: 4),
            _ModeTile(
              icon: AssetIcons.checkBoxFilled,
              title: context.ln.splitTunnelingOnlySelected,
              subtitle: context.ln.splitTunnelingOnlySelectedDescription,
              selected: mode == SplitTunnelMode.onlySelected,
              onTap: () => onModeChanged(SplitTunnelMode.onlySelected),
            ),
            const SizedBox(height: 4),
            _ModeTile(
              icon: AssetIcons.locationOff,
              title: context.ln.splitTunnelingAllExcept,
              subtitle: context.ln.splitTunnelingAllExceptDescription,
              selected: mode == SplitTunnelMode.allExceptSelected,
              onTap: () => onModeChanged(SplitTunnelMode.allExceptSelected),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? accent.withValues(alpha: 0.2)
                    : context.colors.neutralLight.withValues(alpha: 0.15),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? accent : context.colors.neutralDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? accent : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.neutralDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? AssetIcons.radioButtonChecked : AssetIcons.radioButtonUnchecked,
              color: selected ? accent : context.colors.neutralLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Tile ──────────────────────────────────────────────────────────────

class _AppTile extends StatelessWidget {
  final InstalledApp app;
  final bool checked;
  final VoidCallback onTap;

  const _AppTile({
    required this.app,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: Material(
      color: checked ? context.colors.accent.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: app.icon.isEmpty
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.neutralLight.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AssetIcons.settings,
                  size: 20,
                  color: context.colors.neutralDark,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  app.icon,
                  width: 40,
                  height: 40,
                  gaplessPlayback: true,
                ),
              ),
        title: Text(
          app.name,
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: checked ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          app.packageName,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.neutralDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            checked ? AssetIcons.checkBoxFilled : AssetIcons.checkBox,
            key: ValueKey(checked),
            color: checked ? context.colors.accent : context.colors.neutralLight,
          ),
        ),
        onTap: onTap,
      ),
    ),
  );
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      title.toUpperCase(),
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colors.neutralDark,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ─── Count badge ───────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: Container(
      key: ValueKey(count),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.ln.selectedAppsCount(count),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ─── Auto-save status ──────────────────────────────────────────────────────

class _SaveStatus extends StatelessWidget {
  final bool visible;
  final bool saving;
  final bool failed;
  final VoidCallback onRetry;

  const _SaveStatus({
    required this.visible,
    required this.saving,
    required this.failed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(width: 40);

    if (saving) {
      return Tooltip(
        message: context.ln.savingChanges,
        child: const SizedBox.square(
          dimension: 40,
          child: Center(
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (failed) {
      return IconButton(
        tooltip: context.ln.retrySave,
        onPressed: onRetry,
        icon: Icon(
          AssetIcons.error,
          color: context.colors.error,
        ),
      );
    }

    return Tooltip(
      message: context.ln.savedAutomatically,
      child: SizedBox.square(
        dimension: 40,
        child: Icon(
          AssetIcons.checkSmall,
          size: 20,
          color: context.colors.accent,
        ),
      ),
    );
  }
}
