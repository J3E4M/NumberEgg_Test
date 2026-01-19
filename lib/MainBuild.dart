import 'package:flutter/material.dart';

import '/MainPage.dart';
import '/Login.dart';
import '/Register.dart';
import '/camera.dart';
import '/HomePage.dart';
import '/ProfilePage.dart';
import '/HistoryPage.dart';
import '/ResultPage.dart';

void main() {
  runApp(const LinkPage());
}

class LinkPage extends StatelessWidget {
  const LinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/camera': (context) => const TakePictureScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/member': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/history': (context) => const HistoryPage(),
        '/result': (context) => const ResultPage(),
      },
    );
  }
}
