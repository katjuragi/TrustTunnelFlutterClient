import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier, Listenable, VoidCallback;
import 'package:meta/meta.dart';

import 'controller_observer.dart';

/// {@template controller}
/// High-level contract for a controller that coordinates business logic
/// and exposes change notifications for the UI.
///
/// Prefer extending [BaseController] instead of implementing this interface directly.
/// {@endtemplate}
abstract interface class Controller implements Listenable {
  /// Number of active listeners subscribed to this controller.
  int get subscriberCount;

  /// Whether the controller is currently busy handling operations.
  bool get isProcessing;

  /// Indicates whether [dispose] has been called and the controller
  /// is no longer expected to be used.
  bool get isDisposed;

  /// Executes or enqueues a unit of work associated with the controller.
  ///
  /// The exact scheduling strategy (sequential, concurrent, droppable)
  /// is defined by concrete implementations.
  void handle(Future<void> Function() handler);

  /// Releases resources held by the controller.
  ///
  /// Should be invoked only by the owner of this instance.
  void dispose();
}

/// {@template base_controller}
/// Base implementation of [Controller] that wires together lifecycle,
/// listener management and error reporting.
///
/// Subclasses are expected to provide a concrete implementation of [handle]
/// and optionally override [onError].
/// {@endtemplate}
abstract base class BaseController with ChangeNotifier implements Controller {
  /// Optional observer that can be used to hook into controller lifecycle
  /// events (creation, errors, disposal) for logging.
  static ControllerObserver? observer;

  /// {@macro base_controller}
  BaseController() {
    runZonedGuarded<void>(
      () => BaseController.observer?.onCreate(this),
      (Object _, StackTrace _) {
        // Intentionally ignore observer failures.
      },
    );
  }

  bool _isDisposed = false;

  int _subscriberCount = 0;

  @override
  bool get isDisposed => _isDisposed;

  @override
  int get subscriberCount => _subscriberCount;

  @override
  @mustCallSuper
  void addListener(VoidCallback listener) {
    if (isDisposed) {
      assert(false, 'Attempted to add a listener to a disposed $runtimeType.');

      return;
    }
    super.addListener(listener);
    _subscriberCount++;
  }

  @override
  @mustCallSuper
  void removeListener(VoidCallback listener) {
    if (isDisposed) {
      assert(false, 'Attempted to remove a listener from a disposed $runtimeType.');

      return;
    }
    super.removeListener(listener);
    if (_subscriberCount > 0) {
      _subscriberCount--;
    }
  }

  @protected
  @nonVirtual
  @override
  void notifyListeners() {
    if (isDisposed) {
      assert(false, 'Attempted to notify listeners on a disposed $runtimeType.');

      return;
    }
    super.notifyListeners();
  }

  /// Called when an error occurs while processing controller logic.
  ///
  /// By default, forwards the error to the global [observer] (if present)
  /// and suppresses any failures thrown by the observer itself.
  @protected
  void onError(Object error, StackTrace stackTrace) => runZonedGuarded<void>(
    () => BaseController.observer?.onError(this, error, stackTrace),
    (Object _, StackTrace _) {
      // Intentionally ignore observer failures.
    },
  );

  /// Handles the provided [handler] with controller-specific scheduling
  /// and error handling semantics.
  ///
  /// Implementations may run handlers sequentially, in parallel, drop them
  /// when busy, or apply any other custom strategy.
  @protected
  @override
  Future<void> handle(Future<void> Function() handler);

  @override
  @mustCallSuper
  void dispose() {
    if (isDisposed) {
      assert(false, 'A $runtimeType was already disposed.');

      return;
    }
    _isDisposed = true;
    _subscriberCount = 0;

    runZonedGuarded<void>(
      () => BaseController.observer?.onDispose(this),
      (Object _, StackTrace _) {
        // Intentionally ignore observer failures.
      },
    );
    super.dispose();
  }
}
