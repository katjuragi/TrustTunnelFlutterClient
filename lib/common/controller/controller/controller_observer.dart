import 'controller.dart';
import 'state_controller.dart';

/// {@template controller_observer}
/// Observer interface for monitoring controller lifecycle events.
/// {@endtemplate}
abstract interface class ControllerObserver {
  /// Called when a controller instance is created.
  void onCreate(BaseController controller);

  /// Called when a controller is disposed.
  void onDispose(BaseController controller);

  /// Called when a [BaseStateController] updates its state.
  ///
  /// [previousState] — the value before the change.
  /// [nextState] — the newly emitted state.
  void onStateChanged<S extends Object>(BaseStateController<S> controller, S previousState, S nextState);

  /// Called when an unhandled exception occurs inside a controller.
  void onError(BaseController controller, Object error, StackTrace stackTrace);
}
