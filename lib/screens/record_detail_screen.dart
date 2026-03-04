import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/models/test_record.dart';
import '../providers/test_provider.dart';

class RecordDetailScreen extends StatelessWidget {
  final TestRecord record;

  const RecordDetailScreen({super.key, required this.record});

  Color _getScoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  // ✅ share as PDF
  Future<void> _shareAsPDF(BuildContext context) async {
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
              // personal info
              pw.Text(
                'البيانات الشخصية',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: ttfBold),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 10),
              pw.Text('الاسم: ${record.name}', style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),
              pw.Text('العمر: ${record.age} سنة', style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),
              pw.Text('العنوان: ${record.address}', style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),
              pw.Text('الهاتف: ${record.phone}', style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),
              pw.Text('تاريخ الاختبار: ${record.formattedDate} - ${record.formattedTime}',
                  style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),

              pw.SizedBox(height: 20),

              // main result
              pw.Center(
                child: pw.Text(
                  '${record.overallScore.toStringAsFixed(1)}% - ${record.status}',
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
              ...record.categoryScores.entries.map((entry) {
                return pw.Text(
                  '${entry.key}: ${entry.value.toStringAsFixed(0)}%',
                  style: pw.TextStyle(fontSize: 12, font: ttf),
                  textDirection: pw.TextDirection.rtl,
                );
              }).toList(),
              pw.SizedBox(height: 20),

              // strengths
              if (record.strengths.isNotEmpty) ...[
                pw.Text(
                  'نقاط القوة:',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfBold),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 10),
                ...record.strengths.asMap().entries.map((entry) {
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
              if (record.weaknesses.isNotEmpty) ...[
                pw.Text(
                  'نقاط تحتاج تحسين:',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfBold),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 10),
                ...record.weaknesses.asMap().entries.map((entry) {
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

              // general advice
              pw.Text(
                'النصيحة العامة:',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfBold),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                record.advice,
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
        Navigator.pop(context); // close loading dialog
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(pdfPath)],
          subject: 'نتيجة اختبار بدايتك',
          text: 'نتيجتي في تطبيق بدايتك',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : const Rect.fromLTWH(0, 0, 100, 100),
        );
      }
    } catch (e) {
      print('❌ خطأ في إنشاء PDF: $e');
      if (context.mounted) {
        Navigator.pop(context); // close loading dialog
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.teal,
          elevation: 0,
          title: Text(
            'تفاصيل التقييم',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // ✅ PDF مباشر - بدون BottomSheet
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: () => _shareAsPDF(context),  // ✅ استدعاء مباشر
              tooltip: 'مشاركة كـ PDF',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('حذف السجل', style: GoogleFonts.cairo()),
                    content: Text(
                      'هل أنت متأكد من حذف هذا السجل؟',
                      style: GoogleFonts.cairo(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('إلغاء', style: GoogleFonts.cairo()),
                      ),
                      TextButton(
                        onPressed: () async {
                          final provider = Provider.of<TestProvider>(context,
                              listen: false);
                          await provider.deleteRecord(record.id!);
                          Navigator.pop(ctx); // close dialog
                          Navigator.pop(context, true);
                        },
                        child: Text(
                          'حذف',
                          style: GoogleFonts.cairo(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // personal data card
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
                        Icon(Icons.person, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'البيانات الشخصية',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('الاسم', record.name),
                    _buildInfoRow('العمر', '${record.age} سنة'),
                    _buildInfoRow('العنوان', record.address),
                    _buildInfoRow('الهاتف', record.phone),
                    _buildInfoRow(
                      'تاريخ الاختبار',
                      '${record.formattedDate} - ${record.formattedTime}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // result card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${record.overallScore.toStringAsFixed(1)}%',
                      style: GoogleFonts.cairo(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(record.overallScore),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(record.overallScore).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.status,
                        style: GoogleFonts.cairo(
                          color: _getScoreColor(record.overallScore),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // category details
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
                      'نتائج المجالات',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...record.categoryScores.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                                  entry.value >= 75
                                      ? Colors.green
                                      : entry.value >= 50
                                      ? Colors.orange
                                      : Colors.red,
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

              const SizedBox(height: 16),

              // top 4 strengths
              if (record.strengths.isNotEmpty) ...[
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
                          Icon(Icons.thumb_up, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'نقاط القوة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...record.strengths.asMap().entries.map((entry) {
                        int index = entry.key;
                        var s = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s['question'] ?? '',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '💡 ${s['advice']}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // top 12 weaknesses
              if (record.weaknesses.isNotEmpty) ...[
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
                          Icon(Icons.warning, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'النقاط التي تحتاج تحسين',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...record.weaknesses.asMap().entries.map((entry) {
                        int index = entry.key;
                        var w = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: w['score'] == 1 ? Colors.red : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      w['question'] ?? '',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '💡 ${w['advice']}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // general advice
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
                        Icon(Icons.auto_awesome, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'النصيحة العامة',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.advice,
                      style: GoogleFonts.cairo(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}