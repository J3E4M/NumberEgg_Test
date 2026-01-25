import 'package:flutter/material.dart';

import '/MainPage.dart';
import '/ProfileSettingPage.dart';
import '/camera.dart';
import '/HomePage.dart';
import '/ProfilePage.dart';
import '/HistoryPage.dart';
import '/ResultPage.dart';
import '/Login.dart';
import '/Register.dart';

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
        '/': (context) => MainPage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/camera': (context) => const TakePictureScreen(),
        '/member': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/history': (context) => const HistoryPage(),
        '/result': (context) => const ResultPage(),
      },
    );
  }
}
