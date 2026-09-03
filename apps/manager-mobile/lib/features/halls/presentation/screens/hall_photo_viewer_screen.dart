import 'package:flutter/material.dart';

import '../../data/hall_models.dart';

/// Full-screen, pinch-to-zoom viewer for a Hall's photos (`InteractiveViewer`
/// is part of the Flutter SDK — no new dependency). Reached by tapping any
/// thumbnail in `HallDetailsScreen`'s photo strip; opens on the tapped
/// photo, swipe left/right to move between the rest.
class HallPhotoViewerScreen extends StatefulWidget {
  const HallPhotoViewerScreen({super.key, required this.photos, required this.initialIndex});

  final List<HallMedia> photos;
  final int initialIndex;

  @override
  State<HallPhotoViewerScreen> createState() => _HallPhotoViewerScreenState();
}

class _HallPhotoViewerScreenState extends State<HallPhotoViewerScreen> {
  late final PageController _pageController = PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.photos.length > 1 ? '${_currentIndex + 1} / ${widget.photos.length}' : 'Photo',
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(
              widget.photos[index].url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
