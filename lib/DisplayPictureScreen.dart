import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera.dart'; // Import Detection class
import 'database/egg_database.dart'; // Import egg database

// --- หน้าแสดงผลและ Save หลังจากถ่ายภาพ ---
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final List<Detection> detections; // รับค่าผลลัพธ์จากหน้า Camera

  const DisplayPictureScreen({
    Key? key,
    required this.imagePath,
    this.detections = const [], // ค่า default ว่าง
  }) : super(key: key);

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool isSaving = false;
  ui.Image? _decodedImage;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _decodedImage = frame.image; // Get the actual image from FrameInfo
      if (mounted) setState(() {});
    } catch (e) {
      print('Error decoding image: $e');
    }
  }

  @override 
  Widget build(BuildContext context) {
    const Color cardBgColor = Color(0xFFFFE082); 
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Result Store", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Original image
                        Image.file(
                          File(widget.imagePath), 
                          fit: BoxFit.cover, 
                          height: 300, 
                          width: double.infinity
                        ),
                        // Detection overlay
                        if (widget.detections.isNotEmpty && _decodedImage != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DetectionOverlayPainter(
                                detections: widget.detections,
                                imageWidth: _decodedImage!.width.toDouble(),
                                imageHeight: _decodedImage!.height.toDouble(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBgColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.detections.isNotEmpty ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.detections.isNotEmpty ? Icons.check : Icons.search,
                            color: Colors.white, 
                            size: 20
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.detections.isNotEmpty ? "การประมวลผล สำเร็จ" : "ไม่พบไข่",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              widget.detections.isNotEmpty 
                                ? "พบไข่ไก่จำนวน ${widget.detections.length} ฟอง"
                                : "ไม่พบการตรวจจับในภาพ",
                              style: TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Text(
                    "รายละเอียด",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  // แสดงรายการไข่ที่ตรวจพบจริง
                  if (widget.detections.isNotEmpty)
                    ...widget.detections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final detection = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildDetectionResultItem(
                          title: "Egg ${index + 1}",
                          detection: detection,
                        ),
                      );
                    }).toList()
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_off, color: Colors.grey.shade400, size: 40),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ไม่พบไข่ในภาพ",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  "ลองถ่ายภาพใหม่ในมุมที่ชัดเจนกว่านี้",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveImageToGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                child: isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Save to History",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.download, color: Colors.white),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionResultItem({
    required String title,
    required Detection detection,
  }) {
    // แปลงขนาดไข่เป็นชื่อและสี
    Map<String, dynamic> eggDetails = _getEggDetails(detection.eggSize);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE082).withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.egg, color: eggDetails['color'], size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  eggDetails['name'],
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "ความมั่นใจ: ${(detection.confidence * 100).toStringAsFixed(1)}%",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันช่วยแปลงขนาดไข่เป็นชื่อและสี
  Map<String, dynamic> _getEggDetails(String sizeKey) {
    switch (sizeKey) {
      case 'ใหญ่':
        return {
          'name': 'ใหญ่ (เบอร์ 0)',
          'color': Colors.green
        };
      case 'กลาง':
        return {
          'name': 'กลาง (เบอร์ 1)',
          'color': Colors.amber
        };
      case 'เล็ก':
        return {'name': 'เล็ก (เบอร์ 2-3)', 'color': Colors.orange};
      default:
        return {'name': sizeKey, 'color': Colors.grey};
    }
  }

  Future<void> saveImageToGallery() async {
    setState(() { isSaving = true; });
    try {
      var status = await Permission.storage.request();
      if (status.isDenied) {
        status = await Permission.photos.request();
      }

      if (status.isGranted || await Permission.storage.isGranted || await Permission.photos.isGranted) {
        final Directory? directory = await getExternalStorageDirectory();
        if (directory != null) {
          String newPath = "";
          if (Platform.isAndroid) {
             newPath = "/storage/emulated/0/DCIM/Camera"; 
             final dir = Directory(newPath);
             if (!dir.existsSync()) {
               newPath = directory.path; 
             }
          } else {
            newPath = directory.path;
          }

          String fileName = "Egg_${DateTime.now().millisecondsSinceEpoch}.jpg";
          String fullPath = "$newPath/$fileName";
          
          await File(widget.imagePath).copy(fullPath);

          // บันทึกข้อมูลการตรวจจับลงฐานข้อมูล
          await _saveDetectionToDatabase(fullPath);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('บันทึกรูปภาพเรียบร้อย: $fileName'), 
                backgroundColor: const Color.fromARGB(255, 201, 146, 26)
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาอนุญาตให้เข้าถึงรูปภาพ'), backgroundColor: Colors.red),
          );
        }
        openAppSettings();
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() { isSaving = false; });
    }
  }

  Future<void> _saveDetectionToDatabase(String savedImagePath) async {
    try {
      // สร้าง tags จาก detections
      List<String> tags = [];
      Map<String, int> sizeCount = {};
      
      for (final detection in widget.detections) {
        sizeCount[detection.eggSize] = (sizeCount[detection.eggSize] ?? 0) + 1;
      }
      
      // แปลงเป็นรูปแบบ "2xใหญ่"
      for (final entry in sizeCount.entries) {
        tags.add("${entry.value}x${entry.key}");
      }
      
      // คำนวณข้อมูลสำหรับ database
      final eggCount = widget.detections.length;
      final successPercent = eggCount > 0 ? 100.0 : 0.0;
      final bigCount = sizeCount['ใหญ่'] ?? 0;
      final mediumCount = sizeCount['กลาง'] ?? 0;
      final smallCount = sizeCount['เล็ก'] ?? 0;
      
      // สร้าง egg session
      final sessionId = await EggDatabase.instance.insertSession(
        imagePath: savedImagePath,
        eggCount: eggCount,
        successPercent: successPercent,
        bigCount: bigCount,
        mediumCount: mediumCount,
        smallCount: smallCount,
        day: DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
      );
      
      // บันทึกรายละเอียดไข่แต่ละอัน
      for (int i = 0; i < widget.detections.length; i++) {
        final detection = widget.detections[i];
        await EggDatabase.instance.insertEggItem(
          sessionId: sessionId,
          grade: _getGradeFromSize(detection.eggSize),
          confidence: detection.confidence,
          x1: detection.x1,
          y1: detection.y1,
          x2: detection.x2,
          y2: detection.y2,
        );
      }
      
      print('Saved egg session to database: $sessionId');
    } catch (e) {
      print('Error saving to database: $e');
    }
  }

  // แปลงขนาดไข่เป็นเกรด
  int _getGradeFromSize(String size) {
    switch (size) {
      case 'ใหญ่':
        return 0; // เบอร์ 0
      case 'กลาง':
        return 1; // เบอร์ 1
      case 'เล็ก':
        return 2; // เบอร์ 2-3
      default:
        return 3; // อื่นๆ
    }
  }
}

/// Custom painter to draw detection bounding boxes and labels
class DetectionOverlayPainter extends CustomPainter {
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;

  DetectionOverlayPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final labelPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];
      
      // Scale coordinates to fit the image display size
      final scaleX = size.width / imageWidth;
      final scaleY = size.height / imageHeight;
      
      final rect = Rect.fromLTRB(
        detection.x1 * scaleX,
        detection.y1 * scaleY,
        detection.x2 * scaleX,
        detection.y2 * scaleY,
      );

      // Draw bounding box
      canvas.drawRect(rect, paint);

      // Draw label background
      final labelText = 'Egg ${i + 1}';
      textPainter.text = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      final textWidth = textPainter.width;
      final textHeight = textPainter.height;
      
      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - textHeight - 4,
        textWidth + 8,
        textHeight + 4,
      );
      
      // Draw label background
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        labelPaint,
      );
      
      // Draw label text
      textPainter.paint(
        canvas,
        Offset(rect.left + 4, rect.top - textHeight - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant oldDelegate) => false;
}
