import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  // ========== ✅ تسجيل الدخول بجوجل ==========
  Future<User?> signInWithGoogle() async {
    try {
      print('🟡 1. بدء تسجيل الدخول بجوجل');

      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('🔴 2. المستخدم ألغى تسجيل الدخول');
        return null;
      }

      print('🟢 2. تم اختيار حساب: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      print('🟢 3. تم الحصول على التوثيق');
      print('   📝 Access Token موجود: ${googleAuth.accessToken != null}');
      print('   📝 ID Token موجود: ${googleAuth.idToken != null}');

      if (googleAuth.idToken == null) {
        print('🔴 4. ID Token غير موجود!');
        return null;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🟢 4. تم إنشاء credential');

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      print('🟢 5. تم تسجيل الدخول في Firebase');
      print('   👤 المستخدم: ${userCredential.user?.email}');
      print('   🆔 UID: ${userCredential.user?.uid}');

      return userCredential.user;
    } catch (e) {
      print('🔴 خطأ في تسجيل الدخول: $e');
      return null;
    }
  }

  // ========== ✅ تسجيل الدخول بالبريد الإلكتروني ==========
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      print('🟡 بدء تسجيل الدخول بالبريد الإلكتروني');

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('🟢 تم تسجيل الدخول بنجاح');
      print('   👤 المستخدم: ${userCredential.user?.email}');

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('🔴 خطأ في تسجيل الدخول: ${e.code}');

      if (e.code == 'user-not-found') {
        print('🔴 لا يوجد مستخدم بهذا البريد');
      } else if (e.code == 'wrong-password') {
        print('🔴 كلمة المرور غير صحيحة');
      } else if (e.code == 'invalid-email') {
        print('🔴 البريد الإلكتروني غير صالح');
      }
      return null;
    } catch (e) {
      print('🔴 خطأ غير متوقع: $e');
      return null;
    }
  }

  // ========== ✅ إنشاء حساب جديد بالبريد الإلكتروني ==========
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      print('🟡 بدء إنشاء حساب جديد');

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('🟢 تم إنشاء الحساب بنجاح');
      print('   👤 المستخدم: ${userCredential.user?.email}');

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('🔴 خطأ في إنشاء الحساب: ${e.code}');

      if (e.code == 'weak-password') {
        print('🔴 كلمة المرور ضعيفة');
      } else if (e.code == 'email-already-in-use') {
        print('🔴 البريد الإلكتروني مستخدم بالفعل');
      } else if (e.code == 'invalid-email') {
        print('🔴 البريد الإلكتروني غير صالح');
      }
      return null;
    } catch (e) {
      print('🔴 خطأ غير متوقع: $e');
      return null;
    }
  }

  // ========== ✅ إعادة تعيين كلمة المرور ==========
  Future<bool> resetPassword(String email) async {
    try {
      print('🟡 بدء إعادة تعيين كلمة المرور');
      await _auth.sendPasswordResetEmail(email: email);
      print('🟢 تم إرسال رابط إعادة التعيين إلى $email');
      return true;
    } catch (e) {
      print('🔴 خطأ في إعادة تعيين كلمة المرور: $e');
      return false;
    }
  }

  // ========== ✅ تسجيل الخروج ==========
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('🟢 تم تسجيل الخروج');
    } catch (e) {
      print('🔴 خطأ في تسجيل الخروج: $e');
    }
  }

  // ========== ✅ معلومات المستخدم ==========
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
}