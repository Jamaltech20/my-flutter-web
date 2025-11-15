import 'dart:async';
import 'package:flutter/material.dart';
import '../services/appwrite_service.dart';

class ChatHistoryPage extends StatefulWidget {
  final String? currentChatHistory;
  final String documentId;
  final String currentPlayerName;
  // ✅ فیلد جدید: شمارنده فعلی پیام‌های نخوانده
  final int initialUnreadCount;

  const ChatHistoryPage({
    super.key,
    required this.currentChatHistory,
    required this.documentId,
    required this.currentPlayerName,
    required this.initialUnreadCount, // ✅ دریافت شمارنده اولیه
  });

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final TextEditingController _newResponseController = TextEditingController();
  final AppwriteService appwrite = AppwriteService();
  static const String DATABASE_ID = "jamal1_";
  static const String COLLECTION_ID = "rooms";
  static const String CHAT_FIELD_NAME = "chatHistory";

  String? _localChatHistory;
  bool _isSending = false;

  // ✅ متغیر محلی برای نگه داشتن شمارنده در طول عمر صفحه چت
  int _localUnreadCount = 0;

  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _localChatHistory = widget.currentChatHistory;
    _localUnreadCount = widget.initialUnreadCount; // تنظیم شمارنده اولیه

    // ✅ صفر کردن شمارنده پیام‌های نخوانده هنگام ورود به صفحه
    _resetUnreadCount();

    // ✅ مشترک شدن در تغییرات سند اتاق (Real-time Subscription)
    _subscription = appwrite.realtime.subscribe([
      'databases.$DATABASE_ID.collections.$COLLECTION_ID.documents.${widget.documentId}',
    ]).stream.listen((response) {

      if (response.events.contains('databases.*.collections.*.documents.*.update')) {

        final newHistory = response.payload[CHAT_FIELD_NAME] as String? ?? "";
        final newCount = response.payload["unreadMessageCount"] as int? ?? 0; // دریافت شمارنده جدید

        // به‌روزرسانی UI در صورت تغییر تاریخچه چت
        if (newHistory != _localChatHistory) {
          if (mounted) {
            setState(() {
              _localChatHistory = newHistory;
              // ⚠️ مهم: چون کاربر در این صفحه است، شمارنده باید صفر بماند.
            });
          }
        }
      }
    });
  }

  // ✅ متد صفر کردن شمارنده
  Future<void> _resetUnreadCount() async {
    try {
      // این متد بلافاصله پس از ورود، شمارنده را صفر می‌کند.
      await appwrite.databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: COLLECTION_ID,
        documentId: widget.documentId,
        data: {
          "unreadMessageCount": 0,
        },
      );
      // نیازی به setState نیست چون Real-time Listener تغییر را دریافت می‌کند.
      _localUnreadCount = 0;
    } catch (e) {
      print("Error resetting unread count: $e");
    }
  }

  Future<void> _sendNewMessage() async {
    if (_isSending) return;

    final responseText = _newResponseController.text.trim();
    if (responseText.isEmpty || responseText.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("پیام باید بین ۱ تا ۵۰ حرف باشد.")),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final currentHistory = _localChatHistory ?? "";
      final messageWithSender = "[${widget.currentPlayerName}] $responseText";

      final newHistory = currentHistory.isEmpty
          ? messageWithSender
          : "$currentHistory\n$messageWithSender";

      // ✅ افزایش شمارنده هنگام ارسال پیام
      // این افزایش باعث می‌شود بازیکن دیگر که در صفحه بازی است، نوتیفیکیشن را ببیند.
      await appwrite.databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: COLLECTION_ID,
        documentId: widget.documentId,
        data: {
          CHAT_FIELD_NAME: newHistory,
          // افزایش شمارنده به اضافه ۱
          "unreadMessageCount": widget.initialUnreadCount + 1,
        },
      );

    } catch (e) {
      print("Error sending message from chat history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطا در ارسال پیام.")),
      );
    } finally {
      _newResponseController.clear();
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _newResponseController.dispose();
    _subscription.cancel();
    super.dispose();
  }

  // 💬 ویجت سفارشی حباب پیام (Chat Bubble)
  Widget _buildMessageBubble(String senderName, String content, bool isUserMessage) {
    final String displaySender = isUserMessage ? "شما" : senderName;

    // 💡 رنگ‌های بسیار ساده و تمیز
    final Color messageColor = isUserMessage
        ? Colors.blue.shade50
        : Colors.grey.shade100;

    final Alignment alignment = isUserMessage
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final CrossAxisAlignment crossAxisAlignment = isUserMessage
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    final Color senderColor = isUserMessage
        ? Colors.blue.shade700
        : Colors.grey.shade700;
        
    // 🖼️ تعریف حاشیه‌های گرد دقیق‌تر (Border Radius)
    final BorderRadius borderRadius = BorderRadius.circular(12).copyWith(
      topLeft: isUserMessage ? const Radius.circular(12) : const Radius.circular(2),
      bottomRight: isUserMessage ? const Radius.circular(2) : const Radius.circular(12),
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        margin: const EdgeInsets.only(bottom: 10.0),
        decoration: BoxDecoration(
          color: messageColor,
          borderRadius: borderRadius,
          // 📦 بوردر نازک و ملایم برای تمیزی
          border: Border.all(
            color: isUserMessage ? Colors.blue.shade100 : Colors.grey.shade300,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 3,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Text(
              "$displaySender",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: senderColor,
              ),
              textAlign: isUserMessage ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 5),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> messages = _localChatHistory != null
        ? _localChatHistory!.split('\n').where((s) => s.isNotEmpty).toList()
        : [];

    final bool hasMessages = messages.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 🎨 پس زمینه روشن و تمیز
      appBar: AppBar(
        title: const Text("💬 چت عمومی بازی", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // ✅ بستن صفحه و برگرداندن تاریخچه چت نهایی
            Navigator.pop(context, _localChatHistory);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: hasMessages
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
                    itemCount: messages.length,
                    reverse: true, // نمایش جدیدترین پیام‌ها در پایین
                    itemBuilder: (context, index) {
                      final fullMessage = messages[messages.length - 1 - index];

                      String senderName = "ناشناس";
                      String content = fullMessage;

                      if (fullMessage.startsWith('[') && fullMessage.contains('] ')) {
                        int endBracket = fullMessage.indexOf(']');
                        senderName = fullMessage.substring(1, endBracket);
                        content = fullMessage.substring(endBracket + 2);
                      } else {
                        content = fullMessage;
                        senderName = "سیستم";
                      }

                      final isUserMessage = senderName == widget.currentPlayerName;

                      return _buildMessageBubble(senderName, content, isUserMessage);
                    },
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Text(
                        "هنوز پیامی ارسال نشده است.\nاولین پیام را بفرستید!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                      ),
                    ),
                  ),
          ),

          // 📏 خط جداکننده برای تمیزی UI
          const Divider(height: 1, color: Colors.grey),

          // بخش ارسال پیام
          Container(
            color: Colors.white, // پس‌زمینه سفید برای بخش ورودی
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _newResponseController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: "ارسال پیام جدید...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Colors.grey.shade50,
                      filled: true,
                      // 🖼️ بوردر تمیز و گرد
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none, // حذف بوردر پیش‌فرض
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.indigo.shade700, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      counterText: "",
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    enabled: !_isSending,
                    // ✏️ راست به چپ برای تایپ فارسی
                    textAlign: TextAlign.right, 
                  ),
                ),
                const SizedBox(width: 8),
                // 🚀 دکمه ارسال با سایز و رنگ مناسب
                Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: ShapeDecoration(
                      color: Colors.indigo.shade700,
                      shape: const CircleBorder(),
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendNewMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                      padding: const EdgeInsets.all(10),
                      splashRadius: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}