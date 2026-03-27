// lib/providers/test_provider.dart

import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/models/question_model.dart';
import '../core/models/result_model.dart';
import '../core/models/test_record.dart';
import '../core/models/user_data.dart';
import '../core/utils/navigator_key.dart';
import '../providers/auth_provider.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/push_notification_service.dart';

class TestProvider extends ChangeNotifier {
  List<Question> _allQuestions = [];
  List<Question> _selectedQuestions = [];
  Map<String, int> _answers = {};
  int _currentIndex = 0;
  bool _isLoading = false;

  // user data
  UserData? _userData;

  // AI variables
  bool _isAnalyzing = false;
  Map<String, dynamic> _aiAnalysis = {};

  final List<String> _categoryOrder = [
    'النضج العاطفي',
    'تحمل المسؤولية',
    'إدارة الخلافات',
    'الاستقلال المالي',
    'مهارات التواصل',
  ];

  // getters
  List<Question> get selectedQuestions => _selectedQuestions;
  Map<String, int> get answers => _answers;
  int get currentIndex => _currentIndex;
  Question get currentQuestion => _selectedQuestions[_currentIndex];
  String get currentCategory => _getCurrentCategory();
  int get currentCategoryIndex => _getCurrentCategoryIndex();
  int get totalCategories => _categoryOrder.length;
  bool get isLastQuestion => _currentIndex == _selectedQuestions.length - 1;
  double get progress => _selectedQuestions.isEmpty ? 0 : (_currentIndex + 1) / _selectedQuestions.length;
  bool get isLoading => _isLoading;

  UserData? get userData => _userData;
  bool get hasUserData => _userData != null;
  bool get isAnalyzing => _isAnalyzing;
  Map<String, dynamic> get aiAnalysis => _aiAnalysis;

