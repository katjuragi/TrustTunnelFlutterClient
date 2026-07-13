import 'package:flutter/material.dart';

class ScaffoldMessengerProvider extends ScaffoldMessenger {
  final ScaffoldMessengerState value;

  const ScaffoldMessengerProvider({
    super.key,
    required super.child,
    required this.value,
  });

  @override
  ScaffoldMessengerState createState() => ScaffoldMessengerProviderState();
}

class ScaffoldMessengerProviderState extends ScaffoldMessengerState {
  ScaffoldMessengerProvider get _widget => widget as ScaffoldMessengerProvider;

  ScaffoldMessengerState get value => _widget.value;
}
