import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A photorealistic, skeuomorphic industrial rocker switch matching physical
/// high-end espresso machine & audio hardware switches.
///
/// Features:
/// - Beveled, textured dark industrial bezel with deep recessed cavity
/// - 3D pivoting rocker paddle with true perspective tilt transform
/// - Engraved power / sugar emblem on the rocker face
/// - Integrated rectangular glowing translucent jewel lens indicator lamp
/// - Tactile mechanical haptic click response
class SkeuomorphicRockerSwitch extends StatefulWidget {
  const SkeuomorphicRockerSwitch({
    super.key,
    required this.isSugarFree,
    required this.onChanged,
    this.width = 68.0,
    this.height = 96.0,
  });

  /// `false` means normal Sugar (switch ON), `true` means Sugar-Free / 0 Sugar (switch OFF)
  final bool isSugarFree;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  @override
  State<SkeuomorphicRockerSwitch> createState() =>
      _SkeuomorphicRockerSwitchState();
}

class _SkeuomorphicRockerSwitchState extends State<SkeuomorphicRockerSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rockController;
  late final Animation<double> _tiltAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _rockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // 0.0 = Normal Sugar (rocker tilted down at top, up at bottom)
    // 1.0 = No Sugar (rocker tilted up at top, down at bottom)
    _tiltAnimation = CurvedAnimation(
      parent: _rockController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    if (widget.isSugarFree) {
      _rockController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant SkeuomorphicRockerSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSugarFree != widget.isSugarFree) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _rockController.value = widget.isSugarFree ? 1 : 0;
      } else if (widget.isSugarFree) {
        _rockController.forward();
      } else {
        _rockController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rockController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    widget.onChanged(!widget.isSugarFree);
  }

  @override
  Widget build(BuildContext context) {
    final isSugarOn = !widget.isSugarFree;

    return Semantics(
      button: true,
      toggled: widget.isSugarFree,
      label: 'Sugar-free drink',
      hint: widget.isSugarFree
          ? 'Double tap to add regular sugar'
          : 'Double tap to remove sugar',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _toggle();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _tiltAnimation,
          builder: (context, child) {
            final t = _tiltAnimation.value; // 0.0 (Sugar) -> 1.0 (No Sugar)
            // Perspective tilt angle in radians (-0.22 to +0.22)
            final tiltAngle = (t - 0.5) * 0.44;

            return Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                // Outer dark stainless / chassis bezel plate
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1F2126),
                    Color(0xFF141518),
                    Color(0xFF0D0E10),
                  ],
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFF2E3138), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.70),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Fixed printed bezel label — always reads "SUGAR", never swaps
                  _buildPrintedLabel('SUGAR', isActive: isSugarOn),

                  const SizedBox(height: 2),

                  // 2. 3D Rocker Switch Button (icon only — the printed labels
                  // either side of it tell you which state is active)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF090A0C),
                        borderRadius: BorderRadius.circular(6),
                        // Deep recessed inner cavity shadow
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.90),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.06),
                            blurRadius: 0,
                            offset: const Offset(0, 1),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF181A1E),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: _buildRockerPaddle(tiltAngle, isSugarOn, t),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // 3. Fixed printed bezel label — always reads "0 SUGAR", never swaps
                  _buildPrintedLabel('0 SUGAR', isActive: !isSugarOn),

                  const SizedBox(height: 3),

                  // 4. Rectangular Translucent Jewel Indicator Lamp
                  _buildJewelIndicatorLamp(isSugarOn),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the 3D tilting rocker paddle with realistic bevels, depth, and engraved symbol
  Widget _buildRockerPaddle(double tiltAngle, bool isSugarOn, double t) {
    // Top highlight vs bottom shadow shifts based on tilt
    final topLightAlpha = (1.0 - t).clamp(0.15, 0.45);
    final bottomLightAlpha = t.clamp(0.15, 0.45);

    return Transform.translate(
      offset: Offset(0, _isPressed ? 1.0 : 0.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.003) // 3D perspective depth
          ..rotateX(-tiltAngle), // Rock on X-axis
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            // Heavy industrial matte plastic texture
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.45, 0.55, 1.0],
              colors: isSugarOn
                  ? [
                      const Color(0xFF22242A), // Top slightly raised
                      const Color(0xFF191B20),
                      const Color(
                        0xFF2E313A,
                      ), // Bottom pushed out catching light
                      const Color(0xFF383C46),
                    ]
                  : [
                      const Color(0xFF383C46), // Top pushed out catching light
                      const Color(0xFF2E313A),
                      const Color(0xFF191B20),
                      const Color(0xFF22242A), // Bottom slightly recessed
                    ],
            ),
            border: Border.all(color: const Color(0xFF33363E), width: 0.8),
            boxShadow: [
              // Cast shadow from the raised edge of the rocker
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.85),
                blurRadius: 3,
                offset: isSugarOn ? const Offset(0, 2) : const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top edge specular bevel line
              Positioned(
                top: 1,
                left: 3,
                right: 3,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: topLightAlpha),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),

              // Bottom edge specular bevel line
              Positioned(
                bottom: 1,
                left: 3,
                right: 3,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: bottomLightAlpha),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),

              // Center Engraved Sugar-Cube Icon — a fixed mechanical glyph, not
              // text, since real rocker switches never relabel themselves. When
              // sugar is off, a "no" slash crosses out the cube.
              CustomPaint(
                size: const Size(20, 20),
                painter: _SugarSymbolPainter(
                  color: Colors.white.withValues(
                    alpha: isSugarOn ? 0.90 : 0.55,
                  ),
                  showNoSugarSlash: !isSugarOn,
                  hasGlow: isSugarOn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A fixed, non-swapping printed bezel label (as on a real dispenser plate).
  /// Only its brightness changes to show which side is currently active.
  Widget _buildPrintedLabel(String text, {required bool isActive}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 6.4,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        color: isActive ? Colors.white70 : Colors.white24,
      ),
    );
  }

  /// Builds the rectangular translucent jewel indicator lamp (matching the red lens in the user's photo)
  Widget _buildJewelIndicatorLamp(bool isSugarOn) {
    // When Sugar is ON, bright glowing ruby red lens (exactly like the reference photo)
    // When Sugar is OFF, cool mint green or darkened lens
    final lensColor = isSugarOn
        ? const Color(0xFFFF2222)
        : const Color(0xFF00E676);
    final coreColor = isSugarOn
        ? const Color(0xFFFF8A80)
        : const Color(0xFFB9F6CA);

    return Container(
      width: 26,
      height: 11,
      decoration: BoxDecoration(
        color: const Color(0xFF08080A),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF22242A), width: 0.8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1.8),
          // Faceted translucent ruby jewel lens
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSugarOn
                ? [
                    const Color(0xFFFF5252),
                    const Color(0xFFD50000),
                    const Color(0xFF8E0000),
                  ]
                : [
                    const Color(0xFF00E676),
                    const Color(0xFF00A854),
                    const Color(0xFF004D26),
                  ],
          ),
          boxShadow: [
            // Ambient lens bloom
            BoxShadow(
              color: lensColor.withValues(alpha: 0.70),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          // High intensity filament / LED core
          child: Container(
            width: 8,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              color: coreColor.withValues(alpha: 0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.85),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a small engraved sugar-cube glyph — the icon
/// real dispenser/vending-machine sugar switches actually use (never a power
/// symbol). When [showNoSugarSlash] is true, a prohibition slash crosses the
/// cube to read as "0 sugar".
class _SugarSymbolPainter extends CustomPainter {
  const _SugarSymbolPainter({
    required this.color,
    required this.showNoSugarSlash,
    required this.hasGlow,
  });

  final Color color;
  final bool showNoSugarSlash;
  final bool hasGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (hasGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      _drawCube(canvas, size, glowPaint);
    }

    _drawCube(canvas, size, paint);

    if (showNoSugarSlash) {
      final slashPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round;
      final r = size.width * 0.46;
      final center = Offset(size.width / 2, size.height / 2 + 0.5);
      canvas.drawCircle(center, r, slashPaint);
      canvas.drawLine(
        Offset(center.dx - r * 0.72, center.dy + r * 0.72),
        Offset(center.dx + r * 0.72, center.dy - r * 0.72),
        slashPaint,
      );
    }
  }

  /// A small isometric sugar cube (front face + top face) with a couple of
  /// granule sparkles above it — the universal "sugar" glyph.
  void _drawCube(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final left = w * 0.28;
    final right = w * 0.72;
    final top = h * 0.42;
    final bottom = h * 0.82;
    final skew = w * 0.14;

    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

    final topFace = Path()
      ..moveTo(left, top)
      ..lineTo(left + skew, top - skew * 0.85)
      ..lineTo(right + skew, top - skew * 0.85)
      ..lineTo(right, top)
      ..close();
    canvas.drawPath(topFace, paint);

    canvas.drawLine(
      Offset(right, bottom),
      Offset(right + skew, bottom - skew * 0.85),
      paint,
    );
    canvas.drawLine(
      Offset(right + skew, top - skew * 0.85),
      Offset(right + skew, bottom - skew * 0.85),
      paint,
    );

    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.30, h * 0.20), 1.0, dotPaint);
    canvas.drawCircle(Offset(w * 0.44, h * 0.12), 0.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SugarSymbolPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.showNoSugarSlash != showNoSugarSlash ||
        oldDelegate.hasGlow != hasGlow;
  }
}
