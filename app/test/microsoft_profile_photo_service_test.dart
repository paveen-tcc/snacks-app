import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/core/auth/microsoft_profile_photo_service.dart';
import 'package:snacks_app/core/auth/msal_service.dart';

class _GraphAdapter implements HttpClientAdapter {
  _GraphAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

MicrosoftGraphSession _session() => MicrosoftGraphSession(
  accessToken: 'graph-token',
  accountId: 'account-id',
  expiresOn: DateTime.now().add(const Duration(hours: 1)),
  username: 'person@example.com',
);

Dio _dio(_GraphAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://graph.microsoft.com/v1.0'));
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  test('returns and caches the signed-in user photo bytes', () async {
    final adapter = _GraphAdapter(
      (_) => ResponseBody.fromBytes(
        [1, 2, 3],
        200,
        headers: {
          Headers.contentTypeHeader: ['image/jpeg'],
        },
      ),
    );
    final service = MicrosoftProfilePhotoService(
      acquireSession: () async => _session(),
      dio: _dio(adapter),
    );

    expect(await service.currentUserPhoto(), Uint8List.fromList([1, 2, 3]));
    expect(await service.currentUserPhoto(), Uint8List.fromList([1, 2, 3]));
    expect(adapter.requestCount, 1);
  });

  test(
    'resolves a mail address to a Graph id when it is not the UPN',
    () async {
      final adapter = _GraphAdapter((options) {
        if (options.path == '/users') {
          return ResponseBody.fromString(
            jsonEncode({
              'value': [
                {'id': 'graph-user-id'},
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        if (options.path.contains('graph-user-id')) {
          return ResponseBody.fromBytes(
            [9, 8, 7],
            200,
            headers: {
              Headers.contentTypeHeader: ['image/jpeg'],
            },
          );
        }
        return ResponseBody.fromBytes(const [], 404);
      });
      final service = MicrosoftProfilePhotoService(
        acquireSession: () async => _session(),
        dio: _dio(adapter),
      );

      expect(
        await service.userPhoto('mail@example.com'),
        Uint8List.fromList([9, 8, 7]),
      );
      expect(adapter.requestCount, 4);
    },
  );

  test(
    'permission failures fall back to null and clear allows a retry',
    () async {
      final adapter = _GraphAdapter(
        (_) => ResponseBody.fromBytes(const [], 403),
      );
      final service = MicrosoftProfilePhotoService(
        acquireSession: () async => _session(),
        dio: _dio(adapter),
      );

      expect(await service.userPhoto('person@example.com'), isNull);
      expect(await service.userPhoto('person@example.com'), isNull);
      expect(adapter.requestCount, 1);

      service.clear();
      expect(await service.userPhoto('person@example.com'), isNull);
      expect(adapter.requestCount, 2);
    },
  );
}
