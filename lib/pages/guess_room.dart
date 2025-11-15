import 'dart:math';
import 'package:flutter/material.dart';
import 'room_page.dart';

class GuessRoom extends StatelessWidget {
  final String playerName;
  const GuessRoom({super.key, required this.playerName});

  // ... (توابع _createRoom و _joinRoom بدون تغییر)

  void _createRoom(BuildContext context) {
    final roomCode = (Random().nextInt(900000) + 100000).toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomPage(
          roomCode: roomCode,
          playerName: playerName,
          isCreator: true,
        ),
      ),
    );
  }

  void _joinRoom(BuildContext context) {
    // برای سادگی و اجتناب از تغییر StatelessWidget، منطق اعتبارسنجی به _JoinRoomDialog منتقل شد
    showDialog(
      context: context,
      builder: (_) => _JoinRoomDialog(playerName: playerName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Guess Room")),
      body: Padding(
        padding: const EdgeInsets.all(24.0), // افزایش پدینگ برای فضای بیشتر
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, // کشیدن عناصر به عرض کامل
          children: [
            // ✨ بهبود UX: نمایش نام کاربر
            Text(
              "خوش آمدید، ${playerName}!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 50),
            
            // دکمه ایجاد اتاق
            ElevatedButton(
              onPressed: () => _createRoom(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 70), // دکمه کمی بزرگتر
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // گوشه‌های گرد
              ),
              child: const Text("ایجاد اتاق جدید ➕", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 25), // افزایش فاصله بین دکمه‌ها
            
            // دکمه پیوستن به اتاق
            ElevatedButton(
              onPressed: () => _joinRoom(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("پیوستن به اتاق 🤝", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ✨ بهبود UX: استفاده از StatefulWidget برای مدیریت وضعیت ورودی و بازخورد خطا
class _JoinRoomDialog extends StatefulWidget {
  final String playerName;
  const _JoinRoomDialog({required this.playerName});

  @override
  State<_JoinRoomDialog> createState() => __JoinRoomDialogState();
}

class __JoinRoomDialogState extends State<_JoinRoomDialog> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _join() {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorText = "کد اتاق باید دقیقاً ۶ رقم باشد.";
      });
      return;
    }
    
    // اگر معتبر است، دیالوگ را ببند و به RoomPage برو
    Navigator.pop(context); 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomPage(
          roomCode: code,
          playerName: widget.playerName,
          isCreator: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // گوش دادن به تغییرات فیلد برای فعال/غیرفعال کردن دکمه و پاک کردن خطا
    _codeController.addListener(() {
      if (_errorText != null) {
        setState(() {
          _errorText = null;
        });
      }
      setState(() {}); // برای بازسازی ویجت و بررسی طول برای دکمه
    });
    
    final bool isCodeValid = _codeController.text.trim().length == 6;

    return Directionality( // جهت‌دهی مناسب برای دیالوگ فارسی
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text("کد اتاق را وارد کنید"),
        content: TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6, // محدود کردن طول ورودی
          decoration: InputDecoration(
            hintText: "کد ۶ رقمی",
            errorText: _errorText, // ✨ بازخورد خطا
            counterText: "", // حذف شمارنده کاراکتر
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("لغو"),
          ),
          TextButton(
            // ✨ بهبود UX: دکمه پیوستن تنها زمانی فعال است که کد معتبر باشد
            onPressed: isCodeValid ? _join : null, 
            child: const Text("پیوستن"),
          ),
        ],
      ),
    );
  }
}