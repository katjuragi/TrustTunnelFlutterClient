/// {@template vpn_log_action}
/// Action taken by the VPN engine for a logged connection or request.
///
/// This enum is intended for UI and diagnostics.
/// {@endtemplate}
enum VpnLogAction {
  /// The connection was routed directly (not through the VPN tunnel).
  bypass,

  /// The connection was routed through the VPN tunnel.
  tunnel,

  /// The connection was rejected/blocked by the engine.
  reject,
}
