import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:facecode/models/user_profile.dart';
import 'package:facecode/models/game_error.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  UserProfile? _user;
  bool _isBusy = false;
  GameError? _authError;

  UserProfile? get user => _user;
  bool get isBusy => _isBusy;
  bool get isSignedIn => _user != null;
  GameError? get authError => _authError;

  AuthProvider() {
    _init();
  }

  FirebaseAuth? get _firebaseAuth => _auth;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _ensureFirebaseReady() {
    if (!_isFirebaseReady) {
      _setError(const GameError(
        type: GameErrorType.network,
        title: 'Firebase Not Initialized',
        message: 'Authentication service is not initialized. Please try again later.',
        actionLabel: 'OK',
      ));
      return false;
    }
    _auth ??= FirebaseAuth.instance;
    return true;
  }

  Future<void> _init() async {
    try {
      // Avoid using Firebase if it wasn't successfully initialized
      if (!_isFirebaseReady) {
        debugPrint('AuthProvider: Firebase not initialized yet; skipping Firebase-dependent initialization.');
        return;
      }

      _auth ??= FirebaseAuth.instance;

      // Try to restore session from Firebase currentUser
      final current = _firebaseAuth?.currentUser;
      if (current != null) {
        _user = UserProfile(
          uid: current.uid,
          email: current.email ?? '',
          name: current.displayName ?? '',
        );
        notifyListeners();
      }

      // Optionally enforce session timeout/persistence via SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('remember_me') ?? true;
      if (!remember) await signOut();
    } catch (e, s) {
      debugPrint('AuthProvider._init error: $e\n$s');
      // Swallow errors to avoid crashing the app during provider creation
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EMAIL AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> register(String name, String email, String password) async {
    try {
      if (!_ensureFirebaseReady()) return;
      _isBusy = true;
      notifyListeners();

      if (password.length < 6) {
        throw FirebaseAuthException(code: 'weak-password', message: 'Password too short. Use at least 6 characters.');
      }

      final cred = await _firebaseAuth!.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(name);
      _user = UserProfile(uid: cred.user!.uid, email: email, name: name);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthProvider.register FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          _setError(const GameError(type: GameErrorType.validation, title: 'Email in Use', message: 'This email is already registered.', actionLabel: 'OK'));
          break;
        case 'invalid-email':
          _setError(const GameError(type: GameErrorType.validation, title: 'Invalid Email', message: 'Please enter a valid email address.', actionLabel: 'OK'));
          break;
        case 'weak-password':
          _setError(const GameError(type: GameErrorType.validation, title: 'Weak Password', message: 'Password must be at least 6 characters.', actionLabel: 'OK'));
          break;
        case 'operation-not-allowed':
          _setError(const GameError(type: GameErrorType.validation, title: 'Auth Disabled', message: 'Email/password sign-in is disabled. Enable it in Firebase Console -> Authentication -> Sign-in method.', actionLabel: 'OK'));
          break;
        default:
          _setError(GameError(type: GameErrorType.unknown, title: 'Registration Failed', message: e.message ?? 'Could not create account. Please try again.', actionLabel: 'OK'));
      }
    } catch (e) {
      debugPrint('AuthProvider.register unknown exception: $e');
      _setError(GameError(type: GameErrorType.unknown, title: 'Registration Failed', message: e?.toString() ?? 'Could not create account. Please try again.', actionLabel: 'OK'));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      if (!_ensureFirebaseReady()) return;
      _isBusy = true;
      notifyListeners();

      final cred = await _firebaseAuth!.signInWithEmailAndPassword(email: email, password: password);
      _user = UserProfile(uid: cred.user!.uid, email: cred.user!.email ?? '', name: cred.user!.displayName ?? '');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _setError(const GameError(type: GameErrorType.validation, title: 'User Not Found', message: 'No account found for that email.', actionLabel: 'OK'));
      } else if (e.code == 'wrong-password') {
        _setError(const GameError(type: GameErrorType.validation, title: 'Wrong Password', message: 'Wrong password. Please try again.', actionLabel: 'OK'));
      } else {
        _setError(const GameError(type: GameErrorType.unknown, title: 'Login Failed', message: 'Could not log in. Please try again.', actionLabel: 'OK'));
      }
    } catch (_) {
      _setError(const GameError(type: GameErrorType.unknown, title: 'Login Failed', message: 'Could not log in. Please try again.', actionLabel: 'OK'));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      if (!_ensureFirebaseReady()) return;
      _isBusy = true;
      notifyListeners();
      await _firebaseAuth!.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');
      _user = null;
      notifyListeners();
    } catch (_) {
      _setError(const GameError(type: GameErrorType.unknown, title: 'Logout Failed', message: 'Could not log out. Please try again.', actionLabel: 'OK'));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _setError(GameError error) {
    _authError = error;
    notifyListeners();
    debugPrint('Auth Error: ${error.title} - ${error.message}');
  }

  void clearError() {
    _authError = null;
    notifyListeners();
  }
}
