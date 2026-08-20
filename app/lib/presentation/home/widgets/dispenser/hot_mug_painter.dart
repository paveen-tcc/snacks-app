import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a ceramic hot beverage mug with empty/filled states, pouring stream,
/// coffee froth/crema, sugar cubes, and animated steam vapor trails.
class HotMugPainter extends CustomPainter {
  const HotMugPainter({
    required this.liquidColor,
    required this.secondaryLiquidColor,
    required this.accentLiquidColor,
    required this.fillLevel, // 0.0 = empty mug
    required this.streamProgress,
    required this.steamPhase,
    required this.hasSugar,
    required this.isDark,
  });

  final Color liquidColor;
  final Color secondaryLiquidColor;
  final Color accentLiquidColor;
  final double fillLevel;
  final double streamProgress;
  final double steamPhase;
  final bool hasSugar;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final mugLeft = w * 0.28;
    final mugRight = w * 0.72;
    final mugTop = h * 0.34;
    final mugBottom = h * 0.85;
    final mugWidth = mugRight - mugLeft;

    // 1. Draw Pouring Stream (if pouring active)
    if (streamProgress > 0.01 && fillLevel > 0.0) {
      _drawPouringStream(canvas, size, mugTop, mugBottom, fillLevel);
    }

    // 2. Draw Ceramic Handle on the right side
    final handlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF383844), const Color(0xFF22222A)]
            : [const Color(0xFFE6E6EE), const Color(0xFFC6C6D2)],
      ).createShader(Rect.fromLTWH(mugRight - 10, mugTop + 14, 48, 60))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final handlePath = Path()
      ..moveTo(mugRight - 8, mugTop + 20)
      ..cubicTo(
        mugRight + 44,
        mugTop + 22,
        mugRight + 44,
        mugBottom - 26,
        mugRight - 8,
        mugBottom - 22,
      );
    canvas.drawPath(handlePath, handlePaint);

    // 3. Draw Mug Body
    final mugPath = Path()
      ..moveTo(mugLeft, mugTop + 8)
      ..lineTo(mugLeft + 8, mugBottom - 10)
      ..quadraticBezierTo(mugLeft + 8, mugBottom, mugLeft + 20, mugBottom)
      ..lineTo(mugRight - 20, mugBottom)
      ..quadraticBezierTo(mugRight - 8, mugBottom, mugRight - 8, mugBottom - 10)
      ..lineTo(mugRight, mugTop + 8)
      ..close();

    // Mug Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.4 : 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, mugBottom + 6),
        width: mugWidth * 1.1,
        height: 14,
      ),
      shadowPaint,
    );

    // Ceramic Body Gradient
    final ceramicShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark
          ? [
              const Color(0xFF2A2A36),
              const Color(0xFF3A3A48),
              const Color(0xFF1E1E28),
            ]
          : [
              const Color(0xFFE2E2EA),
              const Color(0xFFFFFFFF),
              const Color(0xFFD2D2DC),
            ],
    ).createShader(Rect.fromLTWH(mugLeft, mugTop, mugWidth, mugBottom - mugTop));

    canvas.drawPath(mugPath, Paint()..shader = ceramicShader);

    // 4. Liquid Inside the Mug Opening
    final rimRect = Rect.fromCenter(
      center: Offset((mugLeft + mugRight) * 0.5, mugTop + 8),
      width: mugWidth,
      height: 24,
    );

    // Inner dark hollow cavity (visible when empty or partial)
    final innerHollowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? Colors.black : const Color(0xFF60606A)).withValues(alpha: 0.85),
          Colors.black.withValues(alpha: 0.95),
        ],
      ).createShader(rimRect);
    canvas.drawOval(rimRect, innerHollowPaint);

    if (fillLevel > 0.02) {
      // Liquid Fill Surface
      final liquidFillRect = Rect.fromCenter(
        center: Offset((mugLeft + mugRight) * 0.5, mugTop + 8 + (1.0 - fillLevel) * 10),
        width: mugWidth - 6,
        height: 20 * fillLevel.clamp(0.4, 1.0),
      );

      final liquidSurfacePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            liquidColor,
            secondaryLiquidColor,
          ],
        ).createShader(liquidFillRect);
      canvas.drawOval(liquidFillRect, liquidSurfacePaint);

      // Froth / Crema Swirl on surface
      final cremaPaint = Paint()
        ..color = accentLiquidColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: liquidFillRect.center,
          width: liquidFillRect.width * 0.7,
          height: liquidFillRect.height * 0.6,
        ),
        cremaPaint,
      );

      // Sugar Cubes (if enabled)
      if (hasSugar) {
        _drawSugarCube(canvas, (mugLeft + mugRight) * 0.5 - 12, liquidFillRect.center.dy - 2);
        _drawSugarCube(canvas, (mugLeft + mugRight) * 0.5 + 10, liquidFillRect.center.dy);
      }
    }

    // Outer Rim Highlight
    final rimOutline = Paint()
      ..color = (isDark ? Colors.white : Colors.grey.shade400).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(rimRect, rimOutline);

    // Specular Vertical Gleam
    final gleamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(mugLeft + 16, mugTop + 24),
      Offset(mugLeft + 20, mugBottom - 18),
      gleamPaint,
    );

    // 5. Rising Steam Vapor Trails (only when filled with hot liquid)
    if (fillLevel > 0.15) {
      _drawRisingSteam(canvas, (mugLeft + mugRight) * 0.5, mugTop, steamPhase);
    }
  }

  void _drawPouringStream(Canvas canvas, Size size, double cupTop, double cupBottom, double fill) {
    final cx = size.width * 0.5;
    final topY = 0.0;
    final targetY = cupTop + 8 + (1.0 - fill) * 10;

    final streamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          liquidColor.withValues(alpha: 0.95),
          secondaryLiquidColor,
        ],
      ).createShader(Rect.fromLTRB(cx - 4, topY, cx + 4, targetY))
      ..strokeWidth = 6.0 * streamProgress
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final streamPath = Path()..moveTo(cx, topY)..lineTo(cx, targetY);
    canvas.drawPath(streamPath, streamPaint);
  }

  void _drawSugarCube(Canvas canvas, double cx, double cy) {
    const size = 9.0;
    final half = size * 0.5;

    final topFace = Path()
      ..moveTo(cx, cy - half * 0.8)
      ..lineTo(cx + half, cy - half * 0.2)
      ..lineTo(cx, cy + half * 0.4)
      ..lineTo(cx - half, cy - half * 0.2)
      ..close();
    canvas.drawPath(topFace, Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawPath(
      topFace,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawRisingSteam(Canvas canvas, double cx, double topY, double phase) {
    final steamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final steamStreams = [
      {'ox': -18.0, 'amp': 14.0, 'h': 65.0, 'delay': 0.0},
      {'ox': 0.0, 'amp': 18.0, 'h': 85.0, 'delay': 0.35},
      {'ox': 18.0, 'amp': 12.0, 'h': 60.0, 'delay': 0.7},
    ];

    for (final s in steamStreams) {
      final ox = s['ox'] as double;
      final amp = s['amp'] as double;
      final totalH = s['h'] as double;
      final delay = s['delay'] as double;

      final progress = ((phase + delay) % 1.0);
      final currentY = topY - 4 - progress * totalH;
      final alpha = math.sin(progress * math.pi) * 0.45;

      steamPaint
        ..color = (isDark ? Colors.white : Colors.grey.shade600).withValues(alpha: alpha.clamp(0.0, 1.0))
        ..strokeWidth = 2.4 * (1.0 - progress * 0.4);

      final path = Path();
      path.moveTo(cx + ox, currentY + 20);
      path.cubicTo(
        cx + ox + math.sin(phase * 4 + ox) * amp,
        currentY + 10,
        cx + ox - math.sin(phase * 4 + ox) * amp,
        currentY - 5,
        cx + ox + math.sin(phase * 3) * (amp * 0.5),
        currentY - 20,
      );
      canvas.drawPath(path, steamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HotMugPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.streamProgress != streamProgress ||
        oldDelegate.steamPhase != steamPhase ||
        oldDelegate.liquidColor != liquidColor ||
        oldDelegate.hasSugar != hasSugar ||
        oldDelegate.isDark != isDark;
  }
}
