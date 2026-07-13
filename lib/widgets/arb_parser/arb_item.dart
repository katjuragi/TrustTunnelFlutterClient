class ArbItem {
  final String? text;
  final ArbItemType type;

  const ArbItem({
    this.text,
    required this.type,
  });
}

enum ArbItemType {
  plain,
  bold,
}
