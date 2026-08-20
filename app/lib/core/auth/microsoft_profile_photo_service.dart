import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'msal_service.dart';

typedef MicrosoftGraphSessionProvider =
    Future<MicrosoftGraphSession?> Function();

/// Fetches Microsoft 365 profile photos directly from Microsoft Graph.
///
/// Access tokens and image bytes are kept in memory only. Every failure is a
/// normal `null` result so account screens can continue to render initials.
class MicrosoftProfilePhotoService {
  MicrosoftProfilePhotoService({
    required MicrosoftGraphSessionProvider acquireSession,
    Dio? dio,
  }) : _acquireSession = acquireSession,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: 'https://graph.microsoft.com/v1.0',
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
             ),
           );

  final MicrosoftGraphSessionProvider _acquireSession;
  final Dio _dio;
  final Map<String, Future<Uint8List?>> _photoCache = {};

  MicrosoftGraphSession? _session;
  Future<MicrosoftGraphSession?>? _sessionRequest;

  Future<Uint8List?> currentUserPhoto({int size = 96}) {
    return _photoCache.putIfAbsent(
      'me:$size',
      () async {
        final direct = await _loadPhoto('/me/photo/\$value');
        if (direct != null) return direct;
        return _loadPhoto('/me/photos/${size}x$size/\$value');
      },
    );
  }

  Future<Uint8List?> userPhoto(String emailOrUpn, {int size = 48}) {
    final identity = emailOrUpn.trim();
    if (identity.isEmpty) return Future.value(null);
    final cacheKey = 'user:${identity.toLowerCase()}:$size';
    return _photoCache.putIfAbsent(
      cacheKey,
      () => _loadUserPhoto(identity, size),
    );
  }

  void clear() {
    _photoCache.clear();
    _session = null;
    _sessionRequest = null;
  }

  Future<MicrosoftGraphSession?> _getSession() async {
    final current = _session;
    final refreshBoundary = DateTime.now().add(const Duration(minutes: 1));
    if (current != null && current.expiresOn.isAfter(refreshBoundary)) {
      return current;
    }

    final pending = _sessionRequest;
    if (pending != null) return pending;

    final request = _acquireSession();
    _sessionRequest = request;
    try {
      final result = await request;
      _session = result;
      return result;
    } finally {
      _sessionRequest = null;
    }
  }

  Future<Uint8List?> _loadUserPhoto(String identity, int size) async {
    final encodedIdentity = Uri.encodeComponent(identity);
    var direct = await _loadPhotoResponse(
      '/users/$encodedIdentity/photo/\$value',
    );
    if (direct.bytes != null) return direct.bytes;

    if (direct.statusCode == 404) {
      direct = await _loadPhotoResponse(
        '/users/$encodedIdentity/photos/${size}x$size/\$value',
      );
      if (direct.bytes != null) return direct.bytes;
    }
    if (direct.statusCode != 404) return null;

    // The app stores the best email-like claim from the Microsoft token. In
    // most tenants this is the UPN; if it is only the `mail` value, resolve the
    // Graph user id first and retry by id.
    final escaped = identity.replaceAll("'", "''");
    final lookup = await _getJson(
      '/users',
      queryParameters: {
        '\$filter': "mail eq '$escaped' or userPrincipalName eq '$escaped'",
        '\$select': 'id',
        '\$top': 1,
      },
    );
    final values = lookup?['value'];
    if (values is! List || values.isEmpty || values.first is! Map) return null;
    final id = (values.first as Map)['id'];
    if (id is! String || id.isEmpty) return null;
    final encodedId = Uri.encodeComponent(id);
    final byId = await _loadPhotoResponse(
      '/users/$encodedId/photo/\$value',
    );
    if (byId.bytes != null) return byId.bytes;
    return (await _loadPhotoResponse('/users/$encodedId/photos/${size}x$size/\$value')).bytes;
  }

  Future<Uint8List?> _loadPhoto(String path) async {
    return (await _loadPhotoResponse(path)).bytes;
  }

  Future<({Uint8List? bytes, int? statusCode})> _loadPhotoResponse(
    String path,
  ) async {
    final session = await _getSession();
    if (session == null) return (bytes: null, statusCode: null);

    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Accept': 'image/*',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null && data.isNotEmpty) {
        return (
          bytes: data is Uint8List ? data : Uint8List.fromList(data),
          statusCode: response.statusCode,
        );
      }
      return (bytes: null, statusCode: response.statusCode);
    } catch (_) {
      return (bytes: null, statusCode: null);
    }
  }

  Future<Map<String, dynamic>?> _getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final session = await _getSession();
    if (session == null) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Accept': 'application/json',
            'ConsistencyLevel': 'eventual',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200 ? response.data : null;
    } catch (_) {
      return null;
    }
  }
}
