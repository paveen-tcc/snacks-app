import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/core/auth/microsoft_profile_photo_service.dart';
import 'package:snacks_app/core/auth/msal_service.dart';
import 'package:snacks_app/core/design/app_theme.dart';
import 'package:snacks_app/core/widgets/microsoft_avatar.dart';

class _AvatarAdapter implements HttpClientAdapter {
  _AvatarAdapter(this.bytes, this.statusCode);

  final List<int> bytes;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromBytes(
    bytes,
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['image/png'],
    },
  );

  @override
  void close({bool force = false}) {}
}

MicrosoftProfilePhotoService _service(List<int> bytes, int statusCode) {
  final dio = Dio(BaseOptions(baseUrl: 'https://graph.microsoft.com/v1.0'));
  dio.httpClientAdapter = _AvatarAdapter(bytes, statusCode);
  return MicrosoftProfilePhotoService(
    acquireSession: () async => MicrosoftGraphSession(
      accessToken: 'token',
      accountId: 'account',
      expiresOn: DateTime.now().add(const Duration(hours: 1)),
    ),
    dio: dio,
  );
}

Widget _host(MicrosoftProfilePhotoService service) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: MicrosoftAvatar(
      displayName: 'Alice',
      currentUser: true,
      photoService: service,
    ),
  ),
);

void main() {
  testWidgets('renders initials when Microsoft has no photo', (tester) async {
    await tester.pumpWidget(_host(_service(const [], 404)));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isNull);
  });

  testWidgets('renders Microsoft photo bytes when available', (tester) async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(_host(_service(png, 200)));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsNothing);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isA<MemoryImage>());
  });
}
