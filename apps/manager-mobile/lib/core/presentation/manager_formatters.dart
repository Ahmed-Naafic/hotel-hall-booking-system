/// Pure, presentation-only text formatting — never a source of truth.
/// `status()` and `label()` only reformat casing/spacing of a value the
/// backend/manager already supplied verbatim (e.g. `APPROVED_ACTIVE` ->
/// `Approved Active`, `amenities` -> `Amenities`); neither invents,
/// re-derives, or judges the underlying value.
abstract final class ManagerFormatters {
  static String status(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');

  static String date(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String label(String key) {
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
    return spaced.isEmpty
        ? key
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  static String? text(Map<String, dynamic>? data, String key) {
    final value = data?[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}
