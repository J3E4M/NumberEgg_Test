import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_software_development/MainPage.dart';
import 'package:mobile_software_development/Login.dart';
import 'package:mobile_software_development/Register.dart';
import 'package:mobile_software_development/camera.dart'; 
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
        //'/member': (context) => const MemberPage(),
      },
    );
  }
}
