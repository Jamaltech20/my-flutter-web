import 'dart:math';
import 'package:flutter/material.dart';

class NumberWheelPage extends StatefulWidget {
  final int number;
  final String playerName;
  final String opponentName;
  final String documentId;

  const NumberWheelPage({
    super.key,
    required this.number,
    required this.playerName,
    required this.opponentName,
    required this.documentId,
  });

  @override
  State<NumberWheelPage> createState() => _NumberWheelPageState();
}

class _NumberWheelPageState extends State<NumberWheelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    animation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("گردونه عددی")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (_, child) => Transform.rotate(
                angle: animation.value,
                child: child,
              ),
              child: Image.asset("assets/wheel.png", width: 250),
            ),
            const SizedBox(height: 30),
            Text(
              "عدد انتخاب شده: ${widget.number}",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
