import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/question_model.dart';
import '../core/models/result_model.dart';
import '../core/models/test_record.dart';
import '../core/models/user_data.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';

class TestProvider extends ChangeNotifier {
  List<Question> _allQuestions = [];
  List<Question> _selectedQuestions = [];
  Map<String, int> _answers = {};
  int _currentIndex = 0;
  bool _isLoading = true;

  // ✅ user data
  UserData? _userData;

  // ✅ AI variables
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

  // ✅ new getters
  UserData? get userData => _userData;
  bool get hasUserData => _userData != null;

  // ✅ AI getters
  bool get isAnalyzing => _isAnalyzing;
  Map<String, dynamic> get aiAnalysis => _aiAnalysis;

  TestProvider() {
    loadQuestions();
  }

  // ✅ save user data
  void saveUserData({
    required String name,
    required int age,
    required String address,
    required String phone,
  }) {
    _userData = UserData(
      name: name,
      age: age,
      address: address,
      phone: phone,
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
      _allQuestions = questionsJson.map((q) => Question.fromJson(q)).toList();

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

  // ✅ save test result to database (top 4 strengths and top 12 weaknesses)
  Future<void> saveTestResult(ResultModel result) async {
    if (_userData == null) return;

    // convert questions to text
    List<String> questionTexts = _selectedQuestions.map((q) => q.text).toList();

    // get top 4 strengths
    List<Map<String, dynamic>> topStrengths = [];
    if (result.detailedStrengths != null) {
      List<Map<String, dynamic>> sorted = List.from(result.detailedStrengths!)
        ..sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
      topStrengths = sorted.take(4).toList();
    }

    // get top 12 weaknesses
    List<Map<String, dynamic>> topWeaknesses = [];
    if (result.detailedWeaknesses != null) {
      List<Map<String, dynamic>> sorted = List.from(result.detailedWeaknesses!)
        ..sort((a, b) => (a['score'] ?? 0).compareTo(b['score'] ?? 0));
      topWeaknesses = sorted.take(12).toList();
    }

    final record = TestRecord(
      name: _userData!.name,
      age: _userData!.age,
      address: _userData!.address,
      phone: _userData!.phone,
      testDate: DateTime.now(),
      overallScore: result.overallScore,
      status: result.status,
      categoryScores: result.categoryScores,
      strengths: topStrengths, // ✅ top 4 only
      weaknesses: topWeaknesses, // ✅ top 12 only
      advice: result.advice,
      answers: _answers,
      questions: questionTexts,
    );

    try {
      final dbService = DatabaseService();
      int id = await dbService.insertRecord(record);
      print('✅ تم حفظ السجل بنجاح بالرقم: $id');
    } catch (e) {
      print('❌ خطأ في حفظ السجل: $e');
    }
  }

  // ✅ get all records
  Future<List<TestRecord>> getAllRecords() async {
    try {
      final dbService = DatabaseService();
      return await dbService.getAllRecords();
    } catch (e) {
      print('❌ خطأ في جلب السجلات: $e');
      return [];
    }
  }

  // ✅ get records by name
  Future<List<TestRecord>> getRecordsByName(String name) async {
    try {
      final dbService = DatabaseService();
      return await dbService.getRecordsByName(name);
    } catch (e) {
      print('❌ خطأ في جلب السجلات: $e');
      return [];
    }
  }

  // ✅ delete record
  Future<void> deleteRecord(int id) async {
    try {
      final dbService = DatabaseService();
      await dbService.deleteRecord(id);
      print('✅ تم حذف السجل رقم: $id');
    } catch (e) {
      print('❌ خطأ في حذف السجل: $e');
    }
  }

  void reset() {
    _answers = {};
    _currentIndex = 0;
    _aiAnalysis = {};
    _selectRandomQuestions();
    notifyListeners();
  }
}