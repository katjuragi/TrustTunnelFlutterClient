import 'dart:io';

/// TCP connect-time "ping" to a VPN server.
abstract class PingUtils {
  static const _defaultPort = 443;

  /// Measures the TCP handshake time to [address] (`host`, `host:port`,
  /// `[v6]:port` or an IP literal). Returns milliseconds, or `null` when the
  /// server is unreachable.
  static Future<int?> ping(
    String address, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final (host, port) = _parseHostPort(address.trim());
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      stopwatch.stop();
      socket.destroy();

      return stopwatch.elapsedMilliseconds;
    } on Object {
      return null;
    }
  }

  static (String, int) _parseHostPort(String address) {
    // [ipv6]:port
    if (address.startsWith('[')) {
      final closing = address.indexOf(']');
      if (closing != -1) {
        final host = address.substring(1, closing);
        final port = int.tryParse(address.substring(closing + 1).replaceFirst(':', ''));

        return (host, port ?? _defaultPort);
      }
    }

    // Bare IPv6 literal without a port.
    if (address.split(':').length > 2) {
      return (address, _defaultPort);
    }

    // host or host:port
    final parts = address.split(':');
    if (parts.length == 2) {
      final port = int.tryParse(parts[1]);
      if (port != null) {
        return (parts[0], port);
      }
    }

    return (address, _defaultPort);
  }
}
