import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trusttunnel/common/assets/asset_icons.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/common/localization/localization.dart';
import 'package:trusttunnel/common/router/app_routes.dart';
import 'package:trusttunnel/common/utils/ping_utils.dart';
import 'package:trusttunnel/common/utils/routing_profile_utils.dart';
import 'package:trusttunnel/data/model/server.dart';
import 'package:trusttunnel/data/model/server_data.dart';
import 'package:trusttunnel/feature/server/server_details/domain/service/server_details_service.dart';
import 'package:trusttunnel/feature/server/server_details/widgets/server_details_popup.dart';
import 'package:trusttunnel/feature/server/servers/widget/scope/servers_scope.dart';
import 'package:trusttunnel/feature/server/servers/widget/scope/servers_scope_aspect.dart';
import 'package:trusttunnel/feature/server/servers/widget/servers_card.dart';
import 'package:trusttunnel/feature/server/servers/widget/servers_connection_panel.dart';
import 'package:trusttunnel/feature/server/servers/widget/servers_empty_placeholder.dart';
import 'package:trusttunnel/widgets/buttons/custom_floating_action_button.dart';
import 'package:trusttunnel/widgets/buttons/custom_outlined_button.dart';
import 'package:trusttunnel/widgets/common/scaffold_messenger_provider.dart';
import 'package:trusttunnel/widgets/custom_app_bar.dart';
import 'package:trusttunnel/widgets/scaffold_wrapper.dart';

class ServersScreenView extends StatefulWidget {
  final ServerData? deepLinkData;

  const ServersScreenView({
    super.key,
    this.deepLinkData,
  });

  @override
  State<ServersScreenView> createState() => _ServersScreenViewState();
}

class _ServersScreenViewState extends State<ServersScreenView> {
  late List<Server> _servers;
  late final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  bool _importingFromClipboard = false;
  bool _pinging = false;
  final Map<String, int?> _pingResults = {};

