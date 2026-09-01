import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// A rounded network image with a consistent, token-styled fallback when
/// [url] is null or fails to load — consolidates the identical
/// `Image.network(...errorBuilder: ...)` pattern previously duplicated for
/// every Hotel Logo/Photo and Hall Photo thumbnail.
class HHNetworkImage extends StatelessWidget {
  const HHNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = HHRadii.image,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double? width;
  final double? height;
  final double borderRadius;
  final IconData fallbackIcon;
  final BoxFit fit;

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: HHColors.surfaceSunken,
    child: Icon(fallbackIcon, color: HHColors.textSubtle),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url == null || url!.isEmpty
          ? _placeholder()
          : Image.network(
              url!,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }
}
