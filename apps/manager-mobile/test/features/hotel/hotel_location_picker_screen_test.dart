import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/hotel_location_picker_screen.dart';
import 'package:latlong2/latlong.dart';

void main() {
  Future<void> placePin(WidgetTester tester) async {
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    map.options.onTap!(
      const TapPosition(Offset.zero, Offset.zero),
      const LatLng(-1.286389, 36.817223),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'pin placement captures coordinates and displays detected address',
    (tester) async {
      double? latitude;
      double? longitude;
      await tester.pumpWidget(
        MaterialApp(
          home: HotelLocationPickerScreen(
            showMapTiles: false,
            reverseGeocode: (lat, lon) async {
              latitude = lat;
              longitude = lon;
              return 'Nairobi CBD, Kenya';
            },
          ),
        ),
      );

      await placePin(tester);

      expect(latitude, isNotNull);
      expect(longitude, isNotNull);
      expect(find.text('Nairobi CBD, Kenya'), findsOneWidget);
      expect(find.byIcon(Icons.location_pin), findsOneWidget);
    },
  );

  testWidgets('manager can edit detected address before confirming', (
    tester,
  ) async {
    HotelLocationResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async => result = await Navigator.of(context)
                  .push<HotelLocationResult>(
                    MaterialPageRoute(
                      builder: (_) => HotelLocationPickerScreen(
                        showMapTiles: false,
                        reverseGeocode: (_, __) async => 'Detected address',
                      ),
                    ),
                  ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await placePin(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Detected address'),
      'Manager corrected address',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm location'));
    await tester.pumpAndSettle();

    expect(result?.address, 'Manager corrected address');
    expect(result?.latitude, isNotNull);
    expect(result?.longitude, isNotNull);
  });

  testWidgets(
    'reverse-geocoding failure keeps pin and requires manual address',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HotelLocationPickerScreen(
            showMapTiles: false,
            reverseGeocode: (_, __) async => null,
          ),
        ),
      );
      await placePin(tester);

      expect(
        find.text("We couldn't automatically detect the address."),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'Address *'), findsOneWidget);
      expect(find.byIcon(Icons.location_pin), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm location'));
      await tester.pump();
      expect(find.text('Address is required.'), findsOneWidget);
    },
  );

  testWidgets(
    'manual address fallback can be confirmed after geocoding failure',
    (tester) async {
      HotelLocationResult? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async => result = await Navigator.of(context)
                    .push<HotelLocationResult>(
                      MaterialPageRoute(
                        builder: (_) => HotelLocationPickerScreen(
                          showMapTiles: false,
                          reverseGeocode: (_, __) async => null,
                        ),
                      ),
                    ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await placePin(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *'),
        'Westlands, Nairobi',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm location'));
      await tester.pumpAndSettle();

      expect(result?.address, 'Westlands, Nairobi');
      expect(result?.latitude, isNotNull);
      expect(result?.longitude, isNotNull);
    },
  );
}
