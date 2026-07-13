import 'package:flutter/widgets.dart';

abstract class CustomPageRoute<T> extends ModalRoute<T> implements PageRoute<T> {
  @override
  final bool fullscreenDialog;

  @override
  final bool allowSnapshotting;

  final bool _barrierDismissible;

  CustomPageRoute({
    super.settings,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    bool barrierDismissible = false,
    super.traversalEdgeBehavior,
  }) : _barrierDismissible = barrierDismissible;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => _barrierDismissible;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => nextRoute is PageRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => previousRoute is PageRoute;
}
