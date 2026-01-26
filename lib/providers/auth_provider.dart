import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:facecode/models/user_profile.dart';
import 'package:facecode/models/game_error.dart';
import 'package:facecode/services/error_handler.dart';

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
          _user = UserProfile(uid: guestUid, email: '', name: 'Guest Player', isAnonymous: true);
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
          avatarEmoji: current.photoURL ?? '🙂',
          isAnonymous: current.isAnonymous,
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
      await cred.user?.updatePhotoURL('🙂');
      _user = UserProfile(uid: cred.user!.uid, email: email, name: name, avatarEmoji: '🙂', isAnonymous: false);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider.register exception: $e');
      _setError(ErrorHandler.map(e));
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
      _user = UserProfile(
          uid: cred.user!.uid,
          email: cred.user!.email ?? '',
          name: cred.user!.displayName ?? '',
          isAnonymous: cred.user!.isAnonymous);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider.login exception: $e');
      _setError(ErrorHandler.map(e));
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
      _user = UserProfile(uid: cred.user!.uid, email: '', name: 'Guest Player', isAnonymous: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);
      await prefs.remove(_guestUidKey);

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider.signInAnonymously exception: $e');
      if (e is FirebaseAuthException && (e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation')) {
         await _signInGuestOffline();
         return;
      }
      _setError(ErrorHandler.map(e));
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
    _user = UserProfile(uid: uid, email: '', name: 'Guest Player', avatarEmoji: '🙂', isAnonymous: true);
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

  // ─────────────────────────────────────────────────────────────────────────────
  // PROFILE UPDATES
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> updateDisplayName(String name) async {
    try {
      // Update locally first so UI feels instant
      if (_user != null) {
        _user = UserProfile(uid: _user!.uid, email: _user!.email, name: name, avatarEmoji: _user!.avatarEmoji, isAnonymous: _user!.isAnonymous);
        notifyListeners();
      }

      if (!_ensureFirebaseReady()) return;
      final current = _firebaseAuth.currentUser;
      if (current != null) {
        await current.updateDisplayName(name);
      }
    } catch (e) {
      debugPrint('AuthProvider.updateDisplayName error: $e');
    }
  }

  Future<void> updateAvatar(String emoji) async {
    try {
      // Update locally first so UI feels instant
      if (_user != null) {
        _user = UserProfile(uid: _user!.uid, email: _user!.email, name: _user!.name, avatarEmoji: emoji, isAnonymous: _user!.isAnonymous);
        notifyListeners();
      }

      if (!_ensureFirebaseReady()) return;
      final current = _firebaseAuth.currentUser;
      if (current != null) {
        await current.updatePhotoURL(emoji);
      }
    } catch (e) {
      debugPrint('AuthProvider.updateAvatar error: $e');
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
