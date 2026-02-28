import 'package:ai_helper/screens/settings_screen.dart';
import 'package:ai_helper/screens/user_data_screen.dart';
import 'package:ai_helper/screens/records_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return
      SafeArea(child:  Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.teal,
          elevation: 0,
          title: Text(
            'بـدايتك',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),

          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ✅ welcome message
                if (authProvider.isLoggedIn)
                  Text(
                    '${authProvider.userName ?? ''} 👋',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                const SizedBox(height: 20),

                Text(
                  'تقييم الاستعداد للزواج',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختبار تحديد مدى استعدادك للزواج',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '40 سؤالاً في 5 مجالات مختلفة',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Provider.of<TestProvider>(context, listen: false).reset();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserDataScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: Text(
                          'ابدأ الاختبار',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecordsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history, color: Colors.white),
                        label: Text(
                          'السجلات المحفوظة',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'المجالات التي نقيسها:',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildCategoryCard('النضج العاطفي', Icons.favorite, Colors.red),
                      _buildCategoryCard('تحمل المسؤولية', Icons.handshake, Colors.blue),
                      _buildCategoryCard('إدارة الخلافات', Icons.balance, Colors.orange),
                      _buildCategoryCard('الاستقلال المالي', Icons.attach_money, Colors.green),
                      _buildCategoryCard('مهارات التواصل', Icons.chat, Colors.purple),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
      );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}