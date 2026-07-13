/// {@template connection_protocol}
/// Transport protocol used for a network connection.
///
/// This enum is primarily used for logging/telemetry models where a connection
/// needs to be described in a stable, backend-friendly form.
/// {@endtemplate}
enum ConnectionProtocol {
  /// A TCP connection.
  tcp('tcp'),

  /// A UDP connection.
  udp('udp');

  /// {@template connection_protocol_value}
  /// Backend string representation of the protocol.
  ///
  /// This value is intended for serialization and stable interop with native
  /// components.
  /// {@endtemplate}
  final String value;

  /// {@macro connection_protocol}
  const ConnectionProtocol(this.value);
}
