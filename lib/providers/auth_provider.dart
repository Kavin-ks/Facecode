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
  static const String _guestUidKey = 'guest_local_uid';

  UserProfile? get user => _user;
  bool get isBusy => _isBusy;
  bool get isSignedIn => _user != null;
  GameError? get authError => _authError;

  AuthProvider() {
    _init();
  }

  FirebaseAuth get _firebaseAuth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

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
        debugPrint('AuthProvider: Firebase not initialized yet; using local guest session if available.');
        final prefs = await SharedPreferences.getInstance();
        final guestUid = prefs.getString(_guestUidKey);
        if (guestUid != null) {
          _user = UserProfile(uid: guestUid, email: '', name: 'Guest Player');
          notifyListeners();
        }
        return;
      }

      _auth ??= FirebaseAuth.instance;

      // Try to restore session from Firebase currentUser
      final current = _firebaseAuth.currentUser;
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

      final cred = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
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
      _setError(GameError(type: GameErrorType.unknown, title: 'Registration Failed', message: e.toString(), actionLabel: 'OK'));
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

      final cred = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      _user = UserProfile(uid: cred.user!.uid, email: cred.user!.email ?? '', name: cred.user!.displayName ?? '');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthProvider.login FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        _setError(const GameError(type: GameErrorType.validation, title: 'User Not Found', message: 'No account found for that email.', actionLabel: 'OK'));
      } else if (e.code == 'wrong-password') {
        _setError(const GameError(type: GameErrorType.validation, title: 'Wrong Password', message: 'Wrong password. Please try again.', actionLabel: 'OK'));
      } else {
        _setError(const GameError(type: GameErrorType.unknown, title: 'Login Failed', message: 'Could not log in. Please try again.', actionLabel: 'OK'));
      }
    } catch (e) {
      debugPrint('AuthProvider.login unknown exception: $e');
      _setError(const GameError(type: GameErrorType.unknown, title: 'Login Failed', message: 'Could not log in. Please try again.', actionLabel: 'OK'));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ANONYMOUS AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> signInAnonymously() async {
    try {
      if (!_ensureFirebaseReady()) {
        await _signInGuestOffline();
        return;
      }
      _isBusy = true;
      notifyListeners();

      final cred = await _firebaseAuth.signInAnonymously();
      _user = UserProfile(uid: cred.user!.uid, email: '', name: 'Guest Player');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);
      await prefs.remove(_guestUidKey);

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthProvider.signInAnonymously FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation') {
        await _signInGuestOffline();
        return;
      }
      _setError(GameError(type: GameErrorType.unknown, title: 'Guest Login Failed', message: e.message ?? 'Could not sign in as guest.', actionLabel: 'OK'));
    } catch (e) {
      debugPrint('AuthProvider.signInAnonymously unknown exception: $e');
      _setError(const GameError(type: GameErrorType.unknown, title: 'Guest Login Failed', message: 'Could not sign in as guest.', actionLabel: 'OK'));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _signInGuestOffline() async {
    _isBusy = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_guestUidKey);
    final uid = existing ?? 'guest_local_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_guestUidKey, uid);
    await prefs.setBool('remember_me', true);
    _user = UserProfile(uid: uid, email: '', name: 'Guest Player');
    _isBusy = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      if (!_ensureFirebaseReady()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('remember_me');
        await prefs.remove(_guestUidKey);
        _user = null;
        notifyListeners();
        return;
      }
      _isBusy = true;
      notifyListeners();
      await _firebaseAuth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');
      await prefs.remove(_guestUidKey);
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