  // save user data
  void saveUserData({
    required String name,
    required int age,
    required String phone,
    required String gender,
  }) {
    _userData = UserData(
      name: name,
      age: age,
      phone: phone,
      gender: gender,
      testDate: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> loadQuestions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String response = await rootBundle.loadString('lib/data/questions_complete.json');
      final data = json.decode(response);

      final List<dynamic> questionsJson = data['questions'];

      // تحميل جميع الأسئلة مع تحديد الجنس الحالي
      String currentGender = _userData?.gender ?? 'male';

      _allQuestions = questionsJson.map((q) =>
          Question.fromJson(q, gender: currentGender)
      ).toList();

      print('✅ تم تحميل ${_allQuestions.length} سؤال بنجاح');
      _selectRandomQuestions();
    } catch (e) {
      print('❌ خطأ في تحميل الأسئلة: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _selectRandomQuestions() {
    if (_allQuestions.isEmpty) return;

    final random = Random();
    _selectedQuestions = [];

    for (String category in _categoryOrder) {
      List<Question> categoryQuestions = _allQuestions
          .where((q) => q.category == category)
          .toList();

      var shuffled = List<Question>.from(categoryQuestions)..shuffle(random);
      int takeCount = min(8, shuffled.length);
      _selectedQuestions.addAll(shuffled.take(takeCount));

      print('✅ تم إضافة 8 أسئلة من قسم: $category');
    }
    print('✅ إجمالي الأسئلة: ${_selectedQuestions.length}');
  }

  String _getCurrentCategory() {
    if (_selectedQuestions.isEmpty) return '';
    return _selectedQuestions[_currentIndex].category;
  }

  int _getCurrentCategoryIndex() {
    if (_selectedQuestions.isEmpty) return 0;
    String currentCat = _selectedQuestions[_currentIndex].category;
    return _categoryOrder.indexOf(currentCat) + 1;
  }

  void saveAnswer(String answerText) {
    int score = _selectedQuestions[_currentIndex].getScoreForAnswer(answerText);
    _answers[_selectedQuestions[_currentIndex].id] = score;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _selectedQuestions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  Map<String, double> _calculateCategoryScores() {
    Map<String, List<int>> categoryScores = {};

    _answers.forEach((questionId, score) {
      Question question = _selectedQuestions.firstWhere((q) => q.id == questionId);
      categoryScores.putIfAbsent(question.category, () => []).add(score);
    });

    Map<String, double> categoryAverages = {};

    categoryScores.forEach((category, scores) {
      double avg = scores.reduce((a, b) => a + b) / scores.length;
      double percentage = (avg / 4) * 100;
      categoryAverages[category] = percentage;
    });

    return categoryAverages;
  }

  Future<void> analyzeWithAI() async {
    _isAnalyzing = true;
    notifyListeners();

    Map<String, double> categoryScores = _calculateCategoryScores();

    _aiAnalysis = await AIService.analyzeResults(
      questions: _selectedQuestions,
      answers: _answers,
      categoryScores: categoryScores,
      gender: _userData?.gender ?? 'male',
    );

    _isAnalyzing = false;
    notifyListeners();
  }

  Future<ResultModel> calculateResultWithAI() async {
    await analyzeWithAI();

    return ResultModel.fromAIAnalysis(
      analysis: _aiAnalysis,
      rawAnswers: _answers,
      questions: _selectedQuestions,
      gender: _userData?.gender ?? 'male',
    );
  }

  ResultModel calculateResult() {
    Map<String, double> categoryScores = _calculateCategoryScores();

    double totalScore = categoryScores.values.reduce((a, b) => a + b);
    double overallScore = totalScore / categoryScores.length;

    List<String> strengths = [];
    List<String> weaknesses = [];

    categoryScores.forEach((category, score) {
      if (score >= 75) {
        strengths.add(category);
      } else if (score < 50) {
        weaknesses.add(category);
      }
    });

    String status;
    if (overallScore >= 75) {
      status = 'مؤهل للزواج';
    } else if (overallScore >= 50) {
      status = 'مؤهل جزئياً';
    } else {
      status = 'غير مؤهل';
    }

    String advice = _generateAdvice(strengths, weaknesses, overallScore);

    return ResultModel(
      overallScore: overallScore,
      status: status,
      categoryScores: categoryScores,
      strengths: strengths,
      weaknesses: weaknesses,
      advice: advice,
      testDate: DateTime.now(),
      rawAnswers: _answers.map((key, value) => MapEntry(key, value.toString())),
      questions: _selectedQuestions,
    );
  }

  String _generateAdvice(List<String> strengths, List<String> weaknesses, double score) {
    StringBuffer advice = StringBuffer();

    if (score >= 75) {
      advice.writeln('🎉 مبروك! أنت مؤهل للزواج.');
      if (strengths.isNotEmpty) {
        advice.writeln('نقاط قوتك: ${strengths.join('، ')}.');
      }
      advice.writeln('حافظ على تطوير نفسك واستمر في بناء علاقات صحية.');
    } else if (score >= 50) {
      advice.writeln('⚠️ أنت مؤهل جزئياً للزواج.');
      if (weaknesses.isNotEmpty) {
        advice.writeln('تحتاج للتركيز على تطوير: ${weaknesses.join('، ')}.');
      }
      advice.writeln('ننصحك بالعمل على نقاط الضعف قبل الإقدام على الزواج.');
    } else {
      advice.writeln('📝 أنت غير مؤهل للزواج حالياً.');
      if (weaknesses.isNotEmpty) {
        advice.writeln('يجب العمل على: ${weaknesses.join('، ')} قبل التفكير في الزواج.');
      }
      advice.writeln('لا تيأس، التغيير يبدأ بخطوة. استشر متخصصين وطور نفسك.');
    }

    return advice.toString();
  }

  // ✅ حفظ نتيجة الاختبار مع userId
  Future<void> saveTestResult(ResultModel result) async {
    if (_userData == null) return;

    // الحصول على userId من AuthProvider
    final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    final userId = authProvider.user?.uid ?? '';

    if (userId.isEmpty) {
      print('⚠️ المستخدم غير مسجل، لن يتم حفظ السجل');
      return;
    }

    List<String> questionTexts = _selectedQuestions.map((q) => q.text).toList();

    List<Map<String, dynamic>> topStrengths = [];
    if (result.detailedStrengths != null) {
      List<Map<String, dynamic>> sorted = List.from(result.detailedStrengths!)
        ..sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
      topStrengths = sorted.take(4).toList();
    }

    List<Map<String, dynamic>> topWeaknesses = [];
    if (result.detailedWeaknesses != null) {
      List<Map<String, dynamic>> sorted = List.from(result.detailedWeaknesses!)
        ..sort((a, b) => (a['score'] ?? 0).compareTo(b['score'] ?? 0));
      topWeaknesses = sorted.take(12).toList();
    }

    final record = TestRecord(
      userId: userId,
      name: _userData!.name,
      age: _userData!.age,
      phone: _userData!.phone,
      gender: _userData!.gender,
      testDate: DateTime.now(),
      overallScore: result.overallScore,
      status: result.status,
      categoryScores: result.categoryScores,
      strengths: topStrengths,
      weaknesses: topWeaknesses,
      advice: result.advice,
      answers: _answers,
      questions: questionTexts,
    );

    try {
      final dbService = DatabaseService();
      int id = await dbService.insertRecord(record);
      print('✅ تم حفظ السجل للمستخدم $userId بالرقم: $id');
    } catch (e) {
      print('❌ خطأ في حفظ السجل: $e');
    }
  }

  // ✅ جلب سجلات المستخدم الحالي
  Future<List<TestRecord>> getUserRecords() async {
    try {
      final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
      final userId = authProvider.user?.uid ?? '';

      if (userId.isEmpty) return [];

      final dbService = DatabaseService();
      return await dbService.getRecordsByUserId(userId);
    } catch (e) {
      print('❌ خطأ في جلب السجلات: $e');
      return [];
    }
  }

  // ✅ البحث في سجلات المستخدم الحالي
  Future<List<TestRecord>> searchUserRecords(String name) async {
    try {
      final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
      final userId = authProvider.user?.uid ?? '';

      if (userId.isEmpty) return [];

      final dbService = DatabaseService();
      return await dbService.searchRecordsByUserIdAndName(userId, name);
    } catch (e) {
      print('❌ خطأ في البحث: $e');
      return [];
    }
  }

  // ✅ حذف سجل من سجلات المستخدم الحالي
  Future<void> deleteUserRecord(int id) async {
    try {
      final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
      final userId = authProvider.user?.uid ?? '';

      if (userId.isEmpty) return;

      final dbService = DatabaseService();
      await dbService.deleteRecord(id, userId);
      print('✅ تم حذف السجل رقم: $id للمستخدم $userId');
    } catch (e) {
      print('❌ خطأ في حذف السجل: $e');
    }
  }

  // ✅ جلب آخر نتيجة للمستخدم
  Future<TestRecord?> getLastUserResult() async {
    try {
      final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
      final userId = authProvider.user?.uid ?? '';

      if (userId.isEmpty) return null;

      final dbService = DatabaseService();
      final records = await dbService.getRecordsByUserId(userId);

      if (records.isNotEmpty) {
        return records.first; // آخر نتيجة
      }
      return null;
    } catch (e) {
      print('❌ خطأ في جلب آخر نتيجة: $e');
      return null;
    }
  }

  // في test_provider.dart
  Future<void> sendNotificationToAllUsers() async {
    print('🟡 TestProvider: بدأ إرسال الإشعارات');
    try {
      final lastResult = await getLastUserResult();
      print('🟡 آخر نتيجة: ${lastResult?.overallScore}');

      final notificationService = PushNotificationService();

      String title;
      String body;

      if (lastResult != null) {
        final score = lastResult.overallScore.toStringAsFixed(1);

        if (lastResult.overallScore >= 75) {
          title = '🌟 حافظ على تميزك';
          body = 'نتيجتك السابقة $score%. اختبر نفسك مرة أخرى لتتأكد من تطورك!';
        } else if (lastResult.overallScore >= 50) {
          title = '📈 تقدم مستمر';
          body = 'نتيجتك السابقة $score%. حان الوقت لتحسين مستواك بإعادة الاختبار!';
        } else {
          title = '💪 ابدأ رحلتك';
          body = 'نتيجتك السابقة $score%. لا تيأس، التغيير يبدأ بخطوة. جرب الاختبار مرة أخرى!';
        }
      } else {
        title = '📊 اكتشف استعدادك للزواج';
        body = 'لم تقم بإجراء الاختبار بعد. جربه الآن لتعرف مدى استعدادك!';
      }

      print('🟡 العنوان: $title');
      print('🟡 المحتوى: $body');

      await notificationService.sendNotificationToAllUsers(
        title: title,
        body: body,
        data: {
          'type': 'reminder',
          'hasTest': lastResult != null ? 'true' : 'false',
          'score': lastResult?.overallScore.toString() ?? '0',
        },
      );

      print('🟢 TestProvider: تم إرسال الإشعار بنجاح');
    } catch (e) {
      print('🔴 TestProvider: خطأ في إرسال الإشعار: $e');
      throw e;
    }
  }

  void reset() {
    _answers = {};
    _currentIndex = 0;
    _aiAnalysis = {};
    _selectedQuestions = [];
    _userData = null;
    notifyListeners();
  }
}