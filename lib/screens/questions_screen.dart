import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import 'result_screen.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  String? _selectedAnswer;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.selectedQuestions.isEmpty) {
          return SafeArea(
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      'لا توجد أسئلة متاحة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'حدث خطأ أثناء تحميل الأسئلة',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => provider.reset(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text('حاول مرة أخرى'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        var question = provider.currentQuestion;

        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              backgroundColor: Colors.teal,
              elevation: 0,
              title: Column(
                children: [
                  Text(
                    'سؤال ${provider.currentIndex + 1} من ${provider.selectedQuestions.length}',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('إلغاء الاختبار', style: GoogleFonts.cairo()),
                      content: Text('هل أنت متأكد من إلغاء الاختبار؟', style: GoogleFonts.cairo()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('إلغاء', style: GoogleFonts.cairo()),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.reset();
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: Text('نعم', style: GoogleFonts.cairo(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            body: Column(
              children: [
                // progress bar
                LinearProgressIndicator(
                  value: provider.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  minHeight: 4,
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // category indicator
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.folder, size: 14, color: Colors.teal),
                                  const SizedBox(width: 4),
                                  Text(
                                    provider.currentCategory,
                                    style: GoogleFonts.cairo(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${provider.currentCategoryIndex}/${provider.totalCategories}',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // question text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            question.text,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // answer options
                        Row(
                          children: [
                            Icon(Icons.list, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'اختر إجابتك:',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Expanded(
                          child: ListView.builder(
                            itemCount: question.answers.length,
                            itemBuilder: (context, index) {
                              String answer = question.answers[index].text;
                              bool isSelected = _selectedAnswer == answer;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedAnswer = answer;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.teal.withOpacity(0.05) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? Colors.teal : Colors.grey[300]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              answer,
                                              style: GoogleFonts.cairo(
                                                fontSize: 15,
                                                color: isSelected ? Colors.teal : Colors.black87,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.teal,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // navigation buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (provider.currentIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () {
                              provider.previousQuestion();
                              setState(() {
                                _selectedAnswer = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: const BorderSide(color: Colors.teal),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'السابق',
                              style: GoogleFonts.cairo(fontSize: 16),
                            ),
                          ),
                        ),
                      if (provider.currentIndex > 0) const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedAnswer == null || _isLoading
                              ? null
                              : () async {
                            setState(() => _isLoading = true);

                            provider.saveAnswer(_selectedAnswer!);

                            if (provider.isLastQuestion) {
                              // ✅ ensure user data exists
                              if (provider.userData == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('بيانات المستخدم غير موجودة!', style: GoogleFonts.cairo()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setState(() => _isLoading = false);
                                return;
                              }
                              // show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'الذكاء الاصطناعي يحلل إجاباتك...',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'قد يستغرق هذا بضع ثوانٍ',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                              try {
                                // calculate result with AI
                                var result = await provider.calculateResultWithAI();

                                // ✅ حفظ النتيجة تلقائياً في قاعدة البيانات
                                await provider.saveTestResult(result);

                                if (context.mounted) {
                                  // الانتقال لشاشة النتيجة
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResultScreen(result: result),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('❌ خطأ في حساب النتيجة: $e');
                                if (context.mounted) {
                                  Navigator.pop(context); // close loading dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('حدث خطأ في حساب النتيجة', style: GoogleFonts.cairo()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  setState(() => _isLoading = false);
                                }
                              }
                            } else {
                              provider.nextQuestion();
                              setState(() {
                                _selectedAnswer = null;
                                _isLoading = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading && !provider.isLastQuestion
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            provider.isLastQuestion ? 'عرض النتيجة' : 'التالي',
                            style: GoogleFonts.cairo(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}