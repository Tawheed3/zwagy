import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/models/result_model.dart';
import '../providers/test_provider.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final ResultModel result;
  final ScreenshotController screenshotController = ScreenshotController();

  ResultScreen({super.key, required this.result});

  Color _getStatusColor() {
    if (result.status == 'مؤهل للزواج') return Colors.green;
    if (result.status == 'مؤهل جزئياً') return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (result.status == 'مؤهل للزواج') return Icons.emoji_events;
    if (result.status == 'مؤهل جزئياً') return Icons.warning_amber;
    return Icons.error_outline;
  }

  List<Map<String, dynamic>> _getTopStrengths() {
    if (result.detailedStrengths == null) return [];
    List<Map<String, dynamic>> sorted = List.from(result.detailedStrengths!)
      ..sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    return sorted.take(4).toList();
  }

  List<Map<String, dynamic>> _getTopWeaknesses() {
    if (result.detailedWeaknesses == null) return [];
    List<Map<String, dynamic>> sorted = List.from(result.detailedWeaknesses!)
      ..sort((a, b) => (a['score'] ?? 0).compareTo(b['score'] ?? 0));
    return sorted.take(12).toList();
  }

  Future<void> _saveToDatabase(BuildContext context, TestProvider provider) async {
    try {
      await provider.saveTestResult(result);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ تم حفظ النتيجة في قاعدة البيانات',
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '❌ خطأ في حفظ النتيجة: $e',
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // ✅ share as PDF only (without icons or symbols)
  Future<void> _shareAsPDF(BuildContext context) async {
    final topStrengths = _getTopStrengths();
    final topWeaknesses = _getTopWeaknesses();

    try {
      _showLoadingDialog(context);

      // ✅ use Arabic fonts from assets
      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');

      final ttf = pw.Font.ttf(fontData);
      final ttfBold = pw.Font.ttf(fontBoldData);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Text(
                'نتيجة اختبار بدايتك',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: ttfBold),
                textDirection: pw.TextDirection.rtl,
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // main result
              pw.Center(
                child: pw.Text(
                  '${result.overallScore.toStringAsFixed(1)}% - ${result.status}',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: ttfBold),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
              pw.SizedBox(height: 20),

              // category results
              pw.Text(
                'نتائج المجالات:',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfBold),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 10),
              ...result.categoryScores.entries.map((entry) {
                return pw.Text(
                  '${entry.key}: ${entry.value.toStringAsFixed(0)}%',
                  style: pw.TextStyle(fontSize: 12, font: ttf),
                  textDirection: pw.TextDirection.rtl,
                );
              }).toList(),
              pw.SizedBox(height: 20),

              // strengths
              if (topStrengths.isNotEmpty) ...[
                pw.Text(
                  'نقاط القوة:',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfBold),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 10),
                ...topStrengths.asMap().entries.map((entry) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${entry.key + 1}. ${entry.value['question']}',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: ttfBold),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        entry.value['advice'],
                        style: pw.TextStyle(fontSize: 11, font: ttf),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(height: 8),
                    ],
                  );
                }).toList(),
                pw.SizedBox(height: 20),
              ],

              // weaknesses
              if (topWeaknesses.isNotEmpty) ...[
                pw.Text(
                  'نقاط تحتاج تحسين:',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfBold),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 10),
                ...topWeaknesses.asMap().entries.map((entry) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${entry.key + 1}. ${entry.value['question']}',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: ttfBold),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        entry.value['advice'],
                        style: pw.TextStyle(fontSize: 11, font: ttf),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(height: 8),
                    ],
                  );
                }).toList(),
                pw.SizedBox(height: 20),
              ],

              // development plan
              if (result.developmentPlan != null && result.developmentPlan!.isNotEmpty) ...[
                pw.Text(
                  'خطة التطوير:',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfBold),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 10),
                ...result.developmentPlan!.asMap().entries.map((entry) {
                  return pw.Text(
                    '${entry.key + 1}. ${entry.value}',
                    style: pw.TextStyle(fontSize: 12, font: ttf),
                    textDirection: pw.TextDirection.rtl,
                  );
                }).toList(),
                pw.SizedBox(height: 20),
              ],

              // summary
              pw.Text(
                'الملخص:',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfBold),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                result.advice,
                style: pw.TextStyle(fontSize: 12, font: ttf),
                textDirection: pw.TextDirection.rtl,
              ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'تطبيق بدايتك',
                style: pw.TextStyle(fontSize: 10, font: ttf),
                textDirection: pw.TextDirection.rtl,
              ),
            );
          },
        ),
      );

      // save PDF
      final directory = await getTemporaryDirectory();
      final pdfPath = '${directory.path}/result_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      if (context.mounted) {
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(pdfPath)],
          subject: 'نتيجة اختبار بدايتك',
          text: 'نتيجتي في تطبيق بدايتك',
        );
      }
    } catch (e) {
      print('❌ خطأ في إنشاء PDF: $e');
      if (context.mounted) {
        Navigator.pop(context);
        _showError(context, 'خطأ في إنشاء PDF: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
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
              const CircularProgressIndicator(color: Colors.teal),
              const SizedBox(height: 20),
              Text(
                'جاري إنشاء PDF...',
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PdfColor _getPdfStatusColor() {
    if (result.status == 'مؤهل للزواج') return PdfColors.green;
    if (result.status == 'مؤهل جزئياً') return PdfColors.orange;
    return PdfColors.red;
  }

  // ✅ share PDF only (other options removed)
  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مشاركة النتيجة',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // ✅ PDF only
            _buildShareOption(
              ctx,
              Icons.picture_as_pdf,
              'PDF',
                  () => _shareAsPDF(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.teal, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.cairo(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TestProvider>(context);
    final topStrengths = _getTopStrengths();
    final topWeaknesses = _getTopWeaknesses();

    return
      SafeArea(child:  Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.teal,
          elevation: 0,
          title: Text(
            'نتيجتك',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () {
              provider.reset();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white, size: 20),
              onPressed: () => _saveToDatabase(context, provider),
              tooltip: 'حفظ النتيجة',
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20), // ✅ PDF icon
              onPressed: () => _showShareOptions(context),
            ),
          ],
        ),
        body: SafeArea( // ✅ ensure SafeArea
          child: Screenshot(
            controller: screenshotController,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ✅ main result card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal, Colors.teal.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(_getStatusIcon(), size: 40, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          '${result.overallScore.toStringAsFixed(1)}%',
                          style: GoogleFonts.cairo(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            result.status,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ category details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نتائجك في المجالات',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...result.categoryScores.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.cairo(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: LinearProgressIndicator(
                                    value: entry.value / 100,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      entry.value >= 75 ? Colors.green :
                                      entry.value >= 50 ? Colors.orange : Colors.red,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.value.toStringAsFixed(0)}%',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ strengths
                  if (topStrengths.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.thumb_up, color: Colors.green.shade700, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'نقاط القوة',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...topStrengths.asMap().entries.map((entry) {
                            int index = entry.key;
                            var item = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['question'] ?? '',
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['advice'] ?? '',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ✅ weaknesses
                  if (topWeaknesses.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'النقاط التي تحتاج تحسين',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...topWeaknesses.asMap().entries.map((entry) {
                            int index = entry.key;
                            var item = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: item['score'] == 1 ? Colors.red : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['question'] ?? '',
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '💡 ${item['advice'] ?? ''}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ✅ development plan
                  if (result.developmentPlan != null && result.developmentPlan!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timeline, color: Colors.teal.shade700, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'خطة التطوير',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...result.developmentPlan!.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: GoogleFonts.cairo(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ✅ assessment summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.teal, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'ملخص',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.advice,
                          style: GoogleFonts.cairo(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _saveToDatabase(context, provider);
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: Text(
                            'حفظ',
                            style: GoogleFonts.cairo(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            provider.reset();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                                  (route) => false,
                            );
                          },
                          icon: const Icon(Icons.replay, size: 18),
                          label: Text(
                            'اختبار جديد',
                            style: GoogleFonts.cairo(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      )
      );
  }
}