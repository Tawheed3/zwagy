// lib/screens/settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showAbout = false;
  bool _showContact = false;
  bool _isExpanded = false;
  bool _notificationsEnabled = true;

  File? _profileImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedImage();
      _loadNotificationSettings();
    });
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      setState(() {
        _notificationsEnabled = enabled;
      });
      print('📱 حالة الإشعارات المحملة: $enabled');
    } catch (e) {
      print('🔴 خطأ في تحميل إعدادات الإشعارات: $e');
    }
  }

  Future<void> _saveNotificationSettings(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      print('📱 تم حفظ حالة الإشعارات: $value');
    } catch (e) {
      print('🔴 خطأ في حفظ إعدادات الإشعارات: $e');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    await _saveNotificationSettings(value);

    final notificationService = NotificationService();

    if (value) {
      // تفعيل الإشعارات
      try {
        final hasPermission = await notificationService.isPermissionGranted();
        if (!hasPermission) {
          await notificationService.openSettings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'الرجاء تفعيل الإشعارات من الإعدادات',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        await notificationService.startRecurringReminders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ تم تفعيل الاشعارات',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('🔴 خطأ في تفعيل الإشعارات: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'حدث خطأ في تفعيل الإشعارات',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // إلغاء الإشعارات
      try {
        await notificationService.cancelAllNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ تم إلغاء جميع التذكيرات',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('🔴 خطأ في إلغاء الإشعارات: $e');
      }
    }
  }

  Future<void> _loadSavedImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? 'default';

      final imagePath = prefs.getString('profile_image_$userId');

      print('📂 محاولة تحميل الصورة للمستخدم $userId من: $imagePath');

      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        final exists = await file.exists();

        if (exists) {
          setState(() {
            _profileImage = file;
          });
          print('✅ تم تحميل الصورة المحفوظة للمستخدم $userId');
        } else {
          print('⚠️ ملف الصورة غير موجود للمستخدم $userId، سيتم حذف المسار');
          await prefs.remove('profile_image_$userId');
        }
      }
    } catch (e) {
      print('🔴 خطأ في تحميل الصورة: $e');
    }
  }

  Future<void> _saveImagePath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? 'default';

      await prefs.setString('profile_image_$userId', path);
      print('✅ تم حفظ مسار الصورة للمستخدم $userId: $path');
    } catch (e) {
      print('🔴 خطأ في حفظ مسار الصورة: $e');
    }
  }

  Future<void> _pickImage() async {
    print('🟡 بدأ اختيار الصورة');

    try {
      final picker = ImagePicker();

      print('🟡 فتح المعرض...');

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('🔴 timeout في اختيار الصورة');
          return null;
        },
      );

      if (pickedFile == null) {
        print('⚠️ المستخدم ألغى الاختيار');
        return;
      }

      print('✅ تم اختيار الصورة: ${pickedFile.path}');

      final tempFile = File(pickedFile.path);
      if (!await tempFile.exists()) {
        throw Exception('الملف المختار غير موجود');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/profile_images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        print('📁 تم إنشاء مجلد الصور');
      }

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${imagesDir.path}/$fileName';

      final savedImage = await tempFile.copy(savedPath);
      print('✅ تم نسخ الصورة إلى: $savedPath');

      setState(() {
        _profileImage = savedImage;
      });

      await _saveImagePath(savedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تغيير الصورة بنجاح',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('✅ تم تغيير الصورة بنجاح');

    } catch (e, stackTrace) {
      print('🔴 خطأ في اختيار الصورة: $e');
      print('🔴 StackTrace: $stackTrace');

      String errorMessage = 'حدث خطأ في اختيار الصورة';

      if (e.toString().contains('permission')) {
        errorMessage = 'الرجاء السماح بصلاحية الوصول للمعرض';
      } else if (e.toString().contains('channel')) {
        errorMessage = 'خطأ في الاتصال، يرجى إعادة تشغيل التطبيق';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'انتهت المهلة، حاول مرة أخرى';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteImage() async {
    print('🟡 بدأ حذف الصورة');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف الصورة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف الصورة الشخصية؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (_profileImage != null && await _profileImage!.exists()) {
        await _profileImage!.delete();
        print('✅ تم حذف ملف الصورة');
      }

      final prefs = await SharedPreferences.getInstance();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? 'default';

      await prefs.remove('profile_image_$userId');
      print('✅ تم حذف مسار الصورة للمستخدم $userId');

      setState(() {
        _profileImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف الصورة بنجاح',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('✅ تم حذف الصورة بنجاح');

    } catch (e, stackTrace) {
      print('🔴 خطأ في حذف الصورة: $e');
      print('🔴 StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ في حذف الصورة',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'خيارات الصورة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.teal),
              ),
              title: Text(
                'تغيير الصورة',
                style: GoogleFonts.cairo(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),

            if (_profileImage != null || _hasFirebaseImage()) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: Text(
                  'حذف الصورة',
                  style: GoogleFonts.cairo(fontSize: 16, color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteImage();
                },
              ),
            ],

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.grey),
              ),
              title: Text(
                'إلغاء',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasFirebaseImage() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userPhotoUrl != null && authProvider.userPhotoUrl!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: Text(
          'الإعدادات',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileCard(authProvider),
              const SizedBox(height: 16),

              // ✅ زر الإشعارات مباشرة بعد الـ Profile
              _buildNotificationSection(),

              const SizedBox(height: 20),
              _buildAboutSection(),
              const SizedBox(height: 8),
              _buildContactSection(),
              const SizedBox(height: 20),
              _buildLogoutButton(authProvider),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageOptions,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.teal,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildProfileImage(authProvider),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            authProvider.userName ?? 'مستخدم',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.userEmail ?? 'example@email.com',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(AuthProvider authProvider) {
    if (_profileImage != null) {
      return Image.file(
        _profileImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          print('🔴 خطأ في تحميل الصورة المحلية: $error');
          return _buildInitialImage(authProvider);
        },
      );
    } else if (authProvider.userPhotoUrl != null && authProvider.userPhotoUrl!.isNotEmpty) {
      return Image.network(
        authProvider.userPhotoUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.teal,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('🔴 خطأ في تحميل صورة Firebase: $error');
          return _buildInitialImage(authProvider);
        },
      );
    } else {
      return _buildInitialImage(authProvider);
    }
  }

  Widget _buildInitialImage(AuthProvider authProvider) {
    String initial = 'U';
    if (authProvider.userName != null && authProvider.userName!.isNotEmpty) {
      initial = authProvider.userName![0].toUpperCase();
    }
    return Container(
      color: Colors.teal.shade100,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.cairo(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ),
    );
  }

  // ✅ قسم الإشعارات (يظهر مباشرة بعد الـ Profile)
  Widget _buildNotificationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: _notificationsEnabled ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الاشعارات',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeColor: Colors.blue,
            activeTrackColor: Colors.blue.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showAbout = !_showAbout;
            });
          },
          child: _buildSectionHeader(
            icon: Icons.info_outline,
            title: 'عن التطبيق',
            color: Colors.green,
            isExpanded: _showAbout,
          ),
        ),
        const SizedBox(height: 8),

        if (_showAbout) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: Colors.amber.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'مدرسة العقيق الأهلية النموذجية',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '👩‍🎓 الطالبات المشاركات:',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.purple.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isExpanded ? 'إخفاء الأسماء' : 'عرض الأسماء',
                            style: GoogleFonts.cairo(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 12),
                    _buildStudentCard('غيداء القرشي'),
                    _buildStudentCard('وتين الصائغ'),
                    _buildStudentCard('حلا ثروة'),
                    _buildStudentCard('ليان ضمرة'),
                    _buildStudentCard('سجى القرني'),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'عن التطبيق:',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'هذا التطبيق يساعدك في تقييم استعدادك للزواج من خلال اختبار شامل يغطي خمسة مجالات رئيسية: النضج العاطفي، تحمل المسؤولية، إدارة الخلافات، الاستقلال المالي، ومهارات التواصل. يقدم لك التطبيق تحليلاً مفصلاً لإجاباتك مع نصائح مخصصة وخطة تطوير لمساعدتك على تحسين نقاط ضعفك وتعزيز نقاط قوتك.',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStudentCard(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person,
            color: Colors.purple,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showContact = !_showContact;
            });
          },
          child: _buildSectionHeader(
            icon: Icons.contact_mail,
            title: 'اتصل بنا',
            color: Colors.orange,
            isExpanded: _showContact,
          ),
        ),
        const SizedBox(height: 8),

        if (_showContact) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildContactTile(
                    icon: Icons.email,
                    iconColor: Colors.red,
                    title: 'البريد الإلكتروني',
                    subtitle: 'ghayda650@gmail.com',
                    onTap: () => _launchEmail('ghayda650@gmail.com'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.cairo(fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required bool isExpanded,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.red,
          ),
        ),
        onTap: () => _showLogoutDialog(context, authProvider),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final notificationService = NotificationService();
                await notificationService.cancelAllNotifications();
              } catch (e) {
                print('🔴 خطأ في إلغاء الإشعارات: $e');
              }

              Navigator.pop(ctx);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email?subject=استفسار&body=مرحباً');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('🔴 خطأ في فتح البريد: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن فتح تطبيق البريد', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}