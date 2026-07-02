import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pack_vault/data/datasources/firebase_datasource.dart';

/// Handles authentication using Firebase Auth with synthetic email pattern.
/// Username "vedad" becomes "vedad@packvault.local".
/// Persists login state locally for offline access.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatasource _datasource = FirebaseDatasource();

  User? _user;
  String? _username;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get username => _username;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  String get uid => _user!.uid;

  AuthService() {
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUsername();
    }
  }

  String _toEmail(String username) => '${username.toLowerCase().trim()}@packvault.local';

  /// Load username: try local first (instant), then Firebase.
  Future<void> _loadUsername() async {
    if (_user == null) return;

    // Try local storage first (works offline)
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString('username_${_user!.uid}');
      if (_username != null) {
        notifyListeners();
      }
    } catch (_) {}

    // Then try Firebase (updates if changed)
    try {
      final fbUsername = await _datasource.getUsername(_user!.uid);
      if (fbUsername != null && fbUsername != _username) {
        _username = fbUsername;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username_${_user!.uid}', fbUsername);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Firebase username fetch failed (offline?): $e');
    }
  }

  /// Save username locally for offline access.
  Future<void> _saveUsernameLocal(String uid, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username_$uid', username);
    } catch (_) {}
  }

  /// Login an existing user.
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final email = _toEmail(username);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = cred.user;
      _username = username;
      await _saveUsernameLocal(_user!.uid, username);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _error = 'User not found or wrong password.';
      } else if (e.code == 'wrong-password') {
        _error = 'Wrong password. Try again.';
      } else {
        _error = 'Login failed: ${e.message}';
      }
    } catch (e) {
      _error = 'Connection error. Check your internet.';
      debugPrint('Auth error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Register a new user and initialize their card collection.
  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final email = _toEmail(username);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = cred.user;
      _username = username;
      await _saveUsernameLocal(_user!.uid, username);

      // Initialize user profile in RTDB (album data is lazy-initialized)
      await _datasource.initializeUser(_user!.uid, username);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _error = 'Username already taken.';
      } else if (e.code == 'weak-password') {
        _error = 'Password too weak (min 6 characters).';
      } else {
        _error = 'Registration failed: ${e.message}';
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        _error = 'Server configuration error. Contact support.';
      } else {
        _error = 'Connection error. Check your internet.';
      }
      debugPrint('Register error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _username = null;
    notifyListeners();
  }
}
