import 'package:flutter/material.dart';

import '../../data/hotel_models.dart';

class HotelPhotoViewerScreen extends StatefulWidget {
  const HotelPhotoViewerScreen({super.key, required this.photos, required this.initialIndex});

  final List<HotelMedia> photos;
  final int initialIndex;

  @override
  State<HotelPhotoViewerScreen> createState() => _HotelPhotoViewerScreenState();
}

class _HotelPhotoViewerScreenState extends State<HotelPhotoViewerScreen> {
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
