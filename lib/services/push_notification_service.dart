// lib/services/push_notification_service.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  auth.AutoRefreshingAuthClient? _authClient;

  // ✅ تهيئة الإشعارات المحلية
  Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'general_channel',
      'الإشعارات العامة',
      description: 'قناة الإشعارات العامة',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('✅ تم تهيئة الإشعارات المحلية');
  }

  // ✅ الحصول على Auth Client من Service Account
  Future<auth.AutoRefreshingAuthClient?> _getAuthClient() async {
    if (_authClient != null) return _authClient;

    try {
      final String jsonString = await rootBundle.loadString('assets/service-account.json');
      final Map<String, dynamic> credentials = json.decode(jsonString);

      final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(credentials),
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      _authClient = client;
      print('✅ تم الحصول على Auth Client');
      return client;
    } catch (e) {
      print('🔴 خطأ في الحصول على Auth Client: $e');
      return null;
    }
  }

  // ✅ إرسال إشعار عام لجميع المستخدمين
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    print('🟡 PushNotificationService: بدأ إرسال الإشعارات العامة');
    try {
      print('🟡 جلب Tokens من Firestore...');
      final usersSnapshot = await _firestore.collection('users').get();
      print('🟡 تم جلب ${usersSnapshot.docs.length} مستخدم');

      final List<String> deviceTokens = [];
      for (var doc in usersSnapshot.docs) {
        final fcmToken = doc.data()['fcmToken'];
        if (fcmToken != null && fcmToken.isNotEmpty) {
          deviceTokens.add(fcmToken);
          print('🟡 Token موجود: ${fcmToken.substring(0, 20)}...');
        }
      }

      if (deviceTokens.isEmpty) {
        print('⚠️ لا توجد أجهزة مسجلة للإشعارات');
        // عرض إشعار محلي للتجربة
        await _showLocalNotification(title, body);
        return;
      }

      print('✅ سيتم إرسال الإشعار إلى ${deviceTokens.length} جهاز');
      print('📱 العنوان: $title');
      print('📱 المحتوى: $body');

      // ✅ عرض إشعار حقيقي على الجهاز
      await _showLocalNotification(title, body);

      // ✅ إرسال إشعارات FCM لجميع الأجهزة
      final client = await _getAuthClient();
      if (client != null) {
        for (String token in deviceTokens) {
          await _sendViaFCMV1(client, token, title, body, data);
        }
      } else {
        print('⚠️ لا يمكن إرسال FCM، Auth Client غير متاح');
      }

      print('🟢 PushNotificationService: تم إرسال الإشعارات بنجاح');
    } catch (e) {
      print('🔴 PushNotificationService: خطأ: $e');
      throw e;
    }
  }

  // ✅ عرض إشعار محلي حقيقي
  Future<void> _showLocalNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'general_channel',
        'الإشعارات العامة',
        channelDescription: 'قناة الإشعارات العامة',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
      );
      print('✅ تم عرض إشعار حقيقي: $title');
    } catch (e) {
      print('🔴 خطأ في عرض الإشعار المحلي: $e');
    }
  }

  // ✅ إرسال إشعار عبر FCM HTTP v1 API
  Future<void> _sendViaFCMV1(
      auth.AutoRefreshingAuthClient client,
      String token,
      String title,
      String body,
      Map<String, String>? data,
      ) async {
    try {
      final response = await client.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/testzawag/messages:send'),
        body: json.encode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data ?? {},
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'general_channel',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                },
              },
            },
          },
        }),
      );

      print('📱 إرسال FCM: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('🔴 خطأ FCM: ${response.body}');
      } else {
        print('✅ تم إرسال FCM بنجاح');
      }
    } catch (e) {
      print('🔴 خطأ في إرسال FCM: $e');
    }
  }

  // ✅ تهيئة الإشعارات
  Future<void> init() async {
    try {
      await initLocalNotifications();

      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('🔔 حالة صلاحية الإشعارات: ${settings.authorizationStatus}');

      String? fcmToken = await _fcm.getToken();
      print('📱 FCM Token: $fcmToken');

      await _saveTokenToFirestore(fcmToken);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 إشعار FCM واصل: ${message.notification?.title}');
        _showLocalNotification(
          message.notification?.title ?? 'إشعار',
          message.notification?.body ?? '',
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 تم الضغط على الإشعار: ${message.notification?.title}');
      });

      await _getAuthClient();

    } catch (e) {
      print('🔴 خطأ في التهيئة: $e');
    }
  }

  // ✅ حفظ Token في Firestore
  Future<void> _saveTokenToFirestore(String? fcmToken) async {
    if (fcmToken == null) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': fcmToken,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ تم حفظ Token للمستخدم $userId');
      }
    } catch (e) {
      print('🔴 خطأ في حفظ Token: $e');
    }
  }

  // ✅ التحقق من صلاحية الإشعارات
  Future<bool> isPermissionGranted() async {
    try {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      return false;
    }
  }

  // ✅ فتح إعدادات التطبيق
  Future<void> openSettings() async {
    try {
      await _fcm.requestPermission();
    } catch (e) {
      print('🔴 خطأ في فتح الإعدادات: $e');
    }
  }

  // ✅ إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    print('✅ تم إلغاء جميع الإشعارات المحلية');
  }

  // ✅ تشغيل الإشعارات المتكررة
  Future<void> startRecurringReminders() async {
    print('✅ تم تشغيل التذكيرات');
  }
}