import 'package:flutter/services.dart';

/// Split tunneling mode, mirrors `SplitTunnelStore` constants on Android.
enum SplitTunnelMode {
  allApps(0),
  onlySelected(1),
  allExceptSelected(2);

  final int value;

  const SplitTunnelMode(this.value);

  static SplitTunnelMode fromValue(int? value) =>
      SplitTunnelMode.values.firstWhere(
        (mode) => mode.value == value,
        orElse: () => SplitTunnelMode.allApps,
      );
}

/// An installed launchable application.
class InstalledApp {
  final String name;
  final String packageName;
  final bool isSystem;
  final Uint8List icon;

  const InstalledApp({
    required this.name,
    required this.packageName,
    required this.isSystem,
    required this.icon,
  });
}

/// Split tunneling settings snapshot.
class SplitTunnelSettings {
  final SplitTunnelMode mode;
  final Set<String> packages;

  const SplitTunnelSettings({
    required this.mode,
    required this.packages,
  });
}

/// Access to per-app split tunneling settings and the installed app list.
class SplitTunnelManager {
  static const _channel = MethodChannel('vpn_plugin_split_tunnel');
  static Future<void> _writeQueue = Future<void>.value();

  const SplitTunnelManager();

  Future<List<InstalledApp>> getInstalledApps() async {
    final result = await _channel.invokeListMethod<Object?>('getInstalledApps');

    return (result ?? [])
        .whereType<Map<Object?, Object?>>()
        .map(
          (raw) => InstalledApp(
            name: raw['name']! as String,
            packageName: raw['package']! as String,
            isSystem: raw['system']! as bool,
            icon: raw['icon']! as Uint8List,
          ),
        )
        .toList();
  }

  Future<SplitTunnelSettings> getSettings() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('getSettings');

    return SplitTunnelSettings(
      mode: SplitTunnelMode.fromValue(raw?['mode'] as int?),
      packages: ((raw?['packages'] as List<Object?>?) ?? []).whereType<String>().toSet(),
    );
  }

  /// Persists writes in the same order in which the UI produced them.
  ///
  /// A user can toggle several apps before the previous platform-channel call
  /// completes. Serializing the calls prevents an older response from
  /// overwriting the newest selection.
  Future<void> setSettings(SplitTunnelSettings settings) {
    final mode = settings.mode.value;
    final packages = List<String>.unmodifiable(settings.packages);
    final write = _writeQueue.then<void>(
      (_) => _channel.invokeMethod<void>(
        'setSettings',
        {
          'mode': mode,
          'packages': packages,
        },
      ),
    );

    // Keep the queue usable after an individual platform write fails, while
    // still returning the original failure to that write's caller.
    _writeQueue = write.catchError((Object _) {});

    return write;
  }
}
