import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/core/constants/app_constants.dart';
import 'package:speakup/features/settings/data/models/user_settings_hive.dart';

// =============================================================================
// SplashScreen — "The Curated Orator"
// Faithfully ported from the HTML reference design.
// =============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Animation controllers
  // ---------------------------------------------------------------------------

  /// Master controller — drives the staggered entrance sequence.
  late final AnimationController _master;

  // Logo card
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;

  // Brand name
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;

  // Est. ornament line under brand
  late final Animation<double> _ornamentOpacity;

  // Tagline & loading dots
  late final Animation<double> _taglineOpacity;

  // Editorial side text (large screens)
  late final Animation<double> _sideTextOpacity;

  // Decorative background blobs
  late final Animation<double> _blobOpacity;

  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();

    _master = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    // ── Logo card ─────────────────────────────────────────────────────────
    _logoOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // ── Brand name ────────────────────────────────────────────────────────
    _nameOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // ── Ornament ──────────────────────────────────────────────────────────
    _ornamentOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.40, 0.75, curve: Curves.easeOut),
    );

    // ── Tagline + dots ────────────────────────────────────────────────────
    _taglineOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    // ── Side editorial text ───────────────────────────────────────────────
    _sideTextOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
    );

    // ── Background blobs ──────────────────────────────────────────────────
    _blobOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
    );

    _master.forward();
    _navigateTimer = Timer(const Duration(milliseconds: 2800), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final box = Hive.box<UserSettingsHive>(AppConstants.hiveSettingsBoxName);
    final hive = box.get(AppConstants.hiveUserSettingsKey);
    final bool seen = hive?.hasSeenOnboarding ?? false;
    if (!mounted) return;
    seen ? context.go(AppRoutes.home) : context.go(AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    _master.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLarge = size.width >= 1024; // lg breakpoint

    return Scaffold(
      backgroundColor: AppColorsNew.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Grainy / paper surface ──────────────────────────────────────
          const _GrainySurface(),

          // ── Decorative background blobs ─────────────────────────────────
          FadeTransition(opacity: _blobOpacity, child: const _BackgroundBlobs()),

          // ── Editorial side text (lg screens only) ──────────────────────
          if (isLarge)
            Positioned(
              left: 40,
              top: 0,
              bottom: 0,
              child: FadeTransition(opacity: _sideTextOpacity, child: const _SideEditorialText()),
            ),

          // ── Main content column ─────────────────────────────────────────
          Column(
            children: [
              // Top spacer (asymmetric editorial breathing room)
              const Spacer(),

              // Centre identity block
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo card
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: SlideTransition(position: _logoSlide, child: const _LogoCard()),
                    ),

                    const SizedBox(height: 48),

                    // Brand name + ornament
                    FadeTransition(
                      opacity: _nameOpacity,
                      child: SlideTransition(
                        position: _nameSlide,
                        child: Column(
                          children: [
                            // "SpeakUp"
                            Text(
                              'SpeakUp',
                              style: GoogleFonts.newsreader(
                                fontSize: size.width >= 768 ? 60 : 48,
                                fontWeight: FontWeight.w700,
                                color: AppColorsNew.primary,
                                letterSpacing: -1.0,
                                height: 1,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // "Est. MMXXIV" ornament
                            FadeTransition(
                              opacity: _ornamentOpacity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _OrnamentLine(),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Est. MMXXIV',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColorsNew.secondary.withValues(alpha: 0.80),
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _OrnamentLine(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom tagline section
              Expanded(
                child: FadeTransition(opacity: _taglineOpacity, child: const _TaglineSection()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

// -----------------------------------------------------------------------------
// Grainy surface — replicates `.grainy-surface` CSS class
// -----------------------------------------------------------------------------
class _GrainySurface extends StatelessWidget {
  const _GrainySurface();

  @override
  Widget build(BuildContext context) {
    // A pure-Flutter grain using a CustomPainter so there's no network dependency.
    return CustomPaint(painter: _GrainPainter(), child: const SizedBox.expand());
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = AppColorsNew.onSurface.withValues(alpha: 0.012);
    for (int i = 0; i < 6000; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rng.nextDouble() * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Background blobs — top-left primary blob + bottom-right secondary blob
// -----------------------------------------------------------------------------
class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final blobSize = size.width * 0.5;

    return Stack(
      children: [
        // Top-left primary blob
        Positioned(
          top: -size.height * 0.10,
          left: -size.width * 0.05,
          child: _Blob(size: blobSize, color: AppColorsNew.primary.withValues(alpha: 0.05)),
        ),
        // Bottom-right secondary blob
        Positioned(
          bottom: -size.height * 0.10,
          right: -size.width * 0.05,
          child: _Blob(size: blobSize, color: AppColorsNew.secondary.withValues(alpha: 0.05)),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      // Simulate the CSS blur(120px)
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox.expand()),
    );
  }
}

// -----------------------------------------------------------------------------
// Logo card — white rounded card with the S-shaped soundwave SVG
// -----------------------------------------------------------------------------
class _LogoCard extends StatelessWidget {
  const _LogoCard();

  @override
  Widget build(BuildContext context) {
    final cardSize = MediaQuery.sizeOf(context).width >= 768 ? 144.0 : 112.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft glow behind
        Container(
          width: cardSize + 32,
          height: cardSize + 32,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColorsNew.primary.withValues(alpha: 0.05)),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: const SizedBox.expand()),
        ),

        // Card
        Container(
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: AppColorsNew.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColorsNew.ambientShadow,
          ),
          padding: const EdgeInsets.all(24),
          child: CustomPaint(painter: _SoundwaveLogoPainter()),
        ),
      ],
    );
  }
}

/// Paints the S-shaped soundwave SVG path from the HTML design.
class _SoundwaveLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scale helper: SVG viewBox is 0 0 100 100
    Offset s(double x, double y) => Offset(x / 100 * w, y / 100 * h);

    // ── Background curve (opacity 10%) ──────────────────────────────────
    final bgPaint = Paint()
      ..color = AppColorsNew.primary.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 / 100 * w
      ..strokeCap = StrokeCap.round;

    final bgPath = Path()
      ..moveTo(s(30, 20).dx, s(30, 20).dy)
      ..cubicTo(s(30, 20).dx, s(10, 10).dy, s(40, 10).dx, s(10, 10).dy, s(60, 10).dx, s(10, 10).dy)
      ..cubicTo(s(80, 10).dx, s(10, 10).dy, s(90, 25).dx, s(25, 25).dy, s(90, 40).dx, s(40, 40).dy)
      ..cubicTo(s(90, 55).dx, s(55, 55).dy, s(75, 60).dx, s(60, 60).dy, s(50, 60).dx, s(60, 60).dy)
      ..cubicTo(s(25, 60).dx, s(60, 60).dy, s(10, 65).dx, s(65, 65).dy, s(10, 80).dx, s(80, 80).dy)
      ..cubicTo(s(10, 95).dx, s(95, 95).dy, s(30, 95).dx, s(95, 95).dy, s(45, 95).dx, s(95, 95).dy)
      ..cubicTo(s(60, 95).dx, s(95, 95).dy, s(70, 85).dx, s(85, 85).dy, s(70, 85).dx, s(85, 85).dy);

    canvas.drawPath(bgPath, bgPaint);

    // ── Main S soundwave (gradient) ─────────────────────────────────────
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColorsNew.primary, AppColorsNew.primaryContainer],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 / 100 * w
      ..strokeCap = StrokeCap.round;

    final mainPath = Path()
      ..moveTo(s(25, 35).dx, s(25, 35).dy)
      ..cubicTo(s(25, 35).dx, s(25, 25).dy, s(30, 25).dx, s(25, 25).dy, s(50, 25).dx, s(25, 25).dy)
      ..cubicTo(s(70, 25).dx, s(25, 25).dy, s(75, 35).dx, s(35, 35).dy, s(75, 45).dx, s(45, 45).dy)
      ..cubicTo(s(75, 55).dx, s(55, 55).dy, s(65, 60).dx, s(60, 60).dy, s(50, 60).dx, s(60, 60).dy)
      ..cubicTo(s(35, 60).dx, s(60, 60).dy, s(25, 65).dx, s(65, 65).dy, s(25, 75).dx, s(75, 75).dy)
      ..cubicTo(s(25, 85).dx, s(85, 85).dy, s(30, 95).dx, s(95, 95).dy, s(50, 95).dx, s(95, 95).dy);

    canvas.drawPath(mainPath, gradPaint);

    // ── Card edge detail (small dark rect top-right) ─────────────────────
    final rectPaint = Paint()
      ..color = AppColorsNew.primary
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s(75, 10).dx, s(75, 10).dy, 8 / 100 * w, 30 / 100 * h), const Radius.circular(4)),
      rectPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Ornament line on either side of "Est. MMXXIV"
// -----------------------------------------------------------------------------
class _OrnamentLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 32, height: 0.5, color: AppColorsNew.secondary.withValues(alpha: 0.40));
  }
}

// -----------------------------------------------------------------------------
// Tagline + loading dots at the bottom
// -----------------------------------------------------------------------------
class _TaglineSection extends StatelessWidget {
  const _TaglineSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Tagline with horizontal gradient rule behind it
        Stack(
          alignment: Alignment.center,
          children: [
            // Atmospheric thin horizontal line
            Container(
              height: 1,
              width: 192,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, AppColorsNew.outlineVariant.withValues(alpha: 0.30), Colors.transparent]),
              ),
            ),

            // Tagline text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Practice. Speak. Flourish.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColorsNew.onSurfaceVariant.withValues(alpha: 0.80),
                  letterSpacing: 4.5,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // Loading indicator — three dots, third one more opaque
        const _LoadingDots(),

        const SizedBox(height: 64),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Three-dot loading indicator
// -----------------------------------------------------------------------------
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Cycle which dot is "active" (higher opacity)
        final active = (_ctrl.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: List.generate(3, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColorsNew.primary.withValues(alpha: i == active ? 0.60 : 0.20),
              ),
            );
          }),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Side editorial text — rotated -90°, shown only on large screens
// -----------------------------------------------------------------------------
class _SideEditorialText extends StatelessWidget {
  const _SideEditorialText();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotatedBox(
        quarterTurns: 3, // -90°
        child: Text(
          'The Art of Eloquence',
          style: GoogleFonts.newsreader(
            fontStyle: FontStyle.italic,
            fontSize: 14,
            color: AppColorsNew.onSurfaceVariant.withValues(alpha: 0.20),
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
