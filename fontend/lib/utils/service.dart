// ยูทิลิตีสร้างปุ่มสำหรับการนำทาง (ไม่ได้ใช้ในปัจจุบัน)
import 'package:flutter/material.dart';

// ฟังก์ชันสร้างปุ่มสำหรับไปหน้าอื่น
Widget btnPage(BuildContext context, String text, String route) {
  return ElevatedButton(
    child: Text(text),
    onPressed: () {
      Navigator.pushNamed(context, route);
    },
  );
}