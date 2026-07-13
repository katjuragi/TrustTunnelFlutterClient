/// {@template upstream_protocol}
/// Protocol used to communicate with the VPN endpoint.
///
/// This corresponds to backend transport modes such as HTTP/2 or HTTP/3.
/// {@endtemplate}
enum UpStreamProtocol {
  /// Use HTTP/2 for upstream communication.
  http2('http2'),

  /// Use HTTP/3 (QUIC) for upstream communication.
  http3('http3');

  /// {@template upstream_protocol_value}
  /// Backend string representation of the protocol.
  /// {@endtemplate}
  final String value;

  /// {@macro upstream_protocol}
  const UpStreamProtocol(this.value);
}
