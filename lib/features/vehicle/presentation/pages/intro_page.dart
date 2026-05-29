import 'package:flutter/material.dart';
import './show_room_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            // 使用 pushReplacement 來替換當前頁面，避免返回到介紹頁面
            context,
            MaterialPageRoute(builder: (context) => const ShowRoomPage()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/intro_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          height: double.infinity,
        ),
      ),
    );
  }
}
