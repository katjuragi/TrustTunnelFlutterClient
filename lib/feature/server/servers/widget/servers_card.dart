import 'package:flutter/material.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/data/model/server.dart';
import 'package:trusttunnel/feature/server/server_details/widgets/server_details_popup.dart';
import 'package:trusttunnel/feature/server/servers/widget/scope/servers_scope.dart';

/// Ping measurement state for a single server.
enum ServerPingStatus { none, inProgress, done }

/// A configuration row: tap selects the server, long press opens the editor.
/// The selected configuration is highlighted with a grey background.
class ServersCard extends StatelessWidget {
  final Server server;
  final bool selected;
  final ServerPingStatus pingStatus;
  final int? pingMs;

  const ServersCard({
    super.key,
    required this.server,
    required this.selected,
    this.pingStatus = ServerPingStatus.none,
    this.pingMs,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.colors.neutralLight.withValues(alpha: 0.35) : Colors.transparent,
    child: InkWell(
      onTap: () => _selectServer(context),
      onLongPress: () => _pushServerDetailsScreen(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.serverData.name,
                    style: context.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    server.serverData.ipAddress,
                    style: context.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _PingLabel(
              status: pingStatus,
              pingMs: pingMs,
            ),
          ],
        ),
      ),
    ),
  );

  void _selectServer(BuildContext context) =>
      ServersScope.controllerOf(context, listen: false).pickServer(server.id);

  void _pushServerDetailsScreen(BuildContext context) async {
    final controller = ServersScope.controllerOf(context, listen: false);

    await context.push(
      ServerDetailsPopUp(
        serverId: server.id,
      ),
    );

    controller.fetchServers();
  }
}

class _PingLabel extends StatelessWidget {
  final ServerPingStatus status;
  final int? pingMs;

  const _PingLabel({
    required this.status,
    required this.pingMs,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ServerPingStatus.none:
        return const SizedBox.shrink();
      case ServerPingStatus.inProgress:
        return const SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ServerPingStatus.done:
        final ping = pingMs;
        if (ping == null) {
          return Text(
            '—',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.error,
            ),
          );
        }

        final Color color;
        if (ping < 100) {
          color = Colors.green;
        } else if (ping < 250) {
          color = Colors.orange;
        } else {
          color = context.colors.error;
        }

        return Text(
          '$ping ms',
          style: context.textTheme.bodyMedium?.copyWith(color: color),
        );
    }
  }
}
