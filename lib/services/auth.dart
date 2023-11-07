import 'package:babystory/error/error.dart';
import 'package:babystory/models/perent.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServices {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late Perent? _user;

  Perent? get user => _user;

  Future<Perent?> getUser() async {
    User? user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return Perent(
      uid: user.uid,
      email: user.email!,
      nickname: user.displayName ?? 'User',
      signInMethod: SignInMethod.email,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  Perent _getMyUserFromFirebaseUser(
      {required User user, String? nickname, SignInMethod? signInMethod}) {
    return Perent(
      uid: user.uid,
      email: user.email!,
      nickname: user.displayName ?? nickname ?? '',
      signInMethod: signInMethod ?? SignInMethod.email,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  Future<AuthError?> signupWithEmailAndPassword({
    required String email,
    required String nickname,
    required String password,
  }) async {
    try {
      UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        _user = _getMyUserFromFirebaseUser(
            user: credential.user!,
            nickname: nickname,
            signInMethod: SignInMethod.email);
        return null;
      }
      return AuthError(
          message: 'Server Error', type: ErrorType.auth, code: 'server-error');
    } on FirebaseAuthException catch (error) {
      AuthError authError = AuthError(
        message:
            AuthError.getFirebaseAuthError(error.code) ?? 'firebase auth error',
        type: ErrorType.auth,
        code: error.code,
      );
      return authError;
    }
  }

  Future<AuthError?> signinWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account != null) {
      GoogleSignInAuthentication authentication = await account.authentication;
      OAuthCredential googleCredential = GoogleAuthProvider.credential(
        idToken: authentication.idToken,
        accessToken: authentication.accessToken,
      );
      UserCredential credential =
          await _firebaseAuth.signInWithCredential(googleCredential);
      if (credential.user != null) {
        _user = _getMyUserFromFirebaseUser(
            user: credential.user!, signInMethod: SignInMethod.google);
        return null;
      }
      return AuthError(
          code: 'google-user-not-found',
          type: ErrorType.auth,
          message: 'User not found');
    }
    return AuthError(
        message: 'Account not found',
        type: ErrorType.auth,
        code: 'account-not-found');
  }

  Future<AuthError?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        _user = _getMyUserFromFirebaseUser(
            user: credential.user!, signInMethod: SignInMethod.email);
        return null;
      }
      return AuthError(
          message: 'Server Error', type: ErrorType.auth, code: 'server-error');
    } on FirebaseException catch (error) {
      AuthError authError = AuthError(
        message:
            AuthError.getFirebaseAuthError(error.code) ?? 'firebase auth error',
        type: ErrorType.auth,
        code: error.code,
      );
      return authError;
    }
  }

  Future<AuthError?> loginWithGoogle() async {
    return await signinWithGoogle();
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      return;
    }
  }
}
