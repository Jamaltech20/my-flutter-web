import 'package:flutter/material.dart';

// --- ویجت برای بخش ثبت عدد (شروع‌کننده) 🔢 ---
class StarterInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool isNumberSubmitted; 

  const StarterInput({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.isLoading,
    required this.isNumberSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    if (isNumberSubmitted) {
      // ✅ وضعیت ۱: عدد ثبت شده است - نمایش پیام انتظار
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Center(
          child: Text(
            '✅ عدد محرمانه ثبت شد. منتظر حدس حریف هستید...',
            style: TextStyle(fontSize: 16, color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 💡 وضعیت ۲: عدد ثبت نشده است - نمایش فیلد ورودی و دکمه
    return Column(
      children: [
        // خانه برای ثبت عدد (TextField)
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'عدد محرمانه خود را وارد کنید (1 تا 100)',
            counterText: '', // حذف شمارنده کاراکتر
          ),
          enabled: !isLoading, // اگر در حال بارگذاری است، غیرفعال شود
        ),
        const SizedBox(height: 15),
        
        // دکمه ثبت عدد (ElevatedButton)
        ElevatedButton(
          onPressed: isLoading ? null : onSubmit, // اگر در حال بارگذاری است، غیرفعال شود
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: isLoading 
              ? const SizedBox(
                  height: 20, 
                  width: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text(
                  'ثبت عدد محرمانه و شروع بازی',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

// --- ویجت GuesserInput (بدون تغییر، برای مرجع) 🎯 ---
class GuesserInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isLoading;
  final int remainingGuesses;

  const GuesserInput({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.isLoading,
    required this.remainingGuesses,
  });

  @override
  Widget build(BuildContext context) {
    final bool canSubmitGuess = !isLoading && remainingGuesses > 0;

    if (remainingGuesses <= 0 && !isLoading) {
      return const SizedBox.shrink(); 
    }

    return Column(
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 3,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'حدس خود را وارد کنید (شانس باقی: $remainingGuesses)',
            counterText: '',
          ),
          enabled: canSubmitGuess,
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: canSubmitGuess ? onSubmit : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: isLoading 
              ? const SizedBox(
                  height: 20, 
                  width: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text(
                  'ثبت حدس',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}