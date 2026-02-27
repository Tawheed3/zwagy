// lib/services/ai_service.dart

import 'dart:math';
import '../core/models/question_model.dart';
import 'advice_service.dart'; // ✅ استيراد خدمة النصائح

class AIService {

  static Future<Map<String, dynamic>> analyzeResults({
    required List<Question> questions,
    required Map<String, int> answers,
    required Map<String, double> categoryScores,
  }) async {

    // حساب النتيجة الإجمالية
    double totalScore = 0;
    answers.forEach((key, value) => totalScore += value);
    double overallScore = (totalScore / (questions.length * 4)) * 100;

    // تحديد الحالة
    String status;
    if (overallScore >= 75) {
      status = 'مؤهل للزواج';
    } else if (overallScore >= 50) {
      status = 'مؤهل جزئياً';
    } else {
      status = 'غير مؤهل';
    }

    // تحضير نقاط القوة والضعف المفصلة
    List<Map<String, dynamic>> detailedStrengths = [];
    List<Map<String, dynamic>> detailedWeaknesses = [];

    for (var question in questions) {
      int score = answers[question.id] ?? 0;
      String answerText = '';

      for (var answer in question.answers) {
        if (answer.score == score) {
          answerText = answer.text;
          break;
        }
      }

      if (score >= 3) {
        detailedStrengths.add({
          'question': question.text,
          'userAnswer': answerText,
          'score': score,
          'category': question.category,
          'analysis': AdviceService.getStrengthAnalysis(question.text, score),
          'advice': AdviceService.getAdvice(question.id, score), // ✅ استخدام JSON
        });
      } else if (score <= 2) {
        detailedWeaknesses.add({
          'question': question.text,
          'userAnswer': answerText,
          'score': score,
          'category': question.category,
          'analysis': AdviceService.getWeaknessAnalysis(question.text, score),
          'advice': AdviceService.getAdvice(question.id, score), // ✅ استخدام JSON
        });
      }
    }

    // ترتيب نقاط القوة (الأعلى أولاً)
    detailedStrengths.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    // ترتيب نقاط الضعف (الأقل أولاً)
    detailedWeaknesses.sort((a, b) => (a['score'] ?? 0).compareTo(b['score'] ?? 0));

    // إنشاء خطة تطوير (أول 3 نقاط ضعف)
    List<String> developmentPlan = [];
    if (detailedWeaknesses.isNotEmpty) {
      developmentPlan.add('الأسبوع الأول: ركز على تحسين: "${detailedWeaknesses[0]['question']}"');
      if (detailedWeaknesses.length > 1) {
        developmentPlan.add('الأسبوع الثاني: اعمل على: "${detailedWeaknesses[1]['question']}"');
      }
      if (detailedWeaknesses.length > 2) {
        developmentPlan.add('الأسبوع الثالث: طور: "${detailedWeaknesses[2]['question']}"');
      }
    }

    // النصيحة العامة
    String generalAdvice = AdviceService.getGeneralAdvice(
      detailedStrengths.length,
      detailedWeaknesses.length,
      overallScore,
    );

    return {
      'overallScore': overallScore,
      'status': status,
      'categoryScores': categoryScores,
      'detailedStrengths': detailedStrengths,
      'detailedWeaknesses': detailedWeaknesses,
      'advice': generalAdvice,
      'developmentPlan': developmentPlan,
    };
  }
}