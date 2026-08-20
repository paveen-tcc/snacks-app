import 'package:flutter/material.dart';

/// Curated fancy accent color options for the app.
enum AppAccent {
  sapphire(
    id: 'sapphire',
    title: 'Sapphire Blue',
    subtitle: 'Royal Electric Blue',
    swatchColor: Color(0xFF0072E5),
    lightBrand: Color(0xFF0072E5),
    lightBrandPressed: Color(0xFF005BC4),
    darkBrand: Color(0xFF3B82F6),
    darkBrandPressed: Color(0xFF2563EB),
    lightHeaderGradient: [Color(0xFF00BBFF), Color(0xFF0078FF)],
    lightHeroBannerGradient: [Color(0xFF0078FF), Color(0xFF0048FF)],
    darkHeaderGradient: [Color(0xFF1E3A8A), Color(0xFF172554)],
    darkHeroBannerGradient: [Color(0xFF172554), Color(0xFF0F172A)],
    heroHeartColor: Color(0xFF36FFEB),
    lightCardGlow: [Color(0xFFE2EFFF), Color(0xFFF5F9FD), Colors.white],
    darkCardGlow: [Color(0xFF0F172A), Color(0xFF0B101D), Color(0xFF070A12)],
  ),
  violet(
    id: 'violet',
    title: 'Electric Violet',
    subtitle: 'Radiant Cyber Violet',
    swatchColor: Color(0xFF8B5CF6),
    lightBrand: Color(0xFF7C3AED),
    lightBrandPressed: Color(0xFF6D28D9),
    darkBrand: Color(0xFFA78BFA),
    darkBrandPressed: Color(0xFF8B5CF6),
    lightHeaderGradient: [Color(0xFFA855F7), Color(0xFF7C3AED)],
    lightHeroBannerGradient: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    darkHeaderGradient: [Color(0xFF4C1D95), Color(0xFF3B0764)],
    darkHeroBannerGradient: [Color(0xFF3B0764), Color(0xFF120520)],
    heroHeartColor: Color(0xFFF472B6),
    lightCardGlow: [Color(0xFFF3E8FF), Color(0xFFFAF5FF), Colors.white],
    darkCardGlow: [Color(0xFF1B0E2E), Color(0xFF130922), Color(0xFF0A0512)],
  ),
  sunset(
    id: 'sunset',
    title: 'Sunset Amber',
    subtitle: 'Warm Solar Sunrise',
    swatchColor: Color(0xFFF97316),
    lightBrand: Color(0xFFEA580C),
    lightBrandPressed: Color(0xFFC2410C),
    darkBrand: Color(0xFFFB923C),
    darkBrandPressed: Color(0xFFF97316),
    lightHeaderGradient: [Color(0xFFFFA502), Color(0xFFFF4757)],
    lightHeroBannerGradient: [Color(0xFFFF4757), Color(0xFFB71540)],
    darkHeaderGradient: [Color(0xFF7C2D12), Color(0xFF431407)],
    darkHeroBannerGradient: [Color(0xFF431407), Color(0xFF180804)],
    heroHeartColor: Color(0xFFFDE047),
    lightCardGlow: [Color(0xFFFFEDD5), Color(0xFFFFF7ED), Colors.white],
    darkCardGlow: [Color(0xFF230D08), Color(0xFF160805), Color(0xFF0C0403)],
  ),
  emerald(
    id: 'emerald',
    title: 'Emerald Aurora',
    subtitle: 'Lush Jade Green',
    swatchColor: Color(0xFF10B981),
    lightBrand: Color(0xFF059669),
    lightBrandPressed: Color(0xFF047857),
    darkBrand: Color(0xFF34D399),
    darkBrandPressed: Color(0xFF10B981),
    lightHeaderGradient: [Color(0xFF2ED573), Color(0xFF059669)],
    lightHeroBannerGradient: [Color(0xFF059669), Color(0xFF064E3B)],
    darkHeaderGradient: [Color(0xFF064E3B), Color(0xFF062E25)],
    darkHeroBannerGradient: [Color(0xFF062E25), Color(0xFF041813)],
    heroHeartColor: Color(0xFF6EE7B7),
    lightCardGlow: [Color(0xFFD1FAE5), Color(0xFFECFDF5), Colors.white],
    darkCardGlow: [Color(0xFF071E17), Color(0xFF05140F), Color(0xFF030A08)],
  ),
  ruby(
    id: 'ruby',
    title: 'Crimson Ruby',
    subtitle: 'Deep Velvet Rose',
    swatchColor: Color(0xFFF43F5E),
    lightBrand: Color(0xFFE11D48),
    lightBrandPressed: Color(0xFFBE123C),
    darkBrand: Color(0xFFFB7185),
    darkBrandPressed: Color(0xFFF43F5E),
    lightHeaderGradient: [Color(0xFFFF4B72), Color(0xFFBE123C)],
    lightHeroBannerGradient: [Color(0xFFBE123C), Color(0xFF881337)],
    darkHeaderGradient: [Color(0xFF881337), Color(0xFF4C0519)],
    darkHeroBannerGradient: [Color(0xFF4C0519), Color(0xFF1C050B)],
    heroHeartColor: Color(0xFFFDA4AF),
    lightCardGlow: [Color(0xFFFFE4E6), Color(0xFFFFF1F2), Colors.white],
    darkCardGlow: [Color(0xFF22080F), Color(0xFF150409), Color(0xFF0C0205)],
  ),
  amethyst(
    id: 'amethyst',
    title: 'Cosmic Amethyst',
    subtitle: 'Mystic Galactic Purple',
    swatchColor: Color(0xFFD946EF),
    lightBrand: Color(0xFFC026D3),
    lightBrandPressed: Color(0xFFA21CAF),
    darkBrand: Color(0xFFE879F9),
    darkBrandPressed: Color(0xFFD946EF),
    lightHeaderGradient: [Color(0xFFF368E0), Color(0xFF9333EA)],
    lightHeroBannerGradient: [Color(0xFF9333EA), Color(0xFF581C87)],
    darkHeaderGradient: [Color(0xFF581C87), Color(0xFF3B0764)],
    darkHeroBannerGradient: [Color(0xFF3B0764), Color(0xFF140524)],
    heroHeartColor: Color(0xFFFFD166),
    lightCardGlow: [Color(0xFFFAE8FF), Color(0xFFFDF4FF), Colors.white],
    darkCardGlow: [Color(0xFF1D092A), Color(0xFF13051D), Color(0xFF0B0311)],
  );

  const AppAccent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.swatchColor,
    required this.lightBrand,
    required this.lightBrandPressed,
    required this.darkBrand,
    required this.darkBrandPressed,
    required this.lightHeaderGradient,
    required this.lightHeroBannerGradient,
    required this.darkHeaderGradient,
    required this.darkHeroBannerGradient,
    required this.heroHeartColor,
    required this.lightCardGlow,
    required this.darkCardGlow,
  });

  final String id;
  final String title;
  final String subtitle;
  final Color swatchColor;
  final Color lightBrand;
  final Color lightBrandPressed;
  final Color darkBrand;
  final Color darkBrandPressed;
  final List<Color> lightHeaderGradient;
  final List<Color> lightHeroBannerGradient;
  final List<Color> darkHeaderGradient;
  final List<Color> darkHeroBannerGradient;
  final Color heroHeartColor;
  final List<Color> lightCardGlow;
  final List<Color> darkCardGlow;

  static AppAccent fromId(String? id) {
    if (id == null) return AppAccent.sapphire;
    return AppAccent.values.firstWhere(
      (a) => a.id == id,
      orElse: () => AppAccent.sapphire,
    );
  }
}
