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

  Future<void> setSettings(SplitTunnelSettings settings) => _channel.invokeMethod<void>(
    'setSettings',
    {
      'mode': settings.mode.value,
      'packages': settings.packages.toList(),
    },
  );
}
