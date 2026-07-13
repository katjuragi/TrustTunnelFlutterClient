import 'package:flutter/material.dart';

class CustomIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;

  const CustomIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
  });

  factory CustomIcon.small({
    required IconData icon,
    Color? color,
  }) => CustomIcon(
    icon: icon,
    color: color,
    size: 18,
  );

  factory CustomIcon.medium({
    required IconData icon,
    Color? color,
  }) => CustomIcon(
    icon: icon,
    color: color,
    size: 24,
  );

  @override
  Widget build(BuildContext context) => Icon(
    icon,
    color: color,
    size: size,
    applyTextScaling: true,
  );
}
