import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_mobile/features/halls/data/hall_models.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_photo_viewer_screen.dart';

List<HallMedia> _photos() => [
      const HallMedia(id: 'p1', hallId: 'hall-1', url: 'https://example.com/1.jpg'),
      const HallMedia(id: 'p2', hallId: 'hall-1', url: 'https://example.com/2.jpg'),
      const HallMedia(id: 'p3', hallId: 'hall-1', url: 'https://example.com/3.jpg'),
    ];

void main() {
  testWidgets('opens on the tapped photo, shown in the "N / total" counter', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HallPhotoViewerScreen(photos: _photos(), initialIndex: 1),
    ));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('swiping to the next photo updates the counter', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HallPhotoViewerScreen(photos: _photos(), initialIndex: 0),
    ));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('a single photo shows "Photo" instead of a "1 / 1" counter', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HallPhotoViewerScreen(photos: [_photos().first], initialIndex: 0),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Photo'), findsOneWidget);
  });

  testWidgets('each page supports pinch-to-zoom via InteractiveViewer', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HallPhotoViewerScreen(photos: _photos(), initialIndex: 0),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsWidgets);
  });
}
