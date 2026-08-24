import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a photorealistic transparent shaker cup with dark molded cap (matching user's photo),
/// real-time fluid sine-wave physics, top pouring stream, falling 3D ice cubes, and sugar cubes.
class ShakerCupPainter extends CustomPainter {
  const ShakerCupPainter({
    required this.liquidColor,
    required this.secondaryLiquidColor,
    required this.accentLiquidColor,
    required this.fillLevel, // 0.0 to 1.0 (0.0 = empty cup)
    required this.wavePhase,
    required this.streamProgress,
    required this.iceProgress,
    required this.hasIce,
    required this.hasSugar,
    required this.isDark,
    this.tiltAngle = 0.0,
  });

  final Color liquidColor;
  final Color secondaryLiquidColor;
  final Color accentLiquidColor;
  final double fillLevel;
  final double wavePhase;
  final double streamProgress;
  final double iceProgress;
  final bool hasIce;
  final bool hasSugar;
  final bool isDark;
  final double tiltAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Proportions matching the tapered shaker cup from user's photo
    final cupLeft = w * 0.22;
    final cupRight = w * 0.78;
    final cupBottomLeft = w * 0.28;
    final cupBottomRight = w * 0.72;
    final cupTop = h * 0.22;
    final cupBottom = h * 0.88;
    final cupHeight = cupBottom - cupTop;

    // 1. Draw Pouring Stream (if pouring active)
    if (streamProgress > 0.01 && fillLevel > 0.0) {
      _drawPouringStream(canvas, size, cupTop, cupBottom, fillLevel);
    }

    // 2. Cup Body Path
    final cupPath = Path()
      ..moveTo(cupLeft, cupTop)
      ..lineTo(cupBottomLeft, cupBottom - 10)
      ..quadraticBezierTo(cupBottomLeft, cupBottom, cupBottomLeft + 10, cupBottom)
      ..lineTo(cupBottomRight - 10, cupBottom)
      ..quadraticBezierTo(cupBottomRight, cupBottom, cupBottomRight, cupBottom - 10)
      ..lineTo(cupRight, cupTop)
      ..close();

    // 3. Shadow Under Cup
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.4 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, cupBottom + 8),
        width: (cupBottomRight - cupBottomLeft) * 1.3,
        height: 16,
      ),
      shadowPaint,
    );

    // 4. Transparent Frosted Glass Background with Crystal Luster
    final glassBg = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.16 : 0.09),
        (isDark ? Colors.white : Colors.grey.shade300).withValues(alpha: isDark ? 0.08 : 0.04),
        (isDark ? const Color(0xFF6366F1) : const Color(0xFF818CF8)).withValues(alpha: isDark ? 0.14 : 0.08),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(cupPath, Paint()..shader = glassBg);

    // 5. Volume Measurement Ticks on Glass (100ml, 200ml, 300ml)
    _drawMeasurementTicks(canvas, cupLeft, cupBottomLeft, cupTop, cupBottom);

    // 6. Liquid Fill Layer (If filled)
    if (fillLevel > 0.01) {
      canvas.save();
      canvas.clipPath(cupPath);

      final currentLiquidHeight = cupHeight * fillLevel * 0.85;
      final liquidSurfaceY = cupBottom - currentLiquidHeight;
      final tiltSlope = math.tan(tiltAngle.clamp(-0.45, 0.45));

      // Primary Liquid Gradient
      final liquidGrad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          liquidColor.withValues(alpha: 0.94),
          secondaryLiquidColor.withValues(alpha: 0.98),
        ],
      ).createShader(Rect.fromLTRB(cupLeft, liquidSurfaceY - 10, cupRight, cupBottom));

      // Wave 1: Dynamic Fluid Surface Wave with Gyroscopic Tilt Slosh
      final wave1 = Path()..moveTo(0, cupBottom);
      wave1.lineTo(0, liquidSurfaceY);
      for (double x = 0; x <= w; x += 4) {
        final tiltY = (x - w * 0.5) * tiltSlope;
        final y = liquidSurfaceY + tiltY + math.sin(wavePhase + x * 0.04) * (fillLevel < 0.9 ? 4.5 : 2.5);
        wave1.lineTo(x, y);
      }
      wave1.lineTo(w, cupBottom);
      wave1.close();
      canvas.drawPath(wave1, Paint()..shader = liquidGrad);

      // Wave 2: Top Surface Shimmer / Light Crest
      final shimmerPaint = Paint()
        ..color = accentLiquidColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      final wave2 = Path()..moveTo(0, liquidSurfaceY);
      for (double x = 0; x <= w; x += 4) {
        final tiltY = (x - w * 0.5) * tiltSlope;
        final y = liquidSurfaceY + tiltY + math.sin(wavePhase + math.pi * 0.5 + x * 0.04) * 3.0;
        wave2.lineTo(x, y);
      }
      canvas.drawPath(wave2, shimmerPaint);

      // 7. 3D Ice Cubes
      if (hasIce && iceProgress > 0.05) {
        _draw3DIceCubes(canvas, w, liquidSurfaceY, cupBottom, iceProgress);
      }

      // 8. Sugar Cubes (if sugar enabled)
      if (hasSugar) {
        _drawSugarCubes(canvas, w, liquidSurfaceY, cupBottom);
      }

      canvas.restore();
    }

    // 9. Glass Specular Highlights & Outlines
    final glassOutline = Paint()
      ..color = (isDark ? const Color(0xFF93C5FD) : const Color(0xFF64748B)).withValues(alpha: isDark ? 0.45 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(cupPath, glassOutline);

    // Left curved primary specular sheen line
    final sheenPath = Path()
      ..moveTo(cupLeft + 8, cupTop + 10)
      ..lineTo(cupBottomLeft + 7, cupBottom - 14);
    canvas.drawPath(
      sheenPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Right secondary subtle reflection
    final rightSheenPath = Path()
      ..moveTo(cupRight - 8, cupTop + 16)
      ..lineTo(cupBottomRight - 7, cupBottom - 20);
    canvas.drawPath(
      rightSheenPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // 10. Dark Molded Shaker Lid (Authentic to user's photo)
    _drawShakerLid(canvas, cupLeft, cupRight, cupTop, isDark);
  }

  void _drawMeasurementTicks(Canvas canvas, double cupLeft, double cupBottomLeft, double cupTop, double cupBottom) {
    final tickPaint = Paint()
      ..color = (isDark ? const Color(0xFFBAE6FD) : const Color(0xFF475569)).withValues(alpha: 0.45)
      ..strokeWidth = 1.5;

    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      final y = cupBottom - (cupBottom - cupTop) * t;
      final x = cupBottomLeft + (cupLeft - cupBottomLeft) * t;
      canvas.drawLine(Offset(x + 5, y), Offset(x + 15, y), tickPaint);
    }
  }

  void _drawPouringStream(Canvas canvas, Size size, double cupTop, double cupBottom, double fill) {
    final cx = size.width * 0.5;
    final topY = 0.0;
    final targetY = cupBottom - (cupBottom - cupTop) * fill * 0.85;

    final streamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          liquidColor.withValues(alpha: 0.95),
          secondaryLiquidColor,
        ],
      ).createShader(Rect.fromLTRB(cx - 5, topY, cx + 5, targetY))
      ..strokeWidth = 7.0 * streamProgress
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final streamPath = Path()
      ..moveTo(cx, topY)
      ..quadraticBezierTo(cx + math.sin(wavePhase * 2) * 2.0, targetY * 0.5, cx, targetY);

    canvas.drawPath(streamPath, streamPaint);

    final splashPaint = Paint()
      ..color = accentLiquidColor.withValues(alpha: 0.6 * streamProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, targetY), 10 * streamProgress, splashPaint);
  }

  void _drawShakerLid(Canvas canvas, double left, double right, double topY, bool isDark) {
    final cx = (left + right) * 0.5;
    final lidWidth = (right - left) + 20;
    final lidLeft = cx - lidWidth * 0.5;
    final lidRight = cx + lidWidth * 0.5;

    // Dark sleek molded lid colors
    final lidGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              const Color(0xFF475569),
              const Color(0xFF334155),
              const Color(0xFF1E293B),
            ]
          : [
              const Color(0xFF64748B),
              const Color(0xFF475569),
              const Color(0xFF334155),
            ],
    ).createShader(Rect.fromLTWH(lidLeft, topY - 38, lidWidth, 42));

    final lidPaint = Paint()..shader = lidGradient;

    // Base collar ring
    final collarRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(lidLeft, topY - 10, lidRight, topY + 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(collarRect, lidPaint);

    // Domed upper cap
    final domePath = Path()
      ..moveTo(lidLeft + 6, topY - 10)
      ..lineTo(lidLeft + 12, topY - 28)
      ..quadraticBezierTo(cx, topY - 34, lidRight - 12, topY - 28)
      ..lineTo(lidRight - 6, topY - 10)
      ..close();
    canvas.drawPath(domePath, lidPaint);

    // Sip-spout on top right
    final spoutPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    final spoutPath = Path()
      ..moveTo(cx + 12, topY - 28)
      ..lineTo(cx + 14, topY - 44)
      ..quadraticBezierTo(cx + 26, topY - 46, cx + 34, topY - 40)
      ..lineTo(cx + 30, topY - 26)
      ..close();
    canvas.drawPath(spoutPath, spoutPaint);

    // Loop strap on spout (as in photo)
    final loopPaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final loopPath = Path()
      ..moveTo(cx + 28, topY - 44)
      ..quadraticBezierTo(cx + 48, topY - 40, cx + 40, topY - 24);
    canvas.drawPath(loopPath, loopPaint);

    // Lid Highlight ridge
    final lidHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(lidLeft + 8, topY - 9), Offset(lidRight - 8, topY - 9), lidHighlight);
  }

  void _draw3DIceCubes(Canvas canvas, double width, double surfaceY, double bottomY, double progress) {
    final cubes = [
      {'cx': width * 0.42, 'targetY': surfaceY + 22.0, 'delay': 0.0, 'size': 18.0, 'rot': 0.15},
      {'cx': width * 0.58, 'targetY': surfaceY + 36.0, 'delay': 0.15, 'size': 20.0, 'rot': -0.22},
      {'cx': width * 0.48, 'targetY': surfaceY + 54.0, 'delay': 0.3, 'size': 17.0, 'rot': 0.35},
    ];

    for (final c in cubes) {
      final delay = c['delay'] as double;
      if (progress < delay) continue;
      final localT = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);

      final targetY = c['targetY'] as double;
      final fallY = -20.0 + (targetY + 20.0) * _bounceEase(localT);
      final cx = c['cx'] as double;
      final sz = c['size'] as double;
      final rot = c['rot'] as double;

      canvas.save();
      canvas.translate(cx, fallY);
      canvas.rotate(rot);

      _drawIsometricCube(canvas, sz, Colors.white.withValues(alpha: 0.65));

      canvas.restore();
    }
  }

  void _drawSugarCubes(Canvas canvas, double width, double surfaceY, double bottomY) {
    // Two pristine white sugar cubes resting near the top of the fluid
    final sugarCubes = [
      {'cx': width * 0.38, 'y': surfaceY + 12.0, 'size': 12.0, 'rot': 0.25},
      {'cx': width * 0.62, 'y': surfaceY + 16.0, 'size': 11.0, 'rot': -0.3},
    ];

    for (final s in sugarCubes) {
      canvas.save();
      canvas.translate(s['cx'] as double, s['y'] as double);
      canvas.rotate(s['rot'] as double);

      _drawIsometricCube(canvas, s['size'] as double, Colors.white.withValues(alpha: 0.92));

      canvas.restore();
    }
  }

  void _drawIsometricCube(Canvas canvas, double size, Color baseColor) {
    final half = size * 0.5;

    final topPaint = Paint()..color = baseColor;
    final leftPaint = Paint()..color = baseColor.withValues(alpha: 0.75);
    final rightPaint = Paint()..color = baseColor.withValues(alpha: 0.55);
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Top face
    final topFace = Path()
      ..moveTo(0, -half * 0.8)
      ..lineTo(half, -half * 0.2)
      ..lineTo(0, half * 0.4)
      ..lineTo(-half, -half * 0.2)
      ..close();
    canvas.drawPath(topFace, topPaint);
    canvas.drawPath(topFace, borderPaint);

    // Left face
    final leftFace = Path()
      ..moveTo(-half, -half * 0.2)
      ..lineTo(0, half * 0.4)
      ..lineTo(0, half * 1.1)
      ..lineTo(-half, half * 0.5)
      ..close();
    canvas.drawPath(leftFace, leftPaint);
    canvas.drawPath(leftFace, borderPaint);

    // Right face
    final rightFace = Path()
      ..moveTo(0, half * 0.4)
      ..lineTo(half, -half * 0.2)
      ..lineTo(half, half * 0.5)
      ..lineTo(0, half * 1.1)
      ..close();
    canvas.drawPath(rightFace, rightPaint);
    canvas.drawPath(rightFace, borderPaint);
  }

  double _bounceEase(double t) {
    if (t < 0.7) {
      return (t / 0.7) * (t / 0.7);
    } else {
      final sub = (t - 0.7) / 0.3;
      return 1.0 - math.sin(sub * math.pi) * 0.08;
    }
  }

  @override
  bool shouldRepaint(covariant ShakerCupPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.streamProgress != streamProgress ||
        oldDelegate.iceProgress != iceProgress ||
        oldDelegate.liquidColor != liquidColor ||
        oldDelegate.hasIce != hasIce ||
        oldDelegate.hasSugar != hasSugar ||
        oldDelegate.isDark != isDark;
  }
}
