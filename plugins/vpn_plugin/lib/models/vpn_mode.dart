/// {@template vpn_mode}
/// Routing policy that defines which connections are tunneled.
///
/// The backend uses this mode together with destination lists (for example
/// [Endpoint.exclusions]) to decide whether a connection is sent through the
/// VPN endpoint or handled directly.
///
/// Exact semantics are backend-defined, but typically:
/// - [general] tunnels most traffic except excluded destinations (VPN mode),
/// - [selective] tunnels only explicitly selected destinations (Bypass mode).
/// {@endtemplate}
enum VpnMode {
  /// Tunnel all traffic except destinations considered excluded.
  general('general'),

  /// Tunnel only destinations considered selected (often using the same list).
  selective('selective');

  /// {@template vpn_mode_value}
  /// Backend string representation of the mode.
  /// {@endtemplate}
  final String value;

  /// {@macro vpn_mode}
  const VpnMode(this.value);
}
