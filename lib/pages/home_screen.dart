import 'package:flutter/material.dart';
import '../services/appwrite_service.dart';
import 'auth_page.dart';
import 'guess_room.dart'; // یا مسیر درست نسبت به pages/

class HomeScreen extends StatelessWidget {
  final String playerName; // نام بازیکن از صفحه لاگین
  const HomeScreen({super.key, required this.playerName});

  void _openGame(BuildContext context, String gameName) {
    if (gameName == "بازی حدس") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuessRoom(playerName: playerName),
        ),
      );
    } else {
      // ⚠️ منطق دیالوگ بدون تغییر ماند
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(gameName),
          content: const Text("این بازی هنوز آماده نیست!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("باشه"),
            ),
          ],
        ),
      );
    }
  }

  // 🕹️ ویجت سفارشی کارت بازی
  Widget _buildGameCard(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Card(
        // 🖼️ حاشیه‌های گرد و سایه ملایم
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 4,
        margin: EdgeInsets.zero,
        child: InkWell(
          // 🖱️ افکت کلیک روی کارت
          onTap: () => _openGame(context, title),
          borderRadius: BorderRadius.circular(15.0),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appwrite = AppwriteService();

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // پس‌زمینه روشن و تمیز
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.teal.shade600, // رنگ اصلی جدید
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // چون صفحه اصلی است
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🚀 نمایش نام بازیکن
              Flexible(
                child: Text(
                  '👋 بازیکن: $playerName',
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl, // برای نمایش درست فارسی
                ),
              ),
              const Text("صفحه اصلی", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          // 🚪 دکمه خروج
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "خروج",
            onPressed: () async {
              try {
                await appwrite.account.deleteSession(sessionId: 'current');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطا در خروج: $e')),
                );
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20, top: 10),
              child: Text(
                "بازی‌های موجود:",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
                textAlign: TextAlign.right,
              ),
            ),
            
            // 📝 لیست بازی‌ها
            _buildGameCard(context, "بازی حدس", Icons.question_answer_rounded, Colors.blue.shade700),
            _buildGameCard(context, "بازی مار و پله", Icons.casino_rounded, Colors.green.shade700),
            _buildGameCard(context, "بازی گاغد", Icons.style_rounded, Colors.deepOrange.shade700),
          ],
        ),
      ),
    );
  }
}