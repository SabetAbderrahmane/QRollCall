import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  bool _googleInitialized = false;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmailPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final trimmedName = fullName.trim();
    if (trimmedName.isNotEmpty) {
      await credential.user?.updateDisplayName(trimmedName);
      await credential.user?.reload();
    }

    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'google-id-token-missing',
        message: 'Google sign-in did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<String> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No authenticated Firebase user found.');
    }

    final token = await user.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw Exception('Failed to get Firebase ID token.');
    }

    return token;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    if (_googleInitialized) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // no-op
      }
    }
  }
}