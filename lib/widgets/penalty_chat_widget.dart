import 'package:flutter/material.dart';

class PenaltyChatWidget extends StatelessWidget {
  final bool isPlayerTheQuestionWinner;
  final String currentPenaltyQuestion;
  final List<String> messages;
  final TextEditingController responseController;
  final VoidCallback onSendPenaltyResponse;
  final bool enableAnswerButtons;
  final VoidCallback onAnswerCompleted;
  final VoidCallback onAnswerNotCompleted;

  const PenaltyChatWidget({
    super.key,
    required this.isPlayerTheQuestionWinner,
    required this.currentPenaltyQuestion,
    required this.messages,
    required this.responseController,
    required this.onSendPenaltyResponse,
    required this.enableAnswerButtons,
    required this.onAnswerCompleted,
    required this.onAnswerNotCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // تم رنگی برای دکمه‌های اصلی
    final completedColor = Colors.green.shade600;
    final notCompletedColor = Colors.red.shade600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🏆 سوال جریمه - برجسته و با Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    "سوال جریمه:",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentPenaltyQuestion,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.deepOrange.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 20, thickness: 1),
                  Text(
                    isPlayerTheQuestionWinner ? "✨ نوبت شما برای پاسخ" : "⏳ انتظار برای پاسخ حریف",
                    style: TextStyle(
                      fontSize: 16,
                      color: isPlayerTheQuestionWinner ? Colors.blue.shade700 : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- 💬 باکس چت و ارسال پیام ---
          if (isPlayerTheQuestionWinner)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: responseController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: "پیام شما (حداکثر ۵۰ حرف)",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      counterText: "",
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onSendPenaltyResponse,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text("ارسال پیام جریمه", style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            )
          else
            // پیام انتظار
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "... منتظر ارسال پیام برنده باشید ...",
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16, color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // --- 📣 نمایش پیام ارسالی (اگر وجود دارد) ---
          if (messages.isNotEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.blue.shade50, // رنگ پس‌زمینه حباب پیام
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "آخرین پیام ارسالی:",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      messages.last,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      isPlayerTheQuestionWinner ? "(شما)" : "(حریف)",
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black45),
                    ),
                    if (messages.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "(${messages.length - 1} پیام قبلی)",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 30),
          const Divider(thickness: 1),
          const SizedBox(height: 20),

          // --- 💯 دکمه‌های پاسخ نهایی ---
          Text(
            isPlayerTheQuestionWinner
                ? "دکمه‌های نهایی برای قضاوت حریف فعال می‌شوند."
                : "آیا حریف جریمه را کامل کرده است؟",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // دکمه "انجام دادم" (سبز)
              ElevatedButton.icon(
                onPressed: enableAnswerButtons ? onAnswerCompleted : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("انجام دادم", style: TextStyle(fontSize: 17, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: completedColor,
                  disabledBackgroundColor: completedColor.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // دکمه "انجام ندادم" (قرمز)
              ElevatedButton.icon(
                onPressed: enableAnswerButtons ? onAnswerNotCompleted : null,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text("انجام ندادم", style: TextStyle(fontSize: 17, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: notCompletedColor,
                  disabledBackgroundColor: notCompletedColor.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}