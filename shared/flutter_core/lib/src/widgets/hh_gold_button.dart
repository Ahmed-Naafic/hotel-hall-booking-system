import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// The gold call-to-action: a struck gold fill with a near-black navy label.
///
/// This is the treatment the approved login design uses, and it is what
/// [HHPrimaryButton] becomes in dark mode — there, navy *is* the page, so a
/// navy button is a shape you have to hunt for, and gold is the only brand
/// colour that carries. Used directly (rather than via [HHPrimaryButton])
/// only where the gold is wanted in *both* themes: the authentication
/// screens, which are the brand's front door.
///
/// Built on [ElevatedButton] rather than a bare [InkWell] so it keeps the
/// button semantics, focus handling and disabled behaviour Material already
/// provides; only the fill is taken over, since a gradient is not something
/// `ButtonStyle` can express.
class HHGoldButton extends StatelessWidget {
  const HHGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.height = HHSpacing.controlHLg,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Set to `null` for a label with no trailing mark.
  final IconData? trailingIcon;

  /// Matches [HHPrimaryButton]'s own height when standing in for it, so a
  /// screen's buttons do not change size between themes.
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.hh;
    final isEnabled = !isLoading && onPressed != null;
    // The design's label reads all but black against the gold, and navy950
    // is the deepest navy the brand owns.
    final foreground = isEnabled ? palette.onActionCta : palette.actionDisabledText;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        // The gradient below is the fill, so the button's own Material is
        // left clear rather than painting a flat colour underneath it.
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: foreground,
        disabledForegroundColor: palette.actionDisabledText,
        elevation: 0,
        padding: EdgeInsets.zero,
        minimumSize: Size.fromHeight(height),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isEnabled
                ? [palette.actionGoldGradientFrom, palette.actionGoldGradientTo]
                : [palette.actionDisabledBg, palette.actionDisabledBg],
          ),
          borderRadius: BorderRadius.circular(HHRadii.control),
        ),
        child: Container(
          height: height,
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: palette.actionDisabledText),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: HHTypography.textMd.copyWith(
                          color: foreground,
                          fontWeight: HHTypeScale.weightMedium,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: HHSpacing.space3),
                      Icon(trailingIcon, size: 18, color: foreground),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
