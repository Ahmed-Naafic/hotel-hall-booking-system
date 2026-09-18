import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:latlong2/latlong.dart';

typedef ReverseGeocodeFn =
    Future<String?> Function(double latitude, double longitude);

class HotelLocationResult {
  const HotelLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };
}

class HotelLocationPickerScreen extends StatefulWidget {
  const HotelLocationPickerScreen({
    super.key,
    required this.reverseGeocode,
    this.initialLocation,
    this.showMapTiles = true,
  });

  final ReverseGeocodeFn reverseGeocode;
  final HotelLocationResult? initialLocation;
  final bool showMapTiles;

  @override
  State<HotelLocationPickerScreen> createState() =>
      _HotelLocationPickerScreenState();
}

class _HotelLocationPickerScreenState extends State<HotelLocationPickerScreen> {
  static const _defaultCenter = LatLng(-1.286389, 36.817223);
  static const _pinZoom = 16.0;
  final _addressController = TextEditingController();
  final _mapController = MapController();
  LatLng? _pin;
  bool _isDetecting = false;
  bool _detectionFailed = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    if (initial != null) {
      _pin = LatLng(initial.latitude, initial.longitude);
      _addressController.text = initial.address;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placePin(LatLng point) async {
    setState(() {
      _pin = point;
      _isDetecting = true;
      _detectionFailed = false;
      _addressController.clear();
    });
    _mapController.move(point, _pinZoom);
    // Reverse geocoding must never leave the Manager stuck: any failure —
    // not just a provider-returned unavailable result — falls through to
    // the same manual-address path (ADR-0008's non-blocking guarantee).
    String? address;
    try {
      address = await widget.reverseGeocode(point.latitude, point.longitude);
    } catch (_) {
      address = null;
    }
    if (!mounted || _pin != point) return;
    setState(() {
      _isDetecting = false;
      _detectionFailed = address == null || address.trim().isEmpty;
      if (!_detectionFailed) _addressController.text = address!.trim();
    });
  }

  void _confirm() {
    final pin = _pin;
    final address = _addressController.text.trim();
    if (pin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place a pin on the map first.')),
      );
      return;
    }
    if (address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Address is required.')));
      return;
    }
    Navigator.of(context).pop(
      HotelLocationResult(
        latitude: pin.latitude,
        longitude: pin.longitude,
        address: address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _pin ?? _defaultCenter;
    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(title: const Text('Hotel location')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _pin == null ? 6 : _pinZoom,
                  onTap: (_, point) => _placePin(point),
                ),
                children: [
                  if (widget.showMapTiles)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hotelhall.manager',
                    ),
                  if (_pin != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pin!,
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.location_pin,
                            size: 48,
                            color: context.hh.actionPrimary,
                          ),
                        ),
                      ],
                    ),
                  RichAttributionWidget(
                    attributions: const [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(HHSpacing.space6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        color: context.hh.actionPrimary,
                      ),
                      const SizedBox(width: HHSpacing.space3),
                      Expanded(
                        child: Text(
                          _pin == null
                              ? 'Tap the map to place the pin'
                              : 'Pin placed. Tap elsewhere to move it.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HHSpacing.space4),
                  if (_isDetecting) const LinearProgressIndicator(),
                  if (_detectionFailed) ...[
                    Text(
                      "We couldn't automatically detect the address.",
                      style: TextStyle(color: context.hh.warning700),
                    ),
                    const SizedBox(height: HHSpacing.space3),
                  ],
                  HHTextField(
                    label: _detectionFailed ? 'Address *' : 'Detected address',
                    controller: _addressController,
                    enabled: !_isDetecting,
                    maxLines: 2,
                  ),
                  const SizedBox(height: HHSpacing.space5),
                  HHPrimaryButton(
                    label: 'Confirm location',
                    isLoading: _isDetecting,
                    onPressed: _isDetecting ? null : _confirm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
