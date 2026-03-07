import 'package:flutter/material.dart';

/// Notion-style warm illustration color palette.
class IllustrationColors {
  static const Color peach = Color(0xFFFDECC8);
  static const Color softBlue = Color(0xFFD3E5EF);
  static const Color softGreen = Color(0xFFDBEDDB);
  static const Color softPurple = Color(0xFFE8DEEE);
  static const Color softPink = Color(0xFFFFE2DD);
  static const Color softOrange = Color(0xFFFADEC9);
  static const Color warmBrown = Color(0xFF937264);
  static const Color outline = Color(0xFF37352F);
}

/// A warm, Notion-style food scene illustration for the welcome screen.
class WelcomeIllustration extends StatelessWidget {
  final double width;
  const WelcomeIllustration({super.key, this.width = 300});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.7,
      child: CustomPaint(painter: _WelcomePainter()),
    );
  }
}

class _WelcomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outline = Paint()
      ..color = IllustrationColors.outline.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final steamPaint = Paint()
      ..color = IllustrationColors.warmBrown.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // --- Decorative background dots & sparkles ---
    _dot(canvas, Offset(w * 0.06, h * 0.18), 8, IllustrationColors.peach);
    _dot(canvas, Offset(w * 0.93, h * 0.13), 6, IllustrationColors.softGreen);
    _dot(canvas, Offset(w * 0.87, h * 0.78), 5, IllustrationColors.softPink);
    _dot(canvas, Offset(w * 0.13, h * 0.82), 7, IllustrationColors.softBlue);
    _dot(canvas, Offset(w * 0.50, h * 0.04), 4, IllustrationColors.softOrange);
    _dot(canvas, Offset(w * 0.74, h * 0.07), 5, IllustrationColors.softPurple);
    _sparkle(canvas, Offset(w * 0.16, h * 0.10), 7, IllustrationColors.softOrange);
    _sparkle(canvas, Offset(w * 0.82, h * 0.28), 5, IllustrationColors.softBlue);
    _sparkle(canvas, Offset(w * 0.60, h * 0.06), 4, IllustrationColors.softGreen);

    // --- Table surface ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.73, w * 0.9, h * 0.055),
        const Radius.circular(20),
      ),
      Paint()..color = IllustrationColors.peach,
    );

    // --- Bowl (center) ---
    final bowlL = w * 0.27;
    final bowlR = w * 0.63;
    final bowlT = h * 0.43;
    final bowlB = h * 0.73;
    final bowlMx = (bowlL + bowlR) / 2;
    final bowlFill = Paint()..color = IllustrationColors.softOrange;

    final bowl = Path()
      ..moveTo(bowlL, bowlT)
      ..quadraticBezierTo(bowlL - w * 0.01, bowlB, bowlMx - w * 0.04, bowlB)
      ..lineTo(bowlMx + w * 0.04, bowlB)
      ..quadraticBezierTo(bowlR + w * 0.01, bowlB, bowlR, bowlT)
      ..close();
    canvas.drawPath(bowl, bowlFill);
    canvas.drawPath(bowl, outline);

    // Rim
    final rim = Rect.fromLTWH(bowlL, bowlT - h * 0.025, bowlR - bowlL, h * 0.05);
    canvas.drawOval(rim, bowlFill);
    canvas.drawOval(rim, outline);

    // Food bits inside
    _dot(canvas, Offset(w * 0.37, bowlT + h * 0.06), 6, IllustrationColors.softGreen);
    _dot(canvas, Offset(w * 0.47, bowlT + h * 0.04), 5, IllustrationColors.softPink);
    _dot(canvas, Offset(w * 0.54, bowlT + h * 0.07), 4, IllustrationColors.softPurple);
    _dot(canvas, Offset(w * 0.42, bowlT + h * 0.11), 5, IllustrationColors.peach);

    // Steam
    for (var i = 0; i < 3; i++) {
      final x = w * (0.37 + i * 0.07);
      final y0 = bowlT - h * 0.04;
      canvas.drawPath(
        Path()
          ..moveTo(x, y0)
          ..quadraticBezierTo(x - 4, y0 - h * 0.08, x + 2, y0 - h * 0.14)
          ..quadraticBezierTo(x + 6, y0 - h * 0.20, x, y0 - h * 0.24),
        steamPaint,
      );
    }

    // --- Cup (left) ---
    final cupFill = Paint()..color = IllustrationColors.softPurple;
    final cupR = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.50, w * 0.11, h * 0.23),
      const Radius.circular(4),
    );
    canvas.drawRRect(cupR, cupFill);
    canvas.drawRRect(cupR, outline);

    // Handle
    final hx = w * 0.17;
    canvas.drawPath(
      Path()
        ..moveTo(hx, h * 0.55)
        ..quadraticBezierTo(hx + w * 0.05, h * 0.55, hx + w * 0.05, h * 0.615)
        ..quadraticBezierTo(hx + w * 0.05, h * 0.68, hx, h * 0.68),
      outline,
    );

    // Cup steam
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.10, h * 0.46)
        ..quadraticBezierTo(w * 0.08, h * 0.39, w * 0.11, h * 0.34),
      steamPaint,
    );

    // --- Plate with items (right) ---
    final plateCenter = Offset(w * 0.82, h * 0.69);
    final plateR = Rect.fromCenter(center: plateCenter, width: w * 0.22, height: h * 0.07);
    canvas.drawOval(plateR, Paint()..color = IllustrationColors.softBlue);
    canvas.drawOval(plateR, outline);

    _dot(canvas, Offset(w * 0.78, h * 0.66), 5, IllustrationColors.softPink);
    _dot(canvas, Offset(w * 0.85, h * 0.67), 4, IllustrationColors.softGreen);
    _dot(canvas, Offset(w * 0.81, h * 0.64), 3.5, IllustrationColors.peach);

    // --- Spoon (between bowl and plate) ---
    final spoonPaint = Paint()
      ..color = IllustrationColors.outline.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.68, h * 0.72)
        ..lineTo(w * 0.72, h * 0.45)
        ..quadraticBezierTo(w * 0.725, h * 0.40, w * 0.71, h * 0.38)
        ..quadraticBezierTo(w * 0.69, h * 0.36, w * 0.68, h * 0.40)
        ..quadraticBezierTo(w * 0.675, h * 0.44, w * 0.72, h * 0.45),
      spoonPaint,
    );
  }

  void _dot(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(c, r, Paint()..color = color);
  }

  void _sparkle(Canvas canvas, Offset c, double s, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.22, c.dy - s * 0.22)
      ..lineTo(c.dx + s, c.dy)
      ..lineTo(c.dx + s * 0.22, c.dy + s * 0.22)
      ..lineTo(c.dx, c.dy + s)
      ..lineTo(c.dx - s * 0.22, c.dy + s * 0.22)
      ..lineTo(c.dx - s, c.dy)
      ..lineTo(c.dx - s * 0.22, c.dy - s * 0.22)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A soft, Notion-style empty state illustration with concentric circles
