import 'package:flutter/foundation.dart';
import 'package:msal_auth/msal_auth.dart';

class MsalService {
  static const String _clientId = 'a9bb1ec3-db6c-4192-96c6-de69296cfe66';
  static const String _tenantId = '78c58f88-8385-43c2-b475-a57dcfbbc09f';
  static const List<String> _scopes = ['User.Read'];
  static const String _androidDebugRedirectUri =
      'msauth://company.thecloud.pantry/515a9IhVXCyy57IZeaswJmLBBUA%3D';
  static const String _androidReleaseRedirectUri =
      'msauth://company.thecloud.pantry/s46h%2BmgBrqVfAnFDUVD8ERZKOVw%3D';

  late SingleAccountPca _pca;

  Future<void> initialize() async {
    final androidRedirectUri =
        kReleaseMode ? _androidReleaseRedirectUri : _androidDebugRedirectUri;

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

  Future<void> signOut() async {
    try {
      await _pca.signOut();
    } catch (_) {
      // Ignore sign-out errors
    }
  }
}
