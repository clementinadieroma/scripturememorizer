import 'package:firebase_auth/firebase_auth.dart';

import '../datasources/auth_datasource.dart';

class AuthRepository {
  AuthRepository(this._datasource);

  final AuthDatasource _datasource;

  Stream<User?> authStateChanges() => _datasource.authStateChanges();

  User? get currentUser => _datasource.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _datasource.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

  Future<void> signIn({
    required String email,
    required String password,
  }) =>
      _datasource.signInWithEmail(email: email, password: password);

  Future<void> signInWithGoogle() => _datasource.signInWithGoogle();

  Future<void> signOut() => _datasource.signOut();

  Future<void> resetPassword(String email) =>
      _datasource.sendPasswordReset(email);
}
