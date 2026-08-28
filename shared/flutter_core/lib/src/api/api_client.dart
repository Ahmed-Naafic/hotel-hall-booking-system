import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// Generic HTTP client for the Platform's REST API (api-standards.md §3–§9).
/// Parses `SuccessEnvelope`/`ErrorEnvelope` (§7–§8) exactly as the backend
/// produces them — the same envelope every module's endpoints already use;
/// no module-specific parsing exists here. `httpClient` is injectable so
/// tests never make a real network call (`package:http/testing.dart`'s
/// `MockClient`).
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl, this.accessTokenProvider})
      : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _httpClient;
  final String baseUrl;

  /// Supplies the current access token, if any (Bearer, api-standards.md
  /// §12). Returning `null` sends the request unauthenticated — the caller
  /// (`AuthRepository`) decides whether that's valid for a given endpoint.
  final Future<String?> Function()? accessTokenProvider;

  Future<dynamic> get(String path, {Map<String, String>? query}) async =>
      (await _send('GET', path, query: query)).data;

  Future<dynamic> post(String path, {Object? body}) async => (await _send('POST', path, body: body)).data;

  Future<dynamic> patch(String path, {Object? body}) async => (await _send('PATCH', path, body: body)).data;

  Future<dynamic> delete(String path) async => (await _send('DELETE', path)).data;

  /// For list endpoints whose envelope carries `pagination` as a sibling of
  /// `data` (api-standards.md §10 — e.g. `GET /hotels`, `GET
  /// /hotels/:hotelId/halls`, `GET /halls`) — `get()` alone would discard
  /// it, since most callers only need `data`.
  Future<({dynamic data, Map<String, dynamic>? pagination})> getPaginated(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  /// `multipart/form-data` upload (api-standards.md §15 — file upload
  /// transport standard) — used only by endpoints that accept a file, e.g.
  /// Hotel Media (`POST /hotels/:hotelId/media/logo`/`photos`). Sends the
  /// raw bytes the caller already has (e.g. from an image picker); this
  /// class never touches the filesystem or a platform picker itself.
  Future<dynamic> postMultipart(
    String path, {
    required List<int> bytes,
    required String filename,
    String field = 'file',
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _authHeaders())
      ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));

    http.Response response;
    try {
      final streamed = await _httpClient.send(request);
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw const NetworkException('Could not reach the server. Check your connection and try again.');
    } on HttpException {
      throw const NetworkException('Could not reach the server. Check your connection and try again.');
    }

    return _parse(response).data;
  }

  /// Bearer token only — no `Content-Type`, so the caller (a JSON request
  /// via `_headers()`, or a multipart request via `postMultipart`) sets
  /// its own.
  Future<Map<String, String>> _authHeaders() async {
    final headers = <String, String>{};
    final token = await accessTokenProvider?.call();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, String>> _headers() async => {'Content-Type': 'application/json', ...await _authHeaders()};

  Future<({dynamic data, Map<String, dynamic>? pagination})> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.isNotEmpty == true ? query : null,
    );
    final headers = await _headers();

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers);
        case 'POST':
          response = await _httpClient.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'PATCH':
          response = await _httpClient.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers);
        default:
          throw ArgumentError('Unsupported method: $method');
      }
    } on SocketException {
      throw const NetworkException('Could not reach the server. Check your connection and try again.');
    } on HttpException {
      throw const NetworkException('Could not reach the server. Check your connection and try again.');
    }

    return _parse(response);
  }

  ({dynamic data, Map<String, dynamic>? pagination}) _parse(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (data: null, pagination: null);
      }
      throw ApiException(statusCode: response.statusCode, error: 'UNKNOWN_ERROR', message: 'Something went wrong. Please try again.');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(statusCode: response.statusCode, error: 'UNKNOWN_ERROR', message: 'Something went wrong. Please try again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data: json['data'], pagination: (json['pagination'] as Map?)?.cast<String, dynamic>());
    }

    final detailsJson = json['details'] as List<dynamic>? ?? const [];
    throw ApiException(
      statusCode: response.statusCode,
      error: json['error'] as String? ?? 'UNKNOWN_ERROR',
      message: json['message'] as String? ?? 'Something went wrong. Please try again.',
      details: detailsJson.map((d) => ApiErrorDetail.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}