/// and a central emoji.
class EmptyStateIllustration extends StatelessWidget {
  final String emoji;
  final double size;

  const EmptyStateIllustration({
    super.key,
    this.emoji = '',
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IllustrationColors.peach.withValues(alpha: 0.4),
            ),
          ),
          Container(
            width: size * 0.65,
            height: size * 0.65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IllustrationColors.softOrange.withValues(alpha: 0.3),
            ),
          ),
          Text(emoji, style: TextStyle(fontSize: size * 0.28)),
          Positioned(
            top: size * 0.05,
            right: size * 0.12,
            child: _circle(8, IllustrationColors.softBlue),
          ),
          Positioned(
            bottom: size * 0.08,
            left: size * 0.08,
            child: _circle(6, IllustrationColors.softGreen),
          ),
          Positioned(
            top: size * 0.18,
            left: size * 0.04,
            child: _circle(5, IllustrationColors.softPink),
          ),
          Positioned(
            bottom: size * 0.15,
            right: size * 0.06,
            child: _circle(4, IllustrationColors.softPurple),
          ),
        ],
      ),
    );
  }

  Widget _circle(double d, Color color) {
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// A small Notion-style character holding a bowl — for the order bar.
class SnackCharacterIllustration extends StatelessWidget {
  final double height;
  const SnackCharacterIllustration({super.key, this.height = 56});

  @override
  Widget build(BuildContext context) {
    final w = height * 0.56; // ~83:147 aspect ratio
    return SizedBox(
      width: w,
      height: height,
      child: CustomPaint(painter: _CharacterPainter()),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    final stroke = Paint()
      ..color = IllustrationColors.outline.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // --- Hair (behind head) ---
    canvas.drawCircle(
      Offset(cx, h * 0.14),
      w * 0.28,
      Paint()..color = IllustrationColors.warmBrown,
    );

    // --- Head ---
    final headR = w * 0.24;
    final headCy = h * 0.15;
    canvas.drawCircle(Offset(cx, headCy), headR, Paint()..color = IllustrationColors.peach);
    canvas.drawCircle(Offset(cx, headCy), headR, stroke);

    // Eyes
    final eyePaint = Paint()..color = IllustrationColors.outline;
    canvas.drawCircle(Offset(cx - w * 0.08, headCy - h * 0.005), 1.5, eyePaint);
    canvas.drawCircle(Offset(cx + w * 0.08, headCy - h * 0.005), 1.5, eyePaint);

    // Smile
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, headCy + h * 0.025), width: w * 0.14, height: h * 0.04),
      0.2, 2.7, false,
      Paint()
        ..color = IllustrationColors.outline.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // --- Body ---
    final bodyTop = h * 0.27;
    final bodyBot = h * 0.58;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.28, bodyTop, cx + w * 0.28, bodyBot),
        const Radius.circular(6),
      ),
      Paint()..color = IllustrationColors.softBlue,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.28, bodyTop, cx + w * 0.28, bodyBot),
        const Radius.circular(6),
      ),
      stroke,
    );

    // --- Left arm (holding bowl out) ---
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.28, bodyTop + h * 0.06)
        ..quadraticBezierTo(cx - w * 0.55, bodyTop + h * 0.12, cx - w * 0.45, bodyTop + h * 0.22),
      stroke,
    );

    // --- Right arm (waving) ---
    canvas.drawPath(
      Path()
        ..moveTo(cx + w * 0.28, bodyTop + h * 0.06)
        ..quadraticBezierTo(cx + w * 0.58, bodyTop - h * 0.02, cx + w * 0.50, bodyTop - h * 0.08),
      stroke,
    );
    // Hand dot
    _dot(canvas, Offset(cx + w * 0.50, bodyTop - h * 0.08), 2, IllustrationColors.peach);

    // --- Small bowl in left hand ---
    final bowlCx = cx - w * 0.45;
    final bowlCy = bodyTop + h * 0.22;
    final bowlPath = Path()
      ..moveTo(bowlCx - w * 0.14, bowlCy - h * 0.01)
      ..quadraticBezierTo(bowlCx - w * 0.12, bowlCy + h * 0.06, bowlCx, bowlCy + h * 0.06)
      ..quadraticBezierTo(bowlCx + w * 0.12, bowlCy + h * 0.06, bowlCx + w * 0.14, bowlCy - h * 0.01);
    canvas.drawPath(bowlPath, Paint()..color = IllustrationColors.softOrange);
    canvas.drawPath(bowlPath, stroke);
    // Food dots in bowl
    _dot(canvas, Offset(bowlCx - w * 0.04, bowlCy + h * 0.01), 2, IllustrationColors.softGreen);
    _dot(canvas, Offset(bowlCx + w * 0.05, bowlCy + h * 0.015), 1.8, IllustrationColors.softPink);

    // --- Legs ---
    final legTop = bodyBot;
    final legBot = h * 0.82;
    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.22, legTop, cx - w * 0.04, legBot),
        const Radius.circular(4),
      ),
      Paint()..color = IllustrationColors.softPurple,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.22, legTop, cx - w * 0.04, legBot),
        const Radius.circular(4),
      ),
      stroke,
    );
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + w * 0.04, legTop, cx + w * 0.22, legBot),
        const Radius.circular(4),
      ),
      Paint()..color = IllustrationColors.softPurple,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + w * 0.04, legTop, cx + w * 0.22, legBot),
        const Radius.circular(4),
      ),
      stroke,
    );

    // --- Shoes ---
    final shoeY = legBot;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.26, shoeY, cx - w * 0.02, shoeY + h * 0.06),
        const Radius.circular(3),
      ),
      Paint()..color = IllustrationColors.warmBrown,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + w * 0.02, shoeY, cx + w * 0.26, shoeY + h * 0.06),
        const Radius.circular(3),
      ),
      Paint()..color = IllustrationColors.warmBrown,
    );

    // --- Small sparkle near waving hand ---
    _sparkle(canvas, Offset(cx + w * 0.62, bodyTop - h * 0.12), 3, IllustrationColors.softOrange);
  }

  void _dot(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(c, r, Paint()..color = color);
  }

  void _sparkle(Canvas canvas, Offset c, double s, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.22, c.dy - s * 0.22)
      ..lineTo(c.dx + s, c.dy)
      ..lineTo(c.dx + s * 0.22, c.dy + s * 0.22)
      ..lineTo(c.dx, c.dy + s)
      ..lineTo(c.dx - s * 0.22, c.dy + s * 0.22)
      ..lineTo(c.dx - s, c.dy)
      ..lineTo(c.dx - s * 0.22, c.dy - s * 0.22)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A minimal decorative header accent — a small row of colored dots.
/// Use sparingly at the top of sections for subtle Notion-style warmth.
class SectionAccent extends StatelessWidget {
  const SectionAccent({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _accentDot(IllustrationColors.peach),
        const SizedBox(width: 4),
        _accentDot(IllustrationColors.softBlue),
        const SizedBox(width: 4),
        _accentDot(IllustrationColors.softGreen),
      ],
    );
  }

  Widget _accentDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
