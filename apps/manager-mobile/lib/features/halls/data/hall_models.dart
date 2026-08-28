/// Mirrors `openapi.json#/components/schemas/PublicHall` exactly. No
/// `status`/`visibility` field exists on this resource — Hall Management
/// Technical Design §6/§12 deliberately never returns one; visibility is a
/// request-time outcome, not Hall data. This app does not invent one.
class Hall {
  const Hall({
    required this.id,
    required this.hotelId,
    required this.profileData,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String hotelId;
  final Map<String, dynamic>? profileData;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Hall.fromJson(Map<String, dynamic> json) => Hall(
        id: json['id'] as String,
        hotelId: json['hotelId'] as String,
        profileData: (json['profileData'] as Map?)?.cast<String, dynamic>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// `BDR-016` (Approved) defines `name` as a required standard field, so
  /// this now reads it directly rather than guessing from the first
  /// `profileData` entry. Still falls back gracefully for any Hall created
  /// before that decision (development/test fixtures only — the backend
  /// has required `name` at creation ever since).
  String get displayTitle {
    final data = profileData;
    if (data == null || data.isEmpty) return 'Untitled Hall';
    final name = data['name'];
    if (name != null && name.toString().trim().isNotEmpty) return name.toString();
    return data.entries.first.value?.toString() ?? 'Untitled Hall';
  }

  /// Capacity is stored as a JSON number or numeric string (backend accepts
  /// either, `BDR-016`) — normalized here for display.
  int? get capacity {
    final value = profileData?['capacity'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

class HallPage {
  const HallPage({required this.halls, required this.page, required this.limit, required this.total, required this.hasNext, required this.hasPrevious});

  final List<Hall> halls;
  final int page;
  final int limit;
  final int total;
  final bool hasNext;
  final bool hasPrevious;
}
