import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_plugin/split_tunnel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('vpn_plugin_split_tunnel');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  test('serializes settings writes and preserves their order', () async {
    final firstWrite = Completer<void>();
    final modes = <int>[];
    var activeWrites = 0;
    var maxActiveWrites = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method != 'setSettings') return null;

        activeWrites++;
        maxActiveWrites = activeWrites > maxActiveWrites ? activeWrites : maxActiveWrites;
        final arguments = call.arguments! as Map<Object?, Object?>;
        modes.add(arguments['mode']! as int);
        if (modes.length == 1) await firstWrite.future;
        activeWrites--;

        return null;
      },
    );

    const manager = SplitTunnelManager();
    final first = manager.setSettings(
      const SplitTunnelSettings(
        mode: SplitTunnelMode.onlySelected,
        packages: {'com.example.first'},
      ),
    );
    final second = manager.setSettings(
      const SplitTunnelSettings(
        mode: SplitTunnelMode.allExceptSelected,
        packages: {'com.example.second'},
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(modes, [SplitTunnelMode.onlySelected.value]);

    firstWrite.complete();
    await Future.wait([first, second]);

    expect(
      modes,
      [
        SplitTunnelMode.onlySelected.value,
        SplitTunnelMode.allExceptSelected.value,
      ],
    );
    expect(maxActiveWrites, 1);
  });

  test('takes an immutable snapshot of selected packages', () async {
    List<Object?>? savedPackages;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        final arguments = call.arguments! as Map<Object?, Object?>;
        savedPackages = arguments['packages']! as List<Object?>;

        return null;
      },
    );

    final packages = <String>{'com.example.kept'};
    const manager = SplitTunnelManager();
    final write = manager.setSettings(
      SplitTunnelSettings(
        mode: SplitTunnelMode.onlySelected,
        packages: packages,
      ),
    );
    packages.add('com.example.added.too.late');
    await write;

    expect(savedPackages, ['com.example.kept']);
  });
}
