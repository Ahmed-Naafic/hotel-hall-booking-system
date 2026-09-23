import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// The Login screen's own hero panel — deep navy ground, the brand mark,
/// the wordmark, and a one-line tagline, closing with the same gold
/// rule-and-eyebrow device the logo itself uses ("BOOK • STAY •
/// CELEBRATE"). Shared verbatim between Customer and Hotel Manager Mobile
/// (only [tagline] differs per app); every colour is a token from the
/// existing gold/navy palette — no photography or a second accent colour
/// introduced for this screen alone.
class AuthHeroHeader extends StatelessWidget {
  const AuthHeroHeader({super.key, required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Vertical, not diagonal: sampling the approved design across
            // the panel shows the light sitting at the top centre and
            // falling straight down, the same height reading identically
            // left and right.
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Theme-aware so the panel always sits deeper than the card
            // that overlaps it — see HHPalette.surfaceHeroTop.
            colors: [context.hh.surfaceHeroTop, context.hh.surfaceHeroBottom],
          ),
        ),
        child: Stack(
          children: [
            // Two gold sweeps bleeding off the top corners — a broad band
            // with a fine line riding just inside it, the same pairing the
            // logo's archway uses. Both fade out at either end so they read
            // as light catching a curve rather than as drawn circles.
            Positioned(
              top: -150,
              left: -170,
              child: _GoldSweep(size: 330, from: -0.12, sweep: 0.62, width: 26, alpha: 0.30),
            ),
            Positioned(
              top: -120,
              left: -140,
              child: _GoldSweep(size: 300, from: -0.05, sweep: 0.46, width: 2.5, alpha: 0.65),
            ),
            Positioned(
              top: -170,
              right: -150,
              child: _GoldSweep(size: 340, from: 0.40, sweep: 0.60, width: 26, alpha: 0.30),
            ),
            Positioned(
              top: -140,
              right: -120,
              child: _GoldSweep(size: 300, from: 0.48, sweep: 0.46, width: 2.5, alpha: 0.65),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  HHSpacing.space7,
                  HHSpacing.space9,
                  HHSpacing.space7,
                  HHSpacing.space9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The navy-ground cut of the mark: transparent, with the
                    // artwork's navy relit. `logo_mark.png` is drawn for a
                    // white page — on this panel its white field renders as
                    // a box, and its navy sits at 1.3:1 against the panel,
                    // which is the buildings disappearing entirely. This cut
                    // keeps the gold and teal untouched and carries the same
                    // shading, but at 10.5:1. The original is kept beside it
                    // for anywhere the mark is placed on white.
                    Image.asset(
                      'packages/hotel_hall_core/assets/branding/logo_mark_on_navy.png',
                      height: 84,
                    ),
                    const SizedBox(height: HHSpacing.space4),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: HHTypography.displayMd.copyWith(color: HHColors.white),
                        children: [
                          const TextSpan(text: 'Hotel '),
                          TextSpan(text: 'Hall', style: TextStyle(color: HHColors.gold400)),
                        ],
                      ),
                    ),
                    const SizedBox(height: HHSpacing.space3),
                    Text(
                      tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: HHTypeScale.textMd, color: HHColors.textOnNavy),
                    ),
                    const SizedBox(height: HHSpacing.space5),
                    Row(
                      children: [
                        Expanded(child: Divider(color: HHColors.gold500, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space3),
                          child: Transform.rotate(
                            angle: 0.785398, // 45°, a diamond from a square.
                            child: Container(width: 6, height: 6, color: HHColors.gold500),
                          ),
                        ),
                        Expanded(child: Divider(color: HHColors.gold500, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: HHSpacing.space3),
                    Text(
                      'BOOK • STAY • CELEBRATE',
                      textAlign: TextAlign.center,
                      style: HHTypography.eyebrow.copyWith(color: HHColors.gold400),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// One tapered gold arc. [from] and [sweep] are turns (1.0 = full circle),
/// measured clockwise from three o'clock, so a corner sweep is readable as
/// a fraction rather than as raw radians.
class _GoldSweep extends StatelessWidget {
  const _GoldSweep({
    required this.size,
    required this.from,
    required this.sweep,
    required this.width,
    required this.alpha,
  });

  final double size;
  final double from;
  final double sweep;
  final double width;
  final double alpha;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _GoldSweepPainter(
        from: from * 2 * math.pi,
        sweep: sweep * 2 * math.pi,
        width: width,
        alpha: alpha,
      ),
    ),
  );
}

class _GoldSweepPainter extends CustomPainter {
  const _GoldSweepPainter({
    required this.from,
    required this.sweep,
    required this.width,
    required this.alpha,
  });

  final double from;
  final double sweep;
  final double width;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    // A sweep gradient running transparent → gold → transparent across
    // exactly the drawn span is what tapers the ends; a plain stroke would
    // stop dead and give away the circle it came from.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        // Angles match `drawArc` below exactly — both are measured clockwise
        // from three o'clock — so the fade lines up with the drawn span.
        // The ends are already transparent, so clamping past them is a no-op.
        startAngle: from,
        endAngle: from + sweep,
        colors: [
          HHColors.gold500.withValues(alpha: 0),
          HHColors.gold400.withValues(alpha: alpha),
          HHColors.gold500.withValues(alpha: 0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(bounds);

    canvas.drawArc(bounds.deflate(width / 2), from, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_GoldSweepPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.sweep != sweep ||
      oldDelegate.width != width ||
      oldDelegate.alpha != alpha;
}
