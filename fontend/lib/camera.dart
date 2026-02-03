import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'database/egg_database.dart'; // 🔧 ปรับ path ให้ตรงโปรเจกต์คุณ
import 'utils/server_config.dart';
import 'DisplayPictureScreen.dart'; // Import DisplayPictureScreen ที่สมบูรณ์

const List<String> yoloClasses = [
  "egg", // class 0
  // เพิ่ม class อื่นได้
];

/// ================== MODEL ==================
class Detection {
  final double x1, y1, x2, y2;
  final double confidence;
  final int cls;
  final String? className;
  final int? grade; // Add grade property

  Detection.fromJson(Map<String, dynamic> json)
      : x1 = (json['x1'] as num).toDouble(),
        y1 = (json['y1'] as num).toDouble(),
        x2 = (json['x2'] as num).toDouble(),
        y2 = (json['y2'] as num).toDouble(),
        confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0,
        cls = (json['class_id'] as num?)?.toInt() ?? (json['class'] as num?)?.toInt() ?? 0,
        className = json['class_name'] as String?,
        grade = (json['class_id'] as num?)?.toInt() ?? (json['class'] as num?)?.toInt() ?? 0; // Use class_id as grade

  // Add toJson method for DisplayPictureScreen
  Map<String, dynamic> toJson() {
    return {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
      'confidence': confidence,
      'class_id': cls,
      'class_name': className,
      'grade': grade, // Include grade in JSON
    };
  }
}

/// ================== MAIN ==================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey, // ⭐ เพิ่ม
      debugShowCheckedModeBanner: false,
      home: SelectImageScreen(),
    );
  }
}

/// ================== SELECT IMAGE SCREEN ==================
class SelectImageScreen extends StatefulWidget {
  const SelectImageScreen({super.key});

  @override
  State<SelectImageScreen> createState() => _SelectImageScreenState();
}

class _SelectImageScreenState extends State<SelectImageScreen> {
  bool isLoading = false;

  /// 🔥 ส่งรูปไป YOLO
  Future<List<Detection>> sendToYolo(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      // ใช้ ServerConfig เพื่อดึง URL จาก config
      final baseUrl = await ServerConfig.getApiUrl();
      final url = Uri.parse('$baseUrl/detect');
      
      debugPrint('Sending request to: $url');
      
      final request = http.MultipartRequest('POST', url);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      // เพิ่ม headers สำหรับ debugging
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'NumberEgg-Flutter-App',
      });

      final response = await request.send();
      debugPrint('Response status code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception('API Error: ${response.statusCode} - $errorBody');
      }
      
      final body = await response.stream.bytesToString();
      debugPrint('Response body: $body');
      
      final jsonData = jsonDecode(body);
      
      // จัดการกับ response format ที่แตกต่างกัน
      List<dynamic> detectionsList;
      if (jsonData['detections'] != null) {
        detectionsList = jsonData['detections'] as List;
      } else if (jsonData['eggs'] != null) {
        detectionsList = jsonData['eggs'] as List;
      } else {
        detectionsList = [];
      }
      
      return detectionsList
          .map((e) => Detection.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error in sendToYolo: $e');
      rethrow;
    }
  }

  /// 📁 เลือกรูปจากเครื่อง
  Future<void> pickImage() async {
    try {
      setState(() => isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // ⭐ สำคัญมาก (Web ต้องใช้)
      );

      if (result == null) return;

      final bytes = result.files.single.bytes!;
      final fileName = result.files.single.name;

      final detections = await sendToYolo(bytes, fileName);

      if (!mounted) return;

      // แสดง debug info
      debugPrint('Found ${detections.length} detections');
      for (int i = 0; i < detections.length; i++) {
        final d = detections[i];
        debugPrint('Detection $i: class=${d.className ?? d.cls}, confidence=${d.confidence}');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DisplayPictureScreen(
            imagePath: fileName, // ใช้ชื่อไฟล์จริง
            detections: detections, // detections ไม่ใช่ optional
            imageBytes: bytes,
            railwayResponse: {
              'count': detections.length,
              'detections': detections.map((d) => d.toJson()).toList()
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint("Pick image error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/number_egg_logo.png',
                    width: 250,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text(
                      "เลือกรูปจากเครื่อง",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// ================== DISPLAY RESULT ==================
// ใช้ DisplayPictureScreen จาก DisplayPictureScreen.dart แทน
