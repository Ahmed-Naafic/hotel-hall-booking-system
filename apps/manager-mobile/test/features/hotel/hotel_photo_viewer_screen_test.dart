import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_mobile/features/hotel/data/hotel_models.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/hotel_photo_viewer_screen.dart';

List<HotelMedia> _photos() => [
      HotelMedia(id: 'p1', hotelId: 'h1', type: 'PHOTO', url: 'https://example.com/1.jpg', createdAt: DateTime(2026, 8, 26), updatedAt: DateTime(2026, 8, 26)),
      HotelMedia(id: 'p2', hotelId: 'h1', type: 'PHOTO', url: 'https://example.com/2.jpg', createdAt: DateTime(2026, 8, 26), updatedAt: DateTime(2026, 8, 26)),
      HotelMedia(id: 'p3', hotelId: 'h1', type: 'PHOTO', url: 'https://example.com/3.jpg', createdAt: DateTime(2026, 8, 26), updatedAt: DateTime(2026, 8, 26)),
    ];

void main() {
  testWidgets('opens on the tapped photo, shown in the "N / total" counter', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HotelPhotoViewerScreen(photos: _photos(), initialIndex: 1),
    ));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('swiping to the next photo updates the counter', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HotelPhotoViewerScreen(photos: _photos(), initialIndex: 0),
    ));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('a single photo shows "Photo" instead of a "1 / 1" counter', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HotelPhotoViewerScreen(photos: [_photos().first], initialIndex: 0),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Photo'), findsOneWidget);
  });

  testWidgets('each page supports pinch-to-zoom via InteractiveViewer', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HotelPhotoViewerScreen(photos: _photos(), initialIndex: 0),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsWidgets);
  });
}
