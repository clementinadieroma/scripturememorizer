import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Set via: `--dart-define=SKIP_FIREBASE=true` for local/web preview without Firebase.
const bool kSkipFirebase =
    bool.fromEnvironment('SKIP_FIREBASE', defaultValue: false);

class AuthDatasource {
  AuthDatasource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    bool stub = kSkipFirebase,
  })  : _stub = stub,
        _auth = stub ? null : (firebaseAuth ?? FirebaseAuth.instance),
        _googleSignIn = stub ? null : (googleSignIn ?? GoogleSignIn());

  final bool _stub;
  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;

  Stream<User?> authStateChanges() =>
      _stub ? Stream<User?>.value(null) : _auth!.authStateChanges();

  User? get currentUser => _stub ? null : _auth!.currentUser;

  Never _firebaseRequired() => throw FirebaseAuthException(
        code: 'firebase-not-configured',
        message:
            'Firebase is not configured. Run flutterfire configure, or use '
            '--dart-define=SKIP_FIREBASE=true for guest-only preview.',
      );

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_stub) _firebaseRequired();
    final credential = await _auth!.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }
    return credential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    if (_stub) _firebaseRequired();
    return _auth!.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (_stub) _firebaseRequired();
    final provider = GoogleAuthProvider();

    if (kIsWeb) {
      return _auth!.signInWithPopup(provider);
    }

    final googleUser = await _googleSignIn!.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'aborted-by-user',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth!.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (_stub) return;
    await Future.wait([
      _auth!.signOut(),
      _googleSignIn!.signOut(),
    ]);
  }

  Future<void> sendPasswordReset(String email) {
    if (_stub) _firebaseRequired();
    return _auth!.sendPasswordResetEmail(email: email);
  }
}
