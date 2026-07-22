import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:trusttunnel/common/assets/asset_icons.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/common/localization/localization.dart';
import 'package:trusttunnel/data/model/server.dart';
import 'package:trusttunnel/data/model/vpn_state.dart';
import 'package:trusttunnel/feature/routing/routing/widgets/scope/routing_scope.dart';
import 'package:trusttunnel/feature/server/servers/widget/scope/servers_scope.dart';
import 'package:trusttunnel/feature/server/servers/widget/scope/servers_scope_aspect.dart';
import 'package:trusttunnel/feature/settings/excluded_routes/widgets/scope/excluded_routes_scope.dart';
import 'package:trusttunnel/feature/vpn/widgets/vpn_scope.dart';
import 'package:trusttunnel/widgets/glass_container.dart';
import 'package:trusttunnel/widgets/rotating_wrapper.dart';

/// Large central connect/disconnect button with the current connection status.
///
/// Toggles the VPN for the selected server (or the first one, if nothing is
/// selected yet).
class ServersConnectionPanel extends StatelessWidget {
  static const double _buttonSize = 168;

  const ServersConnectionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vpnState = VpnScope.vpnControllerOf(context).state;
    final controller = ServersScope.controllerOf(
      context,
      aspect: ServersScopeAspect.servers,
    );
    final server = controller.selectedServer ?? controller.servers.firstOrNull;
    final pending = vpnState != VpnState.connected && vpnState != VpnState.disconnected;
    final connected = vpnState == VpnState.connected;

    final Color buttonColor;
    if (server == null) {
      buttonColor = context.colors.accentDisabled;
    } else if (connected || pending) {
      buttonColor = context.colors.accent;
    } else {
      buttonColor = context.colors.neutralDark;
    }

    return GlassContainer(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Material(
            color: buttonColor,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: server == null ? null : () => _toggleVpn(context, server, vpnState),
              child: SizedBox.square(
                dimension: _buttonSize,
                child: Center(
                  child: pending
                      ? RotatingWidget(
                          duration: const Duration(seconds: 1),
                          child: Icon(
                            AssetIcons.update,
                            size: 64,
                            color: context.colors.specialStaticWhite,
                          ),
                        )
                      : Icon(
                          AssetIcons.powerSettingsNew,
                          size: 64,
                          color: context.colors.specialStaticWhite,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _statusTitle(context, vpnState),
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            server == null
                ? context.ln.addServerToConnect
                : connected
                ? '${server.serverData.name} · ${context.ln.tapToDisconnect}'
                : '${server.serverData.name} · ${context.ln.tapToConnect}',
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _statusTitle(BuildContext context, VpnState state) => switch (state) {
    VpnState.connected => context.ln.vpnStateConnected,
    VpnState.disconnected => context.ln.vpnStateDisconnected,
    _ => context.ln.vpnStateConnecting,
  };

  void _toggleVpn(BuildContext context, Server server, VpnState vpnState) {
    if (vpnState != VpnState.disconnected) {
      VpnScope.vpnControllerOf(context, listen: false).stop();

      return;
    }

    final serversController = ServersScope.controllerOf(context, listen: false);
    if (serversController.selectedServer == null) {
      serversController.pickServer(server.id);
    }

    _connectToVpn(context, server);
  }

  Future<void> _connectToVpn(
    BuildContext context,
    Server server,
  ) async {
    final controller = VpnScope.vpnControllerOf(context, listen: false);
    final excludedRoutes = ExcludedRoutesScope.controllerOf(context, listen: false).excludedRoutes;
    final routingProfile = RoutingScope.controllerOf(context, listen: false).routingList.firstWhere(
      (element) => element.id == server.serverData.routingProfileId,
    );

    await controller.start(
      server: server,
      routingProfile: routingProfile,
      excludedRoutes: excludedRoutes,
    );
  }
}
