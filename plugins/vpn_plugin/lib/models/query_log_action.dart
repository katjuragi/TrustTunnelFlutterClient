/// {@template query_log_action}
/// Action taken by the VPN engine for a particular network query/flow.
///
/// This enum is primarily used for logging and diagnostics.
/// {@endtemplate}
enum QueryLogAction {
  /// The query was bypassed (routed directly, not through the tunnel).
  bypass('bypass'),

  /// The query was tunneled through the VPN endpoint.
  tunnel('tunnel'),

  /// The query was rejected/blocked by the engine.
  reject('reject');

  /// {@template query_log_action_value}
  /// Backend string representation of the action.
  /// {@endtemplate}
  final String value;

  /// {@macro query_log_action}
  const QueryLogAction(this.value);
}
