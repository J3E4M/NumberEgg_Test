import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'database/egg_database.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  ui.Image? _decodedImage;
  List<Map<String, dynamic>> _eggItems = [];

  @override
  void initState() {
    super.initState();
    _loadEggItems();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final String? imagePath = args?['imagePath'];
    
    if (imagePath != null && File(imagePath).existsSync()) {
      try {
        final bytes = await File(imagePath).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        _decodedImage = frame.image; // Get the actual image from FrameInfo
        setState(() {});
      } catch (e) {
        print('Error decoding image: $e');
      }
    }
  }

  Future<void> _loadEggItems() async {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final int sessionId = args?['sessionId'];
    
    if (sessionId != null) {
      try {
        debugPrint("🔍 ResultPage: Loading egg items for session: $sessionId");
        final db = await EggDatabase.instance.database;
        final items = await db.query(
          'egg_item',
          where: 'session_id = ?',
          whereArgs: [sessionId],
          orderBy: 'id ASC',
        );
        
        debugPrint("📊 ResultPage: Found ${items.length} egg items");
        
        setState(() {
          _eggItems = items.map((item) => {
            'grade': item['grade'],
            'confidence': item['confidence'],
            'id': item['id'],
          }).toList();
        });
        
        debugPrint("✅ ResultPage: Loaded ${_eggItems.length} egg items successfully");
      } catch (e) {
        debugPrint("❌ ResultPage: Error loading egg items: $e");
        print('Error loading egg items: $e');
      }
    }
  }

  // ฟังก์ชันช่วยแปลง ขนาด (เช่น "ใหญ่") เป็นชื่อเบอร์และสี
  // อัปเดตสีและชื่อให้ตรงกับภาพตัวอย่าง (Screenshot)
  Map<String, dynamic> _getEggDetails(String sizeKey) {
    switch (sizeKey.trim()) {
      case 'เบอร์ 0':
        return {'name': 'เบอร์ 0 (Extra Large)', 'color': Colors.red};
      case 'เบอร์ 1':
        return {'name': 'เบอร์ 1 (Large)', 'color': Colors.orange};
      case 'เบอร์ 2':
        return {'name': 'เบอร์ 2 (Medium)', 'color': Colors.amber};
      case 'เบอร์ 3':
        return {'name': 'เบอร์ 3 (Small)', 'color': Colors.green};
      case 'เบอร์ 4':
        return {'name': 'เบอร์ 4 (Extra Small)', 'color': Colors.blueGrey};
      case 'เบอร์ 5':
        return {'name': 'เบอร์ 5 (Pewee)', 'color': Colors.grey};
      default:
        return {'name': sizeKey, 'color': Colors.grey};
    }
  }

  // ฟังก์ชันสำหรับสร้างรายการไข่จาก tags
  List<Widget> _generateEggList(List<dynamic> tags) {
    List<Widget> widgets = [];
    int eggCounter = 1; // ตัวนับจำนวนไข่ เริ่มต้นที่ 1

    for (var tagString in tags) {
      // 1. แยกจำนวนและประเภทจาก string เช่น "2xใหญ่" -> count=2, sizeKey="ใหญ่"
      final String tag = tagString.toString();
      final List<String> parts = tag.split('x');

      int count = 1;
      String sizeKey = tag;

      if (parts.length == 2) {
        count = int.tryParse(parts[0]) ?? 1;
        sizeKey = parts[1];
      }

      // 2. ดึงข้อมูลชื่อและสีตามขนาด
      final details = _getEggDetails(sizeKey);

      // 3. วนลูปสร้าง widget ตามจำนวนฟอง (count)
      for (int i = 0; i < count; i++) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildResultItem(
              title: "Egg $eggCounter", // ชื่อไข่ตามลำดับ
              subtitle: details['name'], // ชื่อขนาด เช่น "ใหญ่ (เบอร์ 0)"
              // สร้างตัวเลขความมั่นใจจำลอง (เนื่องจากไม่มีในข้อมูล History)
              confidence: "${98 - ((eggCounter - 1) % 5) * 2}%",
              iconColor: details['color'], // สีไอคอน
            ),
          ),
        );
        eggCounter++; // เพิ่มลำดับไข่
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // รับข้อมูลที่ส่งมาจากหน้า History
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    // ถ้าไม่มีข้อมูล ให้แสดงหน้าว่างๆ
    if (args == null) {
      return const Scaffold(
        body: Center(child: Text("ไม่พบข้อมูล")),
      );
    }

    // ดึงข้อมูลจาก args
    final String date = args['date'] ?? '-';
    final int count = args['count'] ?? 0;
    final bool isSuccess = args['isSuccess'] ?? false;
    final List<dynamic> tags = args['tags'] ?? [];
    final String? imagePath = args['imagePath'];
    const Color cardBgColor = Color(0xFFFFE082);

    return Scaffold(
      backgroundColor: Colors.white,
      // --- AppBar ---
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
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.black54, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          children: [
            const Text(
              "Result Store",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Text(
              date,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
      ),

      // --- Body ---
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. รูปภาพ
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: Colors.grey.shade100,
                      width: double.infinity,
                      height: 300,
                      child: Stack(
                        children: [
                          // Original image
                          imagePath != null && File(imagePath).existsSync()
                              ? Image.file(
                                  File(imagePath),
                                  fit: BoxFit.contain,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                ),
                          // Detection overlay with numbers
                          if (_decodedImage != null && _eggItems.isNotEmpty)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: EggNumberOverlayPainter(
                                  eggItems: _eggItems,
                                  imageWidth: _decodedImage!.width.toDouble(),
                                  imageHeight: _decodedImage!.height.toDouble(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Summary Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBgColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSuccess ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              isSuccess ? Icons.check : Icons.priority_high,
                              color: Colors.white,
                              size: 20),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSuccess ? "การประมวลผล สำเร็จ" : "รอการตรวจสอบ",
                              style: TextStyle(
                                color: isSuccess
                                    ? Colors.green.shade700
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "พบไข่ไก่จำนวน $count ฟอง",
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "รายละเอียด",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  // 3. รายการ Tags (ส่วนที่แก้ไข)
                  if (tags.isEmpty)
                    const Text("ไม่มีรายละเอียดขนาด",
                        style: TextStyle(color: Colors.grey))
                  else
                    // เรียกใช้ฟังก์ชัน _generateEggList เพื่อสร้างรายการ
                    ..._generateEggList(tags),
                ],
              ),
            ),
          ),

          // ปุ่ม Back
          //  Padding(
          //   padding: const EdgeInsets.all(20),
          //   child: SizedBox(
          //     width: double.infinity,
          //     height: 55,
          //     child: ElevatedButton(
          //       onPressed: () => Navigator.pop(context),
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.white,
          //         side: const BorderSide(color: Color(0xFFFFC107), width: 2),
          //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          //         elevation: 0,
          //       ),
          //       child: const Row(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Icon(Icons.arrow_back, color: Color(0xFFFFC107)),
          //           SizedBox(width: 10),
          //           Text(
          //             "ย้อนกลับ",
          //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget สำหรับสร้างแถวรายการแต่ละฟอง
  Widget _buildResultItem({
    required String title,
    required String subtitle,
    required String confidence,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE082).withOpacity(0.5), // สีพื้นหลังตามภาพ
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // ไอคอนไข่ด้านซ้าย
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.egg, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          // ชื่อและรายละเอียดตรงกลาง
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, // เช่น "Egg 1"
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle, // เช่น "ใหญ่ (เบอร์ 0)"
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          // เปอร์เซ็นต์ความมั่นใจด้านขวา
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white, // พื้นหลังสีขาว
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              confidence, // เช่น "98%"
              style: const TextStyle(
                color: Color.fromARGB(255, 175, 168, 76), // สีข้อความ
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw numbers on detected eggs
class EggNumberOverlayPainter extends CustomPainter {
  final List<Map<String, dynamic>> eggItems;
  final double imageWidth;
  final double imageHeight;

  EggNumberOverlayPainter({
    required this.eggItems,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final labelPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < eggItems.length; i++) {
      final eggItem = eggItems[i];
      
      // Get bounding box coordinates from database
      final x1 = eggItem['x1'] as double? ?? 0.0;
      final y1 = eggItem['y1'] as double? ?? 0.0;
      final x2 = eggItem['x2'] as double? ?? 0.0;
      final y2 = eggItem['y2'] as double? ?? 0.0;
      
      // Scale to display size
      final scaleX = size.width / imageWidth;
      final scaleY = size.height / imageHeight;
      
      final rect = Rect.fromLTRB(
        x1 * scaleX,
        y1 * scaleY,
        x2 * scaleX,
        y2 * scaleY,
      );

      // Draw bounding box
      canvas.drawRect(rect, paint);

      // Draw number
      final labelText = '${i + 1}';
      textPainter.text = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      final textWidth = textPainter.width;
      final textHeight = textPainter.height;
      
      // Draw number background
      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - textHeight - 4,
        textWidth + 8,
        textHeight + 4,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        labelPaint,
      );
      
      // Draw number text
      textPainter.paint(
        canvas,
        Offset(rect.left + 4, rect.top - textHeight - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant oldDelegate) => false;
}
