import 'dart:ui';

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

  // The last-saved state — used to detect unsaved changes.
  SplitTunnelMode _savedMode = SplitTunnelMode.allApps;
  Set<String> _savedPackages = {};

  List<InstalledApp>? _apps;
  bool _loadFailed = false;
  bool _saving = false;
  String _searchQuery = '';

  bool get _hasUnsavedChanges =>
      _mode != _savedMode ||
      !_selectedPackages.containsAll(_savedPackages) ||
      !_savedPackages.containsAll(_selectedPackages);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _manager.getSettings();
      final apps = await _manager.getInstalledApps();
      if (!mounted) return;
      setState(() {
        _mode = settings.mode;
        _selectedPackages = {...settings.packages};
        _savedMode = settings.mode;
        _savedPackages = {...settings.packages};
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
    if (!_hasUnsavedChanges || _saving) return;
    setState(() => _saving = true);
    try {
      await _manager.setSettings(
        SplitTunnelSettings(
          mode: _mode,
          packages: _selectedPackages,
        ),
      );
      if (!mounted) return;
      setState(() {
        _savedMode = _mode;
        _savedPackages = {..._selectedPackages};
      });
      context.showInfoSnackBar(message: context.ln.changesSavedSnackbar);
      _promptReconnectIfConnected();
    } on Object {
      if (mounted) {
        context.showInfoSnackBar(message: context.ln.appsLoadError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Split rules only take effect when the tunnel is (re)built, so when a change
  /// is made while connected we offer to reconnect immediately.
  void _promptReconnectIfConnected() {
    if (!mounted) return;
    final vpn = VpnScope.vpnControllerMaybeOf(context, listen: false);
    if (vpn == null || vpn.state != VpnState.connected) return;

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

    await vpn.stop();
    await vpn.start(
      server: server,
      routingProfile: routingProfile,
      excludedRoutes: excludedRoutes,
    );
  }

  void _setMode(SplitTunnelMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
  }

  void _togglePackage(String packageName) {
    setState(() {
      if (!_selectedPackages.remove(packageName)) {
        _selectedPackages.add(packageName);
      }
    });
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
              const Divider(height: 1),
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
                            AssetIcons.sort,
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

            // ─── Save button (shown only when there are unsaved changes) ─
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _hasUnsavedChanges
                  ? _SaveBar(
                      saving: _saving,
                      onSave: _save,
                    )
                  : const SizedBox.shrink(),
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
            TextButton(onPressed: _load, child: const Text('Retry')),
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
              'All apps use the VPN',
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
          'No apps found',
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
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (userApps.isNotEmpty) ...[
          _SectionHeader(title: 'Apps (${userApps.length})'),
          for (final app in userApps)
            _AppTile(
              app: app,
              checked: _selectedPackages.contains(app.packageName),
              onTap: () => _togglePackage(app.packageName),
            ),
        ],
        if (systemApps.isNotEmpty) ...[
          _SectionHeader(title: 'System (${systemApps.length})'),
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
    final isDark = context.theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isDark ? Colors.white : context.colors.accent).withValues(alpha: isDark ? 0.12 : 0.08),
                (isDark ? Colors.white : context.colors.accent).withValues(alpha: isDark ? 0.04 : 0.02),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.4),
            ),
          ),
          child: Column(
            children: [
              _ModeTile(
                icon: AssetIcons.locationOn,
                title: context.ln.splitTunnelingAllApps,
                subtitle: context.ln.splitTunnelingAllAppsDescription,
                selected: mode == SplitTunnelMode.allApps,
                isFirst: true,
                isLast: false,
                onTap: () => onModeChanged(SplitTunnelMode.allApps),
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
              ),
              _ModeTile(
                icon: AssetIcons.checkBoxFilled,
                title: context.ln.splitTunnelingOnlySelected,
                subtitle: context.ln.splitTunnelingOnlySelectedDescription,
                selected: mode == SplitTunnelMode.onlySelected,
                isFirst: false,
                isLast: false,
                onTap: () => onModeChanged(SplitTunnelMode.onlySelected),
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
              ),
              _ModeTile(
                icon: AssetIcons.locationOff,
                title: context.ln.splitTunnelingAllExcept,
                subtitle: context.ln.splitTunnelingAllExceptDescription,
                selected: mode == SplitTunnelMode.allExceptSelected,
                isFirst: false,
                isLast: true,
                onTap: () => onModeChanged(SplitTunnelMode.allExceptSelected),
              ),
            ],
          ),
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
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(20) : Radius.zero,
            bottom: isLast ? const Radius.circular(20) : Radius.zero,
          ),
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
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: app.icon.isEmpty
        ? Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.neutralLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(AssetIcons.settings, size: 20, color: context.colors.neutralDark),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              app.icon,
              width: 36,
              height: 36,
              gaplessPlayback: true,
            ),
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
    trailing: AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Icon(
        key: ValueKey(checked),
        checked ? AssetIcons.checkBoxFilled : AssetIcons.checkBox,
        color: checked ? context.colors.accent : context.colors.neutralLight,
      ),
    ),
    onTap: onTap,
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
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$count selected',
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ─── Save bar ──────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;

  const _SaveBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.5 : 0.7),
                (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.7 : 0.9),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.5),
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(AssetIcons.check, size: 18),
              label: Text(saving ? 'Saving…' : context.ln.save),
            ),
          ),
        ),
      ),
    );
  }
}
