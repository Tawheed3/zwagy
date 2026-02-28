import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    if (_isInitialized) return;

    // listen to Firebase Auth changes
    _authService.user.listen((User? user) {
      _user = user;
      _saveLoginState(user); // ✅ save state on change
      notifyListeners();
    });

    // ✅ restore stored state
    await _restoreLoginState();
    _isInitialized = true;
  }

  // ✅ save login state in SharedPreferences
  Future<void> _saveLoginState(User? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        // user logged in
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', user.uid);
        await prefs.setString('userEmail', user.email ?? '');
        if (user.displayName != null) {
          await prefs.setString('userName', user.displayName!);
        }
        if (user.photoURL != null) {
          await prefs.setString('userPhoto', user.photoURL!);
        }
      } else {
        // user logged out
        await prefs.remove('isLoggedIn');
        await prefs.remove('userId');
        await prefs.remove('userEmail');
        await prefs.remove('userName');
        await prefs.remove('userPhoto');
      }
    } catch (e) {
      print('❌ error saving login state: $e');
    }
  }

  // ✅ restore login state from SharedPreferences
  Future<void> _restoreLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      // if state is stored and current user is null
      if (isLoggedIn && _user == null) {
        // here you can auto-reconnect with Firebase if needed
        print('🔄 restoring stored login state');
        // optional: try to auto sign in
        // await _authService.reloadUser();
      }
    } catch (e) {
      print('❌ error restoring login state: $e');
    }
  }

  // getters
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userEmail => _user?.email;
  String? get userName => _user?.displayName;
  String? get userPhotoUrl => _user?.photoURL;

  // ✅ sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _saveLoginState(user); // ✅ save state after success
      }
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError('فشل تسجيل الدخول بجوجل');
      _setLoading(false);
      return false;
    }
  }

  // ✅ sign in with email
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    if (email.isEmpty || password.isEmpty) {
      _setError('الرجاء إدخال البريد الإلكتروني وكلمة المرور');
      _setLoading(false);
      return false;
    }

    final user = await _authService.signInWithEmail(email, password);

    if (user != null) {
      await _saveLoginState(user); // ✅ save state after success
    } else {
      _setError('فشل تسجيل الدخول. تحقق من بياناتك');
    }

    _setLoading(false);
    return user != null;
  }

  // ✅ create new account
  Future<bool> signUpWithEmail(String email, String password, String confirmPassword) async {
    _setLoading(true);
    _clearError();

    // validate data
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _setError('الرجاء ملء جميع الحقول');
      _setLoading(false);
      return false;
    }

    if (password.length < 6) {
      _setError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      _setLoading(false);
      return false;
    }

    if (password != confirmPassword) {
      _setError('كلمة المرور غير متطابقة');
      _setLoading(false);
      return false;
    }

    final user = await _authService.signUpWithEmail(email, password);

    if (user != null) {
      await _saveLoginState(user); // ✅ save state after success
    } else {
      _setError('فشل إنشاء الحساب. قد يكون البريد مستخدم بالفعل');
    }

    _setLoading(false);
    return user != null;
  }

  // ✅ reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    if (email.isEmpty) {
      _setError('الرجاء إدخال البريد الإلكتروني');
      _setLoading(false);
      return false;
    }

    final success = await _authService.resetPassword(email);
    _setLoading(false);

    if (!success) {
      _setError('فشل إرسال رابط إعادة التعيين');
    }

    return success;
  }

  // ✅ sign out
  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    await _saveLoginState(null); // ✅ clear stored state
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ for debug only
  void printCurrentState() {
    print('📱 AuthProvider State:');
    print('  - isLoggedIn: $isLoggedIn');
    print('  - userEmail: $userEmail');
    print('  - isLoading: $_isLoading');
    print('  - isInitialized: $_isInitialized');
  }
}