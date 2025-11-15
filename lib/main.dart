import 'package:flutter/material.dart';
import 'pages/auth_page.dart';
import 'pages/home_screen.dart';
import 'services/appwrite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appwrite = AppwriteService();
  final loggedIn = await appwrite.isLoggedIn();
  String? playerName;

  if (loggedIn) {
    try {
      final user = await appwrite.account.get();
      playerName = user.name.isNotEmpty ? user.name : user.email;
    } catch (e) {
      // اگر خطا در گرفتن کاربر بود، به AuthPage می‌رود
      playerName = null;
    }
  }

  runApp(MyApp(loggedIn: loggedIn, playerName: playerName));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;
  final String? playerName;

  const MyApp({super.key, required this.loggedIn, this.playerName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Appwrite Windows',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'DigiHamishe', // فونت سراسری
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'DigiHamishe'),
          bodyMedium: TextStyle(fontFamily: 'DigiHamishe'),
          bodySmall: TextStyle(fontFamily: 'DigiHamishe'),
        ),
      ),
      // نمایش صفحه اول بر اساس وضعیت ورود
      home: loggedIn && playerName != null
          ? HomeScreen(playerName: playerName!)
          : const AuthPage(),
    );
  }
}
