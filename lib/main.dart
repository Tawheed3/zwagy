// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/test_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'services/advice_service.dart';
import 'services/push_notification_service.dart';
import 'core/utils/navigator_key.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ تهيئة الإشعارات
  final pushNotificationService = PushNotificationService();
  await pushNotificationService.init();

  await AdviceService.loadAdvice();

  // ✅ check stored login state (optional)
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  print('📱 App Starting - isLoggedIn from prefs: $isLoggedIn');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'بـدايتك',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          fontFamily: GoogleFonts.cairo().fontFamily,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}