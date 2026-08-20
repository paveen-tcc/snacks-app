import 'package:flutter/foundation.dart';
import 'package:msal_auth/msal_auth.dart';

class MicrosoftGraphSession {
  const MicrosoftGraphSession({
    required this.accessToken,
    required this.accountId,
    required this.expiresOn,
    this.username,
  });

  final String accessToken;
  final String accountId;
  final DateTime expiresOn;
  final String? username;
}

class MsalService {
  static const String _clientId = 'a9bb1ec3-db6c-4192-96c6-de69296cfe66';
  static const String _tenantId = '78c58f88-8385-43c2-b475-a57dcfbbc09f';
  static const List<String> _scopes = ['User.Read', 'User.ReadBasic.All'];
  static const String _androidDebugRedirectUri =
      'msauth://company.thecloud.pantry/515a9IhVXCyy57IZeaswJmLBBUA%3D';
  static const String _androidReleaseRedirectUri =
      'msauth://company.thecloud.pantry/nrvBMaqisWak4u1Jp%2Bp7aT5dDhE%3D';

  late SingleAccountPca _pca;

  Future<void> initialize() async {
    final androidRedirectUri = kReleaseMode
        ? _androidReleaseRedirectUri
        : _androidDebugRedirectUri;

    _pca = await SingleAccountPca.create(
      clientId: _clientId,
      androidConfig: AndroidConfig(
        configFilePath: 'assets/msal_config.json',
        redirectUri: androidRedirectUri,
      ),
      appleConfig: AppleConfig(
        authorityType: AuthorityType.aad,
        authority: 'https://login.microsoftonline.com/$_tenantId',
        broker: Broker.webView,
      ),
    );
  }

  /// Signs in the user via Microsoft and returns the ID token.
  Future<String> signIn() async {
    final result = await _pca.acquireToken(scopes: _scopes);
    final idToken = result.idToken;
    if (idToken == null || idToken.isEmpty) {
      return result.accessToken;
    }
    return idToken;
  }

  /// Attempts to silently acquire a token using cached credentials.
  /// Returns the ID token, or null if silent acquisition fails.
  Future<String?> acquireTokenSilent() async {
    try {
      final result = await _pca.acquireTokenSilent(scopes: _scopes);
      final idToken = result.idToken;
      if (idToken == null || idToken.isEmpty) {
        return result.accessToken;
      }
      return idToken;
    } catch (_) {
      return null;
    }
  }

  /// Returns a short-lived Graph token without interrupting the current UI.
  /// A missing consent or expired Microsoft session is treated as unavailable;
  /// callers should keep their initials-based fallback visible.
  Future<MicrosoftGraphSession?> acquireGraphSessionSilent() async {
    for (final scopes in const [
      _scopes,
      ['User.Read'],
    ]) {
      try {
        final result = await _pca.acquireTokenSilent(scopes: scopes);
        return MicrosoftGraphSession(
          accessToken: result.accessToken,
          accountId: result.account.id,
          expiresOn: result.expiresOn,
          username: result.account.username,
        );
      } catch (_) {
        // Existing sessions may not have consented to directory photos yet;
        // User.Read still allows the Profile screen to load /me/photo.
      }
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _pca.signOut();
    } catch (_) {
      // Ignore sign-out errors
    }
  }
}
