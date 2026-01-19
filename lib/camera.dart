import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

const List<String> yoloClasses = [
  "egg", // class 0
  // เพิ่ม class อื่นได้
];

/// ================== MODEL ==================
class Detection {
  final double x1, y1, x2, y2;
  final double confidence;
  final int cls;

  Detection.fromJson(Map<String, dynamic> json)
      : x1 = (json['x1'] as num).toDouble(),
        y1 = (json['y1'] as num).toDouble(),
        x2 = (json['x2'] as num).toDouble(),
        y2 = (json['y2'] as num).toDouble(),
        confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0,
        cls = (json['class'] as num?)?.toInt() ?? 0; // ⭐ กัน null
}

/// ================== MAIN ==================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
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
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'http://localhost:8000/detect'), // 🔧 เปลี่ยน IP ถ้าใช้เครื่องจริง
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final jsonData = jsonDecode(body);

    return (jsonData['detections'] as List)
        .map((e) => Detection.fromJson(e))
        .toList();
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DisplayPictureScreen(
            imageBytes: bytes,
            detections: detections,
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
class DisplayPictureScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final List<Detection> detections;

  const DisplayPictureScreen({
    super.key,
    required this.imageBytes,
    required this.detections,
  });

  Future<ui.Image> _loadImage() async {
    return decodeImageFromList(imageBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Result")),
      body: FutureBuilder<ui.Image>(
        future: _loadImage(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final image = snapshot.data!;
          final imageSize =
              Size(image.width.toDouble(), image.height.toDouble());

          return Column(
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                        ),
                        CustomPaint(
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                          painter: YoloPainter(
                            detections,
                            imageSize, // ✅ ใช้ขนาดภาพจริง
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "พบวัตถุทั้งหมด: ${detections.length}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ================== YOLO PAINTER ==================
class YoloPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize; // เช่น 640x640

  // ⭐ เพิ่มตรงนี้
  final double cmPerPixel = 0.02; // ปรับตามการวัดจริง

  YoloPainter(this.detections, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / imageSize.width,
      size.height / imageSize.height,
    );

    final dx = (size.width - imageSize.width * scale) / 2;
    final dy = (size.height - imageSize.height * scale) / 2;

    final boxPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final d in detections) {
      // 🔲 Bounding box
      final rect = Rect.fromLTRB(
        d.x1 * scale + dx,
        d.y1 * scale + dy,
        d.x2 * scale + dx,
        d.y2 * scale + dy,
      );

      canvas.drawRect(rect, boxPaint);

      // 📐 คำนวณขนาด
      final widthPx = d.x2 - d.x1;
      final heightPx = d.y2 - d.y1;

      final widthCm = widthPx * cmPerPixel;
      final heightCm = heightPx * cmPerPixel;

      // 🏷 Label + confidence + size
      final className = d.cls >= 0 && d.cls < yoloClasses.length
          ? yoloClasses[d.cls]
          : 'Unknown';

      final label = "$className ${(d.confidence * 100).toStringAsFixed(1)}%\n"
          "${widthCm.toStringAsFixed(1)} x ${heightCm.toStringAsFixed(1)} cm";

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // 📍 วาด label เหนือกรอบ
      final labelOffset = Offset(
        rect.left,
        rect.top - textPainter.height - 4,
      );

      textPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
