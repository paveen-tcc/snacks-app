import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/app_accent.dart';
import '../../../../core/design/app_theme.dart';
import 'drink_dispenser_models.dart';

/// Memory cache for themed SVG strings keyed by "${format.name}_${accent.id}_${isDark}"
final Map<String, String> _themedSvgCache = {};

/// High-performance dynamically themed Dispenser Machine vector banner.
///
/// Loads [assets/Juice.svg] or [assets/Coffee.svg] and automatically recolors the
/// machine chassis to match the active [AppAccent] while preserving authentic fruit & coffee artwork.
class ThemedDispenserSvg extends StatefulWidget {
  const ThemedDispenserSvg({
    super.key,
    required this.format,
    this.height = 148,
    this.isPouring = false,
    this.pouringColor,
  });

  final DrinkFormat format;
  final double height;
  final bool isPouring;
  final Color? pouringColor;

  @override
  State<ThemedDispenserSvg> createState() => _ThemedDispenserSvgState();
}

class _ThemedDispenserSvgState extends State<ThemedDispenserSvg> {
  String? _svgString;
  String? _loadedKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadThemedSvg();
  }

  @override
  void didUpdateWidget(covariant ThemedDispenserSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.format != widget.format) {
      _loadThemedSvg();
    }
  }

  Future<void> _loadThemedSvg() async {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Detect accent or fall back to sapphire
    final accent = AppAccent.values.firstWhere(
      (a) => a.lightBrand.toARGB32() == palette.brand.toARGB32() ||
             a.darkBrand.toARGB32() == palette.brand.toARGB32(),
      orElse: () => AppAccent.sapphire,
    );

    final cacheKey = '${widget.format.name}_${accent.id}_$isDark';
    if (_loadedKey == cacheKey && _svgString != null) return;

    if (_themedSvgCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _svgString = _themedSvgCache[cacheKey];
          _loadedKey = cacheKey;
        });
      }
      return;
    }

    final assetPath = widget.format == DrinkFormat.hotBrew
        ? 'assets/Coffee.svg'
        : 'assets/Juice.svg';

    try {
      final rawSvg = await rootBundle.loadString(assetPath);
      final themedSvg = _recolorSvgForAccent(rawSvg, accent, isDark, widget.format);
      _themedSvgCache[cacheKey] = themedSvg;

      if (mounted) {
        setState(() {
          _svgString = themedSvg;
          _loadedKey = cacheKey;
        });
      }
    } catch (_) {
      // Fallback
      if (mounted) {
        setState(() {
          _svgString = null;
          _loadedKey = null;
        });
      }
    }
  }

  static String _recolorSvgForAccent(
    String svg,
    AppAccent accent,
    bool isDark,
    DrinkFormat format,
  ) {
    // If Sapphire (default), keep the original pristine artwork in light mode
    if (accent == AppAccent.sapphire && !isDark) {
      return svg;
    }

    // Color transformation map for the machine housing based on accent
    final Map<String, String> colorMap = {};

    switch (accent) {
      case AppAccent.violet:
        colorMap['#6FB1FD'] = isDark ? '#6D28D9' : '#8B5CF6';
        colorMap['#7CB2FC'] = isDark ? '#7C3AED' : '#A78BFA';
        colorMap['#5DA3FE'] = isDark ? '#5B21B6' : '#7C3AED';
        colorMap['#5889CE'] = isDark ? '#4C1D95' : '#6D28D9';
        colorMap['#9BC6FD'] = isDark ? '#8B5CF6' : '#C4B5FD';
        colorMap['#8DB2FD'] = isDark ? '#7C3AED' : '#A78BFA';
        colorMap['#D3E5FC'] = isDark ? '#3B0764' : '#DDD6FE';
        colorMap['#E5EFFC'] = isDark ? '#2E1065' : '#EDE9FE';
        colorMap['#E1E4F8'] = isDark ? '#2E1065' : '#EDE9FE';
        break;

      case AppAccent.sunset:
        colorMap['#6FB1FD'] = isDark ? '#C2410C' : '#F97316';
        colorMap['#7CB2FC'] = isDark ? '#EA580C' : '#FB923C';
        colorMap['#5DA3FE'] = isDark ? '#9A3412' : '#EA580C';
        colorMap['#5889CE'] = isDark ? '#7C2D12' : '#C2410C';
        colorMap['#9BC6FD'] = isDark ? '#F97316' : '#FDBA74';
        colorMap['#8DB2FD'] = isDark ? '#EA580C' : '#FB923C';
        colorMap['#D3E5FC'] = isDark ? '#431407' : '#FED7AA';
        colorMap['#E5EFFC'] = isDark ? '#2B0E05' : '#FFEDD5';
        colorMap['#E1E4F8'] = isDark ? '#2B0E05' : '#FFEDD5';
        break;

      case AppAccent.emerald:
        colorMap['#6FB1FD'] = isDark ? '#047857' : '#10B981';
        colorMap['#7CB2FC'] = isDark ? '#059669' : '#34D399';
        colorMap['#5DA3FE'] = isDark ? '#065F46' : '#059669';
        colorMap['#5889CE'] = isDark ? '#064E3B' : '#047857';
        colorMap['#9BC6FD'] = isDark ? '#10B981' : '#6EE7B7';
        colorMap['#8DB2FD'] = isDark ? '#059669' : '#34D399';
        colorMap['#D3E5FC'] = isDark ? '#062E25' : '#A7F3D0';
        colorMap['#E5EFFC'] = isDark ? '#041F19' : '#D1FAE5';
        colorMap['#E1E4F8'] = isDark ? '#041F19' : '#D1FAE5';
        break;

      case AppAccent.ruby:
        colorMap['#6FB1FD'] = isDark ? '#BE123C' : '#F43F5E';
        colorMap['#7CB2FC'] = isDark ? '#E11D48' : '#FB7185';
        colorMap['#5DA3FE'] = isDark ? '#9F1239' : '#E11D48';
        colorMap['#5889CE'] = isDark ? '#881337' : '#BE123C';
        colorMap['#9BC6FD'] = isDark ? '#F43F5E' : '#FDA4AF';
        colorMap['#8DB2FD'] = isDark ? '#E11D48' : '#FB7185';
        colorMap['#D3E5FC'] = isDark ? '#4C0519' : '#FECDD3';
        colorMap['#E5EFFC'] = isDark ? '#300310' : '#FFE4E6';
        colorMap['#E1E4F8'] = isDark ? '#300310' : '#FFE4E6';
        break;

      case AppAccent.amethyst:
        colorMap['#6FB1FD'] = isDark ? '#A21CAF' : '#D946EF';
        colorMap['#7CB2FC'] = isDark ? '#C026D3' : '#E879F9';
        colorMap['#5DA3FE'] = isDark ? '#86198F' : '#C026D3';
        colorMap['#5889CE'] = isDark ? '#701A75' : '#A21CAF';
        colorMap['#9BC6FD'] = isDark ? '#D946EF' : '#F0ABFC';
        colorMap['#8DB2FD'] = isDark ? '#C026D3' : '#E879F9';
        colorMap['#D3E5FC'] = isDark ? '#4A044E' : '#F5D0FE';
        colorMap['#E5EFFC'] = isDark ? '#2E0231' : '#FAE8FF';
        colorMap['#E1E4F8'] = isDark ? '#2E0231' : '#FAE8FF';
        break;

      case AppAccent.sapphire:
        // Dark Sapphire overrides
        if (isDark) {
          colorMap['#6FB1FD'] = '#2563EB';
          colorMap['#7CB2FC'] = '#3B82F6';
          colorMap['#5DA3FE'] = '#1D4ED8';
          colorMap['#5889CE'] = '#1E40AF';
          colorMap['#9BC6FD'] = '#60A5FA';
          colorMap['#8DB2FD'] = '#3B82F6';
          colorMap['#D3E5FC'] = '#172554';
          colorMap['#E5EFFC'] = '#0F172A';
          colorMap['#E1E4F8'] = '#0F172A';
        }
        break;
    }

    String result = svg;
    colorMap.forEach((oldHex, newHex) {
      result = result.replaceAll(oldHex, newHex);
      result = result.replaceAll(oldHex.toLowerCase(), newHex);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      alignment: Alignment.center,
      child: _svgString != null
          ? SvgPicture.string(
              _svgString!,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            )
          : SvgPicture.asset(
              widget.format == DrinkFormat.hotBrew
                  ? 'assets/Coffee.svg'
                  : 'assets/Juice.svg',
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
    );
  }
}
