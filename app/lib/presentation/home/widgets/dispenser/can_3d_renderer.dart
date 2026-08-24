import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'drink_dispenser_models.dart';

/// Renders a photorealistic market-accurate 3D soda / energy drink can.
///
/// Features:
/// - Direct native WebGL 3D ModelViewer for GLB assets (Coke, Diet Coke, Red Bull, Monster)
/// - A single active WebGL context, disposed whenever the preview is off-screen
/// - Interactive 360° swipe rotation, specular metallic reflections, brushed aluminum lid
class Can3DRenderer extends StatefulWidget {
  const Can3DRenderer({
    super.key,
    required this.presentation,
    required this.isDark,
    this.isActive = true,
    this.semanticLabel = '3D Drink Can',
    this.fallbackAssetPath,
  });

  final DrinkPresentation presentation;
  final bool isDark;
  final bool isActive;
  final String semanticLabel;
  final String? fallbackAssetPath;

  @override
  State<Can3DRenderer> createState() => _Can3DRendererState();
}

class _Can3DRendererState extends State<Can3DRenderer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  double _rotationAngle = 0.0;
  AnimationController? _idleController;
  WebViewController? _webViewController;
  bool _appIsActive = true;
  bool? _lastReduceMotion;

  bool get _hasModel => widget.presentation.model3dPath?.isNotEmpty ?? false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_hasModel) {
      _idleController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 8),
      )..repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_lastReduceMotion != reduceMotion) {
      _lastReduceMotion = reduceMotion;
      _syncPlayback();
    }
  }

  @override
  void didUpdateWidget(covariant Can3DRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
    _syncPlayback();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleController?.dispose();
    super.dispose();
  }

  bool get _reduceMotion => _lastReduceMotion ?? false;

  void _syncPlayback() {
    final shouldAnimate = widget.isActive && _appIsActive && !_reduceMotion;
    final idle = _idleController;
    if (idle != null) {
      if (shouldAnimate && !idle.isAnimating) {
        idle.repeat();
      } else if (!shouldAnimate && idle.isAnimating) {
        idle.stop();
      }
    }
    final controller = _webViewController;
    if (controller != null) {
      unawaited(
        controller
            .runJavaScript(
              "document.querySelector('model-viewer').autoRotate = ${shouldAnimate ? 'true' : 'false'};",
            )
            .catchError((_) {}),
      );
    }
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    setState(() {
      _rotationAngle += details.primaryDelta! * 0.015;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // If a genuine 3D GLB model exists, render it directly via ModelViewer
    if (_hasModel) {
      return SizedBox(
        width: 175,
        height: 255,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft realistic ground contact shadow
            Positioned(
              bottom: 14,
              child: Container(
                width: 130,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: widget.isDark ? 0.40 : 0.20,
                      ),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Hardware-accelerated 3D ModelViewer with transparent background.
            Semantics(
              label:
                  '${widget.semanticLabel}, interactive 3D preview. Swipe to rotate.',
              image: true,
              child: SizedBox(
                width: 175,
                height: 255,
                child: ModelViewer(
                  key: ValueKey('mv_${widget.presentation.model3dPath}'),
                  src: widget.presentation.model3dPath!,
                  alt: widget.semanticLabel,
                  autoRotate: widget.isActive && _appIsActive && !_reduceMotion,
                  autoRotateDelay: 800,
                  rotationPerSecond: '18deg',
                  cameraControls: true,
                  disableZoom: true,
                  loading: Loading.eager,
                  reveal: Reveal.auto,
                  interactionPrompt: InteractionPrompt.none,
                  backgroundColor: Colors.transparent,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    _syncPlayback();
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2D Vector can for drinks without a GLB asset (Sprite, generic soda, etc.)
    return GestureDetector(
      onHorizontalDragUpdate: _handleHorizontalDrag,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedBuilder(
          animation: _idleController!,
          builder: (context, child) {
            final effectiveAngle =
                _rotationAngle + (_idleController!.value * 2 * math.pi * 0.15);

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateY(effectiveAngle)
                ..rotateX(-0.04),
              child: CustomPaint(
                size: const Size(175, 255),
                painter: _MarketCanPainter(
                  presentation: widget.presentation,
                  rotationAngle: effectiveAngle,
                  isDark: widget.isDark,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarketCanPainter extends CustomPainter {
  const _MarketCanPainter({
    required this.presentation,
    required this.rotationAngle,
    required this.isDark,
  });

  final DrinkPresentation presentation;
  final double rotationAngle;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final canLeft = 8.0;
    final canRight = w - 8.0;
    final canTop = 18.0;
    final canBottom = h - 18.0;
    final canW = canRight - canLeft;

    // 1. Realistic Soft Drop Shadow Underneath
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.45 : 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, canBottom + 10),
        width: canW * 1.08,
        height: 18,
      ),
      shadowPaint,
    );

    // 2. Can Main Cylindrical Body
    final canBodyRect = Rect.fromLTRB(
      canLeft,
      canTop + 14,
      canRight,
      canBottom - 12,
    );

    // Specular light calculations based on 360 angle
    final normAngle =
        (rotationAngle % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
    final spec1 = (0.28 + math.sin(normAngle) * 0.18).clamp(0.08, 0.92);
    final spec2 = (0.76 + math.cos(normAngle) * 0.12).clamp(0.1, 0.95);

    // Dynamic metallic base gradient
    final baseGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: [0.0, spec1 * 0.5, spec1, spec2, 1.0],
      colors: [
        presentation.secondaryColor,
        presentation.primaryColor,
        presentation.primaryColor.withValues(alpha: 0.95),
        presentation.secondaryColor,
        presentation.secondaryColor.withValues(alpha: 0.85),
      ],
    ).createShader(canBodyRect);

    canvas.drawRect(canBodyRect, Paint()..shader = baseGradient);

    // 3. Render 360 Authentic Brand Graphics
    _draw360BrandGraphics(
      canvas,
      canBodyRect,
      presentation.canBrand ?? 'SODA',
      normAngle,
    );

    // 4. Cylindrical Specular Glare & Metallic Sheen
    final metallicGlare = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: [0.0, spec1 - 0.12, spec1, spec1 + 0.12, 0.82, 1.0],
      colors: [
        Colors.black.withValues(alpha: 0.45),
        Colors.transparent,
        Colors.white.withValues(alpha: 0.40),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.22),
        Colors.black.withValues(alpha: 0.55),
      ],
    ).createShader(canBodyRect);

    canvas.drawRect(canBodyRect, Paint()..shader = metallicGlare);

    // Subtle brushed metal vertical micro-lines
    final brushPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    for (double bx = canLeft + 6; bx < canRight - 6; bx += 8) {
      canvas.drawLine(
        Offset(bx, canBodyRect.top),
        Offset(bx, canBodyRect.bottom),
        brushPaint,
      );
    }

    // 5. Aluminum Top Neck & Chime
    _drawBrushedAluminumTop(
      canvas,
      canLeft,
      canRight,
      canTop,
      isDark,
      normAngle,
    );

    // 6. Aluminum Bottom Chime
    _drawBrushedAluminumBottom(
      canvas,
      canLeft,
      canRight,
      canBottom,
      isDark,
      normAngle,
    );
  }

  void _draw360BrandGraphics(
    Canvas canvas,
    Rect bodyRect,
    String brand,
    double angle,
  ) {
    canvas.save();
    canvas.clipRect(bodyRect);

    final cx = bodyRect.center.dx;
    final cy = bodyRect.center.dy;
    final w = bodyRect.width;

    final offsetFactor = (angle / (2 * math.pi)) * w * 2.0;

    switch (brand) {
      case 'REDBULL':
        _drawRedBullWrap(canvas, bodyRect, offsetFactor, cx, cy);
        break;

      case 'MONSTER':
        _drawMonsterWrap(canvas, bodyRect, offsetFactor, cx, cy);
        break;

      case 'COKE':
        _drawCokeWrap(canvas, bodyRect, offsetFactor, cx, cy);
        break;

      case 'DIET_COKE':
        _drawDietCokeWrap(canvas, bodyRect, offsetFactor, cx, cy);
        break;

      case 'SPRITE':
        _drawSpriteWrap(canvas, bodyRect, offsetFactor, cx, cy);
        break;

      default:
        final stripePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawLine(
          Offset(bodyRect.left, cy - 20),
          Offset(bodyRect.right, cy - 20),
          stripePaint,
        );
        canvas.drawLine(
          Offset(bodyRect.left, cy + 20),
          Offset(bodyRect.right, cy + 20),
          stripePaint,
        );
    }

    canvas.restore();
  }

  void _drawRedBullWrap(
    Canvas canvas,
    Rect r,
    double offset,
    double cx,
    double cy,
  ) {
    final silverPaint = Paint()..color = const Color(0xFFDCDCE6);
    final redPaint = Paint()..color = const Color(0xFFE51A31);
    final yellowPaint = Paint()..color = const Color(0xFFFFCC00);

    for (int i = -1; i <= 2; i++) {
      final baseLeft = r.left + (i * r.width) + (offset % r.width);
      final diag = Path()
        ..moveTo(baseLeft, r.top)
        ..lineTo(baseLeft + r.width, r.bottom)
        ..lineTo(baseLeft + r.width, r.top)
        ..close();
      canvas.drawPath(diag, silverPaint);
    }

    final sunX = cx + math.sin(offset * 0.05) * (r.width * 0.25);
    canvas.drawCircle(Offset(sunX, cy), 24, yellowPaint);

    final bull1 = Path()
      ..moveTo(sunX - 22, cy + 4)
      ..quadraticBezierTo(sunX - 10, cy - 12, sunX - 2, cy)
      ..lineTo(sunX - 6, cy + 8)
      ..close();
    canvas.drawPath(bull1, redPaint);

    final bull2 = Path()
      ..moveTo(sunX + 22, cy + 4)
      ..quadraticBezierTo(sunX + 10, cy - 12, sunX + 2, cy)
      ..lineTo(sunX + 6, cy + 8)
      ..close();
    canvas.drawPath(bull2, redPaint);

    final textPaint = Paint()
      ..color = const Color(0xFF001F5C)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(sunX, cy + 32), width: 54, height: 6),
      textPaint,
    );
  }

  void _drawMonsterWrap(
    Canvas canvas,
    Rect r,
    double offset,
    double cx,
    double cy,
  ) {
    final clawPaint = Paint()
      ..color = const Color(0xFF39FF14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF39FF14).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    final logoX = cx + math.sin(offset * 0.05) * (r.width * 0.28);

    final c1 = Path()
      ..moveTo(logoX - 18, cy - 28)
      ..lineTo(logoX - 12, cy + 32);
    final c2 = Path()
      ..moveTo(logoX, cy - 36)
      ..lineTo(logoX, cy + 38);
    final c3 = Path()
      ..moveTo(logoX + 18, cy - 24)
      ..lineTo(logoX + 12, cy + 28);

    canvas.drawPath(c1, glowPaint);
    canvas.drawPath(c2, glowPaint);
    canvas.drawPath(c3, glowPaint);

    canvas.drawPath(c1, clawPaint);
    canvas.drawPath(c2, clawPaint);
    canvas.drawPath(c3, clawPaint);
  }

  void _drawCokeWrap(
    Canvas canvas,
    Rect r,
    double offset,
    double cx,
    double cy,
  ) {
    final wavePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final subWavePaint = Paint()
      ..color = const Color(0xFFC0C0C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final waveX = cx + math.sin(offset * 0.05) * (r.width * 0.25);

    final wave1 = Path()
      ..moveTo(r.left, cy + 22)
      ..quadraticBezierTo(waveX - 18, cy - 32, waveX, cy + 8)
      ..quadraticBezierTo(waveX + 24, cy + 34, r.right, cy - 18);
    canvas.drawPath(wave1, wavePaint);

    final wave2 = Path()
      ..moveTo(r.left, cy + 30)
      ..quadraticBezierTo(waveX - 18, cy - 24, waveX, cy + 16)
      ..quadraticBezierTo(waveX + 24, cy + 42, r.right, cy - 10);
    canvas.drawPath(wave2, subWavePaint);
  }

  void _drawDietCokeWrap(
    Canvas canvas,
    Rect r,
    double offset,
    double cx,
    double cy,
  ) {
    final wavePaint = Paint()
      ..color = const Color(0xFFE51C23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final subWavePaint = Paint()
      ..color = const Color(0xFF202020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final waveX = cx + math.sin(offset * 0.05) * (r.width * 0.25);

    final wave1 = Path()
      ..moveTo(r.left, cy + 22)
      ..quadraticBezierTo(waveX - 18, cy - 32, waveX, cy + 8)
      ..quadraticBezierTo(waveX + 24, cy + 34, r.right, cy - 18);
    canvas.drawPath(wave1, wavePaint);

    final wave2 = Path()
      ..moveTo(r.left, cy + 30)
      ..quadraticBezierTo(waveX - 18, cy - 24, waveX, cy + 16)
      ..quadraticBezierTo(waveX + 24, cy + 42, r.right, cy - 10);
    canvas.drawPath(wave2, subWavePaint);
  }

  void _drawSpriteWrap(
    Canvas canvas,
    Rect r,
    double offset,
    double cx,
    double cy,
  ) {
    final lemonX = cx + math.sin(offset * 0.05) * (r.width * 0.25);

    final lemonPaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(Offset(lemonX, cy - 12), 18, lemonPaint);

    canvas.drawCircle(
      Offset(lemonX, cy - 12),
      13,
      Paint()..color = const Color(0xFF008B47),
    );

    final textPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lemonX, cy + 20), width: 62, height: 10),
        const Radius.circular(3),
      ),
      textPaint,
    );
  }

  void _drawBrushedAluminumTop(
    Canvas canvas,
    double left,
    double right,
    double topY,
    bool isDark,
    double angle,
  ) {
    final w = right - left;
    final cx = (left + right) * 0.5;

    final neckPath = Path()
      ..moveTo(left, topY + 14)
      ..lineTo(left + 6, topY + 4)
      ..lineTo(right - 6, topY + 4)
      ..lineTo(right, topY + 14)
      ..close();

    final aluminumShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFF7A7A84),
        const Color(0xFFDCDCE6),
        const Color(0xFFFFFFFF),
        const Color(0xFFAAAAAF),
        const Color(0xFF62626C),
      ],
    ).createShader(Rect.fromLTWH(left, topY, w, 24));

    canvas.drawPath(neckPath, Paint()..shader = aluminumShader);

    final lidRect = Rect.fromCenter(
      center: Offset(cx, topY + 4),
      width: w - 12,
      height: 14,
    );
    canvas.drawOval(lidRect, Paint()..shader = aluminumShader);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, topY + 4), width: w - 16, height: 11),
      Paint()..color = const Color(0xFF5A5A64),
    );

    final tabAngle = angle * 0.5;
    final tabOffset = math.sin(tabAngle) * 6.0;

    final tabPaint = Paint()
      ..color = const Color(0xFFE2E2EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + tabOffset, topY + 3.5),
        width: 14,
        height: 6.5,
      ),
      tabPaint,
    );

    canvas.drawCircle(
      Offset(cx + tabOffset * 0.5, topY + 4),
      2.0,
      Paint()..color = const Color(0xFF90909A),
    );
  }

  void _drawBrushedAluminumBottom(
    Canvas canvas,
    double left,
    double right,
    double bottomY,
    bool isDark,
    double angle,
  ) {
    final w = right - left;
    final cx = (left + right) * 0.5;

    final bottomPath = Path()
      ..moveTo(left, bottomY - 12)
      ..lineTo(left + 7, bottomY)
      ..lineTo(right - 7, bottomY)
      ..lineTo(right, bottomY - 12)
      ..close();

    final aluminumShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFF62626C),
        const Color(0xFFD4D4DE),
        const Color(0xFFFFFFFF),
        const Color(0xFF888892),
        const Color(0xFF505058),
      ],
    ).createShader(Rect.fromLTWH(left, bottomY - 12, w, 14));

    canvas.drawPath(bottomPath, Paint()..shader = aluminumShader);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bottomY), width: w - 16, height: 8),
      Paint()..color = const Color(0xFF404048),
    );
  }

  @override
  bool shouldRepaint(covariant _MarketCanPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.presentation != presentation ||
        oldDelegate.isDark != isDark;
  }
}
