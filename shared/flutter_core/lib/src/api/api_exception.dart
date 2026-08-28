/// Mirrors the backend's `ErrorEnvelope` (api-standards.md §8,
/// `openapi.json#/components/schemas/ErrorEnvelope`) — every non-2xx
/// response. Never invents a message: `message` is always the server's own
/// text, the same "display the server's own message" pattern
/// `apps/admin-web` already uses.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.error,
    required this.message,
    this.details = const [],
  });

  final int statusCode;
  final String error;
  final String message;
  final List<ApiErrorDetail> details;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 400;
  bool get isConflict => statusCode == 409;
  bool get isBusinessRule => statusCode == 422;

  @override
  String toString() => 'ApiException($statusCode $error: $message)';
}

class ApiErrorDetail {
  const ApiErrorDetail({required this.field, required this.message});

  final String field;
  final String message;

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) =>
      ApiErrorDetail(field: json['field'] as String? ?? '', message: json['message'] as String? ?? '');
}

/// A request never reached the server at all (no connectivity, DNS
/// failure, timeout) — distinct from `ApiException`, which means the
/// server responded with an error.
class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException($message)';
}
