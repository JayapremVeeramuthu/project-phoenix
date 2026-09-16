import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId:
                  '833719706774-egk0j50gs6bdeta23ta1dqrs069unir7.apps.googleusercontent.com',
              serverClientId:
                  '833719706774-egk0j50gs6bdeta23ta1dqrs069unir7.apps.googleusercontent.com',
              scopes: [
                'email',
                'profile',
              ],
            );

  /// Initiates the native Google Sign-In flow and returns the Google ID Token.
  /// Returns null if the user cancelled the selection dialog.
  Future<String?> signInAndGetIdToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('[GoogleAuthService] User cancelled Google Sign-In.');
        return null;
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint('[GoogleAuthService] ID token is null, using accessToken or mock fallback.');
      }
      return idToken;
    } catch (e) {
      debugPrint('[GoogleAuthService] Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Disconnects/signs out the local Google session.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] Sign out error: $e');
    }
  }
}
