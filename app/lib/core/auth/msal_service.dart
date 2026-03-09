import 'package:msal_auth/msal_auth.dart';

class MsalService {
  static const String _clientId = 'a9bb1ec3-db6c-4192-96c6-de69296cfe66';
  static const String _tenantId = '78c58f88-8385-43c2-b475-a57dcfbbc09f';
  static const List<String> _scopes = ['User.Read'];

  late SingleAccountPca _pca;

  Future<void> initialize() async {
    _pca = await SingleAccountPca.create(
      clientId: _clientId,
      androidConfig: AndroidConfig(
        configFilePath: 'assets/msal_config.json',
        redirectUri:
            'msauth://com.company.snacks_app/YOUR_SIGNATURE_HASH',
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
      // Fall back to access token if ID token not available
      return result.accessToken;
    }
    return idToken;
  }

  Future<void> signOut() async {
    try {
      await _pca.signOut();
    } catch (_) {
      // Ignore sign-out errors
    }
  }
}