  @override
  void initState() {
    super.initState();
    final initialController = ServersScope.controllerOf(context, listen: false);
    _servers = initialController.servers;
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    if (widget.deepLinkData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pushServerDetailsScreen(
          context,
          preloadedData: widget.deepLinkData,
        );
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _servers = ServersScope.controllerOf(
      context,
      aspect: ServersScopeAspect.servers,
    ).servers;
  }

  @override
  Widget build(BuildContext context) => ScaffoldWrapper(
    child: ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.ln.servers,
        ),
        body: Column(
          children: [
            if (_servers.isNotEmpty) ...[
              const ServersConnectionPanel(),
              Builder(
                builder: (context) => CustomOutlinedButton(
                  icon: AssetIcons.copy,
                  label: context.ln.pasteFromClipboard,
                  onPressed: _importingFromClipboard ? null : () => _importFromClipboard(context),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.ln.configurations,
                        style: context.textTheme.titleSmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pinging ? null : _pingAllServers,
                      icon: _pinging
                          ? const SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(AssetIcons.update, size: 16),
                      label: Text(context.ln.ping),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: _servers.isEmpty
                  ? _EmptyServersContent(
                      onPasteFromClipboard: _importingFromClipboard
                          ? null
                          : () => _importFromClipboard(context),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _servers.length,
                      itemBuilder: (_, index) {
                        final server = _servers[index];

                        return Column(
                          children: [
                            ServersCard(
                              server: server,
                              selected: server.serverData.selected,
                              pingStatus: _pinging
                                  ? ServerPingStatus.inProgress
                                  : _pingResults.containsKey(server.id)
                                  ? ServerPingStatus.done
                                  : ServerPingStatus.none,
                              pingMs: _pingResults[server.id],
                            ),

                            if (index != _servers.length - 1) const Divider(height: 1),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: _servers.isEmpty
            ? null
            : Builder(
                builder: (context) => CustomFloatingActionButton.extended(
                  icon: AssetIcons.add,
                  onPressed: () => _pushServerDetailsScreen(context),
                  label: context.ln.addServer,
                ),
              ),
      ),
    ),
  );

  /// Measures TCP connect time to every configured server in parallel.
  Future<void> _pingAllServers() async {
    setState(() => _pinging = true);

    final servers = List<Server>.of(_servers);
    await Future.wait(
      servers.map((server) async {
        final ping = await PingUtils.ping(server.serverData.ipAddress);
        _pingResults[server.id] = ping;
      }),
    );

    if (mounted) {
      setState(() => _pinging = false);
    }
  }

  /// Reads a `tt://` configuration link from the clipboard and, when valid,
  /// saves the configuration right away without opening the editor.
  Future<void> _importFromClipboard(BuildContext context) async {
    final controller = ServersScope.controllerOf(context, listen: false);
    final deepLinkRepository = context.repositoryFactory.deepLinkRepository;
    final serverRepository = context.repositoryFactory.serverRepository;
    final ln = context.ln;

    setState(() => _importingFromClipboard = true);
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim() ?? '';

      String? configQuery;
      if (text.startsWith('tt://?')) {
        configQuery = text.substring(6);
      } else if (text.contains('#tt=')) {
        configQuery = text.split('#tt=').last;
      } else if (text.startsWith('tt://')) {
        configQuery = text.substring(5);
      }

      if (configQuery == null || configQuery.isEmpty) {
        _showSnackBar(ln.clipboardNoConfigLink);

        return;
      }

      final parsedData = await deepLinkRepository.parseDataFromLink(
        deepLink: 'tt://?$configQuery',
      );

      final servers = await serverRepository.getAllServers();
      final otherNames = servers.map((server) => server.serverData.name).toSet();
      final baseName = parsedData.name.trim().isEmpty ? ln.addServer : parsedData.name.trim();
      final name = otherNames.contains(baseName)
          ? ServerDetailsServiceImpl().fallbackDuplicateNames(baseName, otherNames)
          : baseName;

      final newServer = await serverRepository.addNewServer(
        request: parsedData.copyWith(
          name: name,
          routingProfileId: RoutingProfileUtils.defaultRoutingProfileId,
        ),
      );

      if (servers.isEmpty) {
        await serverRepository.setSelectedServerId(id: newServer.id);
      }

      controller.fetchServers();
      _showSnackBar(ln.serverImportedSnackbar(name));
    } on Object {
      _showSnackBar(ln.clipboardNoConfigLink);
    } finally {
      if (mounted) {
        setState(() => _importingFromClipboard = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (message.isEmpty) {
      return;
    }

    final messengerContext = _scaffoldMessengerKey.currentContext;
    if (messengerContext != null && messengerContext.mounted) {
      messengerContext.showInfoSnackBar(message: message);
    }
  }

  void _pushServerDetailsScreen(
    BuildContext context, {
    ServerData? preloadedData,
  }) async {
    final controller = ServersScope.controllerOf(context, listen: false);
    final Widget serverDetailsScreen;

    if (preloadedData != null) {
      serverDetailsScreen = ServerDetailsPopUp.preloaded(
        preloadedData: preloadedData,
      );
    } else {
      serverDetailsScreen = const ServerDetailsPopUp();
    }

    await context.push(
      ScaffoldMessengerProvider(
        value: _scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context),
        child: serverDetailsScreen,
      ),
      route: AppRoutes.serverDetails,
    );

    controller.fetchServers();
  }
}

/// Empty state: the "create your first server" placeholder plus a paste option.
/// The big connection panel is intentionally hidden here — there is nothing to
/// connect to yet.
class _EmptyServersContent extends StatelessWidget {
  final VoidCallback? onPasteFromClipboard;

  const _EmptyServersContent({
    required this.onPasteFromClipboard,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Expanded(
        child: ServersEmptyPlaceholder(),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: CustomOutlinedButton(
          icon: AssetIcons.copy,
          label: context.ln.pasteFromClipboard,
          onPressed: onPasteFromClipboard,
        ),
      ),
    ],
  );
}
