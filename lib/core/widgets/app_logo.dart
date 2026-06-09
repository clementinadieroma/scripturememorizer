import 'package:flutter/material.dart';

/// Brand logo used on auth screens and anywhere the app identity is shown.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 120,
    this.semanticLabel = 'Scripture Memorizer',
  });

  final double height;
  final String semanticLabel;

  static const _assetPath = 'assets/images/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final cacheHeight = (height * MediaQuery.devicePixelRatioOf(context)).round();

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        _assetPath,
        height: height,
        fit: BoxFit.contain,
        cacheHeight: cacheHeight,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
