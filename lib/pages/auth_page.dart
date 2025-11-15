import 'package:flutter/material.dart';
import '../services/appwrite_service.dart';
import 'package:appwrite/appwrite.dart';
import 'home_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final appwrite = AppwriteService();

  late TabController _tabController;

  // Login controllers
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  // Sign Up controllers
  final _signupUsername = TextEditingController();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPassword = TextEditingController();

  String msg = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ---------------- LOGIN ----------------
  Future<void> _login() async {
    setState(() {
      msg = "";
      isLoading = true;
    });

    try {
      await appwrite.account.createEmailPasswordSession(
        email: _loginEmail.text.trim(),
        password: _loginPassword.text,
      );

      final user = await appwrite.account.get();
      if (user.$id.isNotEmpty) {
        final playerName = user.name.isNotEmpty ? user.name : user.email;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(playerName: playerName)),
        );
      } else {
        setState(() => msg = "Login failed: Session not created");
      }
    } on AppwriteException catch (e) {
      setState(() => msg = "Login Error: ${e.message}");
    } catch (e) {
      setState(() => msg = "Login Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------- SIGN UP ----------------
  Future<void> _signup() async {
    setState(() {
      msg = "";
      isLoading = true;
    });

    try {
      await appwrite.account.create(
        userId: ID.unique(),
        email: _signupEmail.text.trim(),
        password: _signupPassword.text,
      );

      await appwrite.account.createEmailPasswordSession(
        email: _signupEmail.text.trim(),
        password: _signupPassword.text,
      );

      final user = await appwrite.account.get();
      if (user.$id.isEmpty) {
        setState(() => msg = "Sign Up Error: Session not created");
        return;
      }

      // اضافه کردن به دیتابیس
      await appwrite.databases.createDocument(
        databaseId: 'jamal1_',
        collectionId: 'users',
        documentId: ID.unique(),
        data: {
          'username': _signupUsername.text.trim(),
          'email': _signupEmail.text.trim(),
          'name': _signupName.text.trim(),
        },
      );

      final playerName = _signupName.text.trim().isNotEmpty
          ? _signupName.text.trim()
          : _signupUsername.text.trim();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(playerName: playerName)),
      );
    } on AppwriteException catch (e) {
      setState(() => msg = "Appwrite Error: ${e.message}");
    } catch (e) {
      setState(() => msg = "Sign Up Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  // 📝 ویجت سفارشی برای TextField با بوردر تمیز
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        // 🖼️ استایل بوردر تمیز و گرد
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue.shade600) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
        textAlign: TextAlign.left, // معمولاً برای ایمیل و پسورد راست به چپ نیست
      ),
    );
  }

  // 🚀 ویجت سفارشی دکمه
  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // 🖼️ بوردر گرد
          ),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("احراز هویت", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue.shade200,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "ورود"),
            Tab(text: "ثبت نام"),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // ---------------- Login Tab (ورود) ----------------
              SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _loginEmail,
                      labelText: "ایمیل",
                      icon: Icons.email,
                    ),
                    _buildTextField(
                      controller: _loginPassword,
                      labelText: "رمز عبور",
                      icon: Icons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),
                    _buildActionButton("ورود", _login),
                    const SizedBox(height: 25),
                    if (msg.isNotEmpty)
                      Text(msg, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              // ---------------- Sign Up Tab (ثبت نام) ----------------
              SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _signupUsername,
                      labelText: "نام کاربری",
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      controller: _signupName,
                      labelText: "نام (اختیاری)",
                      icon: Icons.badge_outlined,
                    ),
                    _buildTextField(
                      controller: _signupEmail,
                      labelText: "ایمیل",
                      icon: Icons.email_outlined,
                    ),
                    _buildTextField(
                      controller: _signupPassword,
                      labelText: "رمز عبور",
                      icon: Icons.lock_open_outlined,
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),
                    _buildActionButton("ثبت نام", _signup),
                    const SizedBox(height: 25),
                    if (msg.isNotEmpty)
                      Text(msg, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),

          // 🔄 نمایش لودینگ
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}