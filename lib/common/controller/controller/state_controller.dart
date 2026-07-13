import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'controller.dart';

/// {@template state_controller}
/// Base contract for a state controller.
///
/// Do not implement this interface directly, prefer extending [BaseStateController].
/// {@endtemplate}
abstract interface class StateController<S extends Object> implements Controller {
  /// Current value of the controller's state.
  S get state;
}

/// {@template base_state_controller}
/// A controller that owns and updates a piece of state [State].
///
/// It extends [Controller] and integrates with the controller observer.
/// {@endtemplate}
abstract base class BaseStateController<State extends Object> extends BaseController implements StateController<State> {
  /// Creates a [StateController] with an initial [state] value.
  BaseStateController({required State initialState}) : _state = initialState;

  State _state;

  @override
  @nonVirtual
  State get state => _state;

  /// Updates the current state and notifies listeners.
  ///
  /// Subclasses should call this method whenever [state] changes.
  /// The previous and next states are also forwarded to the global
  /// [BaseController.observer] if present.
  @protected
  @mustCallSuper
  void setState(State nextState) {
    runZonedGuarded<void>(
      () => BaseController.observer?.onStateChanged(this, _state, nextState),
      (Object _, StackTrace _) {
        // Intentionally ignore observer failures.
      },
    );
    _state = nextState;
    if (isDisposed) return;
    notifyListeners();
  }
}
