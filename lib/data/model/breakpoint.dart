// ignore_for_file: constant_identifier_names

enum Breakpoint {
  M,
  S,
  XS,
}

extension BreakpointExtension on Breakpoint {
  int get value => index;

  bool operator >=(Breakpoint other) => index <= other.index;

  bool operator <=(Breakpoint other) => index >= other.index;

  bool operator >(Breakpoint other) => index < other.index;

  bool operator <(Breakpoint other) => index > other.index;
}
