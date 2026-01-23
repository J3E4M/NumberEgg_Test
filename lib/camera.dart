import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'database/egg_database.dart'; // 🔧 ปรับ path ให้ตรงโปรเจกต์คุณ
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
    // final request = http.MultipartRequest(
    //   'POST',
    //   Uri.parse(
    //       'http://localhost:8000/detect'), // 🔧 เปลี่ยน IP ถ้าใช้เครื่องจริง อันนี้ของ Web
    // );
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/detect'), // ✅ Emulator → Host
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

// ================== DISPLAY RESULT ==================
class DisplayPictureScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final List<Detection> detections;

  const DisplayPictureScreen({
    super.key,
    required this.imageBytes,
    required this.detections,
  });

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool isSaving = false;
  bool isSaved = false;

  Future<ui.Image> _loadImage() async {
    return decodeImageFromList(widget.imageBytes);
  }

  @override
  Widget build(BuildContext context) {
    final eggs = widget.detections.where((d) => d.cls == 0).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Result Store"),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== Image =====
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: FutureBuilder<ui.Image>(
                  future: _loadImage(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final image = snapshot.data!;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 🖼 รูป
                        Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.contain, // ✅ ภาพไม่โดน crop
                        ),

                        // 🔲 YOLO Bounding Box
                        CustomPaint(
                          painter: YoloPainter(
                            widget.detections,
                            Size(
                              image.width.toDouble(),
                              image.height.toDouble(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== Success Bar =====
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE082),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "การประมวลผล สำเร็จ\n${eggs.length} Eggs Scanned",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.info_outline),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== Detail =====
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "รายละเอียด",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ===== Egg List =====
            Expanded(
              child: ListView.builder(
                itemCount: eggs.length,
                itemBuilder: (context, index) {
                  final d = eggs[index];
                  final grade = _calculateGrade(d);

                  return EggResultCard(
                    index: index + 1,
                    grade: grade,
                    percent: d.confidence * 100,
                  );
                },
              ),
            ),

            // ===== Save Button =====
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: Text(
                  isSaving
                      ? "บันทึกแล้ว"
                      : isSaved
                          ? "บันทึกแล้ว"
                          : "Save to History",
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSaved ? Colors.grey : const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: (isSaving || isSaved)
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        await _saveToDatabase();
                        if (!mounted) return;
                        setState(() {
                          isSaving = false;
                          isSaved = true;
                        });
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _saveImageToLocal(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = "egg_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ================== SAVE TO SQLITE ==================
  Future<void> _saveToDatabase() async {
    debugPrint("START SAVE");

    int eggCount = 0;
    int successCount = 0;

    int bigCount = 0;
    int mediumCount = 0;
    int smallCount = 0;

    for (final d in widget.detections) {
      if (d.cls != 0) continue;

      eggCount++;

      final grade = _calculateGrade(d);

      switch (grade) {
        case 3:
          bigCount++;
          successCount++;
          break;
        case 2:
          mediumCount++;
          successCount++;
          break;
        case 1:
          smallCount++;
          successCount++;
          break;
        default:
          // grade 0 = ไม่ผ่าน
          break;
      }
    }

    if (eggCount == 0) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("ไม่พบไข่ในภาพ"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final successPercent = (successCount / eggCount) * 100;
    final imagePath = await _saveImageToLocal(widget.imageBytes);

    // ✅ INSERT SESSION (ได้ sessionId)
    final sessionId = await EggDatabase.instance.insertSession(
      imagePath: imagePath,
      eggCount: eggCount,
      successPercent: successPercent,
      bigCount: bigCount,
      mediumCount: mediumCount,
      smallCount: smallCount,
      day: DateTime.now().toIso8601String().substring(0, 10),
    );

    // ✅ INSERT EGG ITEMS
    for (final d in widget.detections) {
      if (d.cls != 0) continue;

      final grade = _calculateGrade(d);

      await EggDatabase.instance.insertEggItem(
        sessionId: sessionId,
        grade: grade,
        confidence: d.confidence * 100,
      );
    }

    debugPrint("SAVE DONE: $eggCount eggs");

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          "บันทึกผลตรวจไข่แล้ว $eggCount ฟอง "
          "(ใหญ่ $bigCount / กลาง $mediumCount / เล็ก $smallCount)",
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class EggResultCard extends StatelessWidget {
  final int index;
  final int grade;
  final double percent;

  const EggResultCard({
    super.key,
    required this.index,
    required this.grade,
    required this.percent,
  });

  String get gradeText {
    switch (grade) {
      case 3:
        return "ใหญ่ (เบอร์ 0)";
      case 2:
        return "กลาง (เบอร์ 1)";
      case 1:
        return "เล็ก (เบอร์ 2)";
      default:
        return "ไม่ผ่าน";
    }
  }

  IconData get gradeIcon {
    switch (grade) {
      case 3:
        return Icons.egg;
      case 2:
        return Icons.egg_alt;
      case 1:
        return Icons.egg_outlined;
      default:
        return Icons.close;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE082),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(gradeIcon, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Egg $index",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  gradeText,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${percent.toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }
}

int _calculateGrade(Detection d) {
  const cmPerPixel = 0.02;
  final widthCm = (d.x2 - d.x1) * cmPerPixel;

  if (widthCm >= 6.0) return 3; // ใหญ่
  if (widthCm >= 5.0) return 2; // กลาง
  if (widthCm >= 1.5) return 1; // เล็ก
  return 0; // ไม่ผ่าน
}

Color eggColor(double avgSize) {
  if (avgSize >= 6.0) {
    return Colors.green; // ไข่ใหญ่
  } else if (avgSize >= 5.0) {
    return Colors.orange; // ไข่กลาง
  } else if (avgSize >= 1.5) {
    return const Color.fromARGB(255, 255, 0, 0); // ไข่เล็ก
  } else {
    return Colors.red; // ไข่เล็ก
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

    for (final d in detections) {
      final widthPx = d.x2 - d.x1;
      final widthCm = widthPx * cmPerPixel;

      // 🎯 ใช้ logic เดียวกับ _calculateGrade
      Color boxColor;
      if (widthCm >= 6.0) {
        boxColor = Colors.green; // ใหญ่
      } else if (widthCm >= 5.0) {
        boxColor = Colors.orange; // กลาง
      } else {
        boxColor = Colors.red; // เล็ก
      }

      final paint = Paint()
        ..color = boxColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final rect = Rect.fromLTRB(
        d.x1 * scale + dx,
        d.y1 * scale + dy,
        d.x2 * scale + dx,
        d.y2 * scale + dy,
      );

      canvas.drawRect(rect, paint);

      for (final d in detections) {
        // 🔲 Bounding box
        final rect = Rect.fromLTRB(
          d.x1 * scale + dx,
          d.y1 * scale + dy,
          d.x2 * scale + dx,
          d.y2 * scale + dy,
        );

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
