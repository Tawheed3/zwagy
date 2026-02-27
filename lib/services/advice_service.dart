// lib/services/advice_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';

class AdviceService {
  static Map<String, dynamic> _adviceData = {};

  // ✅ تحميل النصائح من ملف JSON
  static Future<void> loadAdvice() async {
    try {
      final String response = await rootBundle.loadString('lib/data/advice_data.json');
      final data = await json.decode(response);
      _adviceData = data['advice'];
      print('✅ تم تحميل ${_adviceData.length} مفتاح سؤال');

// تحقق من وجود كل الفئات
      int eCount = 0, rCount = 0, cCount = 0, fCount = 0, tCount = 0;

      _adviceData.forEach((key, value) {
        if (key.startsWith('e')) eCount++;
        else if (key.startsWith('r')) rCount++;
        else if (key.startsWith('c')) cCount++;
        else if (key.startsWith('f')) fCount++;
        else if (key.startsWith('t')) tCount++;
      });

      print('📊 تفاصيل التحميل:');
      print('  - النضج العاطفي (e): $eCount/100');
      print('  - تحمل المسؤولية (r): $rCount/100');
      print('  - إدارة الخلافات (c): $cCount/100');
      print('  - الاستقلال المالي (f): $fCount/100');
      print('  - مهارات التواصل (t): $tCount/100');    } catch (e) {
      print('❌ خطأ في تحميل النصائح: $e');
      _adviceData = {};
    }
  }

  // ✅ الحصول على النصيحة حسب ID السؤال والدرجة
  static String getAdvice(String questionId, int score) {
    if (_adviceData.isEmpty) {
      return 'نصيحة عامة: حاول تحسين هذا الجانب بالتدريب المستمر والممارسة.';
    }

    final questionAdvice = _adviceData[questionId];
    if (questionAdvice == null) {
      return 'نصيحة عامة: حاول تحسين هذا الجانب بالتدريب المستمر والممارسة.';
    }

    if (score >= 3) {
      return questionAdvice['strength'] ?? 'نصيحة: حافظ على قوتك هذه واستمر في تطويرها.';
    } else {
      return questionAdvice['weakness'] ?? 'نصيحة: اعمل على تحسين هذا الجانب بالتدريب والممارسة.';
    }
  }

  // ✅ تحليل نقاط القوة
  static String getStrengthAnalysis(String question, int score) {
    if (score == 4) {
      return 'إجابة ممتازة. هذه المهارة متقدمة لديك وتدل على نضجك في هذا الجانب.';
    } else {
      return 'إجابة جيدة. لديك أساس قوي في هذا الجانب، ويمكنك تطويره أكثر.';
    }
  }

  // ✅ تحليل نقاط الضعف
  static String getWeaknessAnalysis(String question, int score) {
    if (score == 1) {
      return 'هذا الجانب يحتاج تحسين كبير. العمل عليه سيفيدك كثيراً في حياتك وعلاقاتك.';
    } else {
      return 'لديك بعض التحديات في هذا الجانب. مع القليل من الاهتمام، يمكنك تحسينه.';
    }
  }

  // ✅ نصيحة عامة
  static String getGeneralAdvice(int strengthsCount, int weaknessesCount, double score) {
    if (score >= 85) {
      return 'أنت في حالة رائعة. حافظ على توازنك وكن قدوة للآخرين.';
    } else if (score >= 75) {
      return 'أنت مؤهل للزواج. ركز على تطوير نقاط قوتك وحسن تواصلك.';
    } else if (score >= 60) {
      return 'أنت قريب من التأهل. اعمل على نقاط الضعف التي ظهرت في التقييم.';
    } else if (score >= 50) {
      return 'تحتاج للعمل على نفسك. حدد أولوياتك وابدأ بخطوات صغيرة.';
    } else {
      return 'أنصحك بالتأمل والتفكير. استشر متخصصاً وطور مهاراتك الشخصية.';
    }
  }
}