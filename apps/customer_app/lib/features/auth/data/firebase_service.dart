import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '833719706774-egk0j50gs6bdeta23ta1dqrs069unir7.apps.googleusercontent.com',
    scopes: ['email'],
  );

  fb.User? get currentUser => _auth.currentUser;

  Future<fb.UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<fb.UserCredential> createUserWithEmailAndPassword(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> confirmPasswordReset(String code, String newPassword) {
    return _auth.confirmPasswordReset(code: code, newPassword: newPassword);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<GoogleSignInAccount?> signInWithGoogle() {
    return _googleSignIn.signIn();
  }

  Future<fb.UserCredential> signInWithCredential(fb.AuthCredential credential) {
    return _auth.signInWithCredential(credential);
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Duration timeout,
    required fb.PhoneVerificationCompleted verificationCompleted,
    required fb.PhoneVerificationFailed verificationFailed,
    required fb.PhoneCodeSent codeSent,
    required fb.PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }
}
