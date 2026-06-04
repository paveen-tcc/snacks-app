import 'package:flutter/material.dart';

import '../design/app_tokens.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.borderRadius,
    this.shadows,
    this.semanticLabel = 'TCC Pantry logo',
  });

  static const assetPath = 'assets/brand/pantry_logo.png';

  final double size;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: borderRadius ?? AppRadii.rMd,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
      ),
    );

    if (shadows == null || shadows!.isEmpty) return image;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? AppRadii.rMd,
        boxShadow: shadows,
      ),
      child: image,
    );
  }
}
