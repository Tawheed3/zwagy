import 'question_model.dart';
import 'package:flutter/material.dart';

class ResultModel {
  final double overallScore;
  final String status;
  final Map<String, double> categoryScores;
  final List<String> strengths; // للتوافق مع الكود القديم
  final List<String> weaknesses; // للتوافق مع الكود القديم
  final String advice;
  final DateTime testDate;
  final Map<String, dynamic> rawAnswers;
  final List<Question> questions;

  // ✅ إضافات جديدة من AI
  final List<Map<String, dynamic>>? detailedStrengths;
  final List<Map<String, dynamic>>? detailedWeaknesses;
  final List<String>? developmentPlan;

  ResultModel({
    required this.overallScore,
    required this.status,
    required this.categoryScores,
    required this.strengths,
    required this.weaknesses,
    required this.advice,
    required this.testDate,
    required this.rawAnswers,
    required this.questions,
    this.detailedStrengths,
    this.detailedWeaknesses,
    this.developmentPlan,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    return ResultModel(
      overallScore: json['overallScore']?.toDouble() ?? 0,
      status: json['status'] ?? '',
      categoryScores: Map<String, double>.from(json['categoryScores'] ?? {}),
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      advice: json['advice'] ?? '',
      testDate: DateTime.parse(json['testDate']),
      rawAnswers: json['rawAnswers'] ?? {},
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
      detailedStrengths: json['detailedStrengths'] != null
          ? List<Map<String, dynamic>>.from(json['detailedStrengths'])
          : null,
      detailedWeaknesses: json['detailedWeaknesses'] != null
          ? List<Map<String, dynamic>>.from(json['detailedWeaknesses'])
          : null,
      developmentPlan: json['developmentPlan'] != null
          ? List<String>.from(json['developmentPlan'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'status': status,
      'categoryScores': categoryScores,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'advice': advice,
      'testDate': testDate.toIso8601String(),
      'rawAnswers': rawAnswers,
      'questions': questions.map((q) => q.toJson()).toList(),
      'detailedStrengths': detailedStrengths,
      'detailedWeaknesses': detailedWeaknesses,
      'developmentPlan': developmentPlan,
    };
  }

  // ✅ من تحليل AI
  factory ResultModel.fromAIAnalysis({
    required Map<String, dynamic> analysis,
    required Map<String, int> rawAnswers,
    required List<Question> questions,
  }) {
    // استخراج القيم من التحليل
    double overallScore = analysis['overallScore']?.toDouble() ?? 0;
    String status = analysis['status'] ?? 'غير محدد';
    Map<String, double> categoryScores = Map<String, double>.from(analysis['categoryScores'] ?? {});

    // نقاط القوة والضعف المبسطة (للتوافق مع الكود القديم)
    List<String> strengths = [];
    List<String> weaknesses = [];

    // استخراج النقاط المفصلة
    List<Map<String, dynamic>>? detailedStrengths;
    List<Map<String, dynamic>>? detailedWeaknesses;
    List<String>? developmentPlan;

    if (analysis['detailedStrengths'] != null) {
      detailedStrengths = List<Map<String, dynamic>>.from(analysis['detailedStrengths']);
      // إضافة النقاط المبسطة
      strengths = detailedStrengths.map((s) => s['question']?.toString() ?? '').toList();
    }

    if (analysis['detailedWeaknesses'] != null) {
      detailedWeaknesses = List<Map<String, dynamic>>.from(analysis['detailedWeaknesses']);
      weaknesses = detailedWeaknesses.map((w) => w['question']?.toString() ?? '').toList();
    }

    if (analysis['developmentPlan'] != null) {
      developmentPlan = List<String>.from(analysis['developmentPlan']);
    }

    String advice = analysis['advice'] ?? 'شكراً لمشاركتك';

    return ResultModel(
      overallScore: overallScore,
      status: status,
      categoryScores: categoryScores,
      strengths: strengths,
      weaknesses: weaknesses,
      advice: advice,
      testDate: DateTime.now(),
      rawAnswers: rawAnswers.map((key, value) => MapEntry(key, value.toString())),
      questions: questions,
      detailedStrengths: detailedStrengths,
      detailedWeaknesses: detailedWeaknesses,
      developmentPlan: developmentPlan,
    );
  }

  // ✅ لون الحالة
  Color getStatusColor() {
    if (status.contains('مؤهل للزواج')) return Colors.green;
    if (status.contains('مؤهل جزئياً')) return Colors.orange;
    return Colors.red;
  }

  // ✅ أيقونة الحالة
  IconData getStatusIcon() {
    if (status.contains('مؤهل للزواج')) return Icons.emoji_events;
    if (status.contains('مؤهل جزئياً')) return Icons.warning;
    return Icons.error;
  }

  // ✅ وصف مختصر للحالة
  String getStatusDescription() {
    if (status.contains('مؤهل للزواج')) {
      return 'أنت جاهز للزواج، لديك نضج عاطفي واجتماعي جيد';
    } else if (status.contains('مؤهل جزئياً')) {
      return 'أنت في الطريق الصحيح، لكن تحتاج لتحسين بعض الجوانب';
    } else {
      return 'تحتاج للعمل على نفسك أكثر قبل التفكير في الزواج';
    }
  }

  // ✅ نصيحة إضافية حسب النتيجة
  String getDetailedAdvice() {
    if (overallScore >= 85) {
      return '🌟 ممتاز! أنت في حالة رائعة. حافظ على توازنك وكن قدوة للآخرين.';
    } else if (overallScore >= 75) {
      return '🎯 أنت مؤهل للزواج. ركز على تطوير نقاط قوتك وحسن تواصلك.';
    } else if (overallScore >= 60) {
      return '📈 أنت قريب من التأهل. اعمل على نقاط الضعف التي ظهرت في التقييم.';
    } else if (overallScore >= 50) {
      return '💪 تحتاج للعمل على نفسك. حدد أولوياتك وابدأ بخطوات صغيرة.';
    } else {
      return '📝 أنصحك بالتأمل والتفكير. استشر متخصصاً وطور مهاراتك الشخصية.';
    }
  }

  // ✅ تحليل سريع لأدنى وأعلى قسم
  Map<String, dynamic> getCategoryAnalysis() {
    if (categoryScores.isEmpty) {
      return {
        'highest': {'category': 'لا يوجد', 'score': 0.0},
        'lowest': {'category': 'لا يوجد', 'score': 0.0},
      };
    }

    var highest = categoryScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    var lowest = categoryScores.entries.reduce((a, b) => a.value < b.value ? a : b);

    return {
      'highest': {'category': highest.key, 'score': highest.value},
      'lowest': {'category': lowest.key, 'score': lowest.value},
    };
  }

  // ✅ هل النتيجة جيدة؟
  bool get isGood => overallScore >= 75;

  // ✅ هل النتيجة متوسطة؟
  bool get isAverage => overallScore >= 50 && overallScore < 75;

  // ✅ هل النتيجة ضعيفة؟
  bool get isPoor => overallScore < 50;

  // ✅ تنسيق التاريخ
  String get formattedDate {
    return '${testDate.day}/${testDate.month}/${testDate.year}';
  }

  // ✅ تنسيق التاريخ مع الوقت
  String get formattedDateTime {
    return '${testDate.day}/${testDate.month}/${testDate.year} ${testDate.hour}:${testDate.minute.toString().padLeft(2, '0')}';
  }

  // ✅ مقارنة نتيجتين
  bool isBetterThan(ResultModel other) {
    return overallScore > other.overallScore;
  }

  // ✅ الفرق بين نتيجتين
  double differenceWith(ResultModel other) {
    return (overallScore - other.overallScore).abs();
  }

  // ✅ نص ملخص سريع للنتيجة
  String get quickSummary {
    return '$formattedDate - $overallScore% - $status';
  }

  // ✅ نص ملخص مع النقاط الرئيسية
  String get fullSummary {
    StringBuffer summary = StringBuffer();
    summary.writeln('📊 نتيجة تقييم ${formattedDateTime}');
    summary.writeln('الدرجة النهائية: $overallScore%');
    summary.writeln('الحالة: $status');
    summary.writeln('');

    if (detailedStrengths != null && detailedStrengths!.isNotEmpty) {
      summary.writeln('✅ نقاط القوة:');
      for (var s in detailedStrengths!) {
        summary.writeln('   • ${s['question']}');
      }
    }

    if (detailedWeaknesses != null && detailedWeaknesses!.isNotEmpty) {
      summary.writeln('⚠️ نقاط الضعف:');
      for (var w in detailedWeaknesses!) {
        summary.writeln('   • ${w['question']}');
        summary.writeln('     💡 نصيحة: ${w['advice']}');
      }
    }

    summary.writeln('');
    summary.writeln('💡 نصيحة: $advice');

    return summary.toString();
  }
}