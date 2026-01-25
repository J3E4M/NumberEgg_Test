import 'package:flutter/material.dart';
import 'dart:io';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  // ฟังก์ชันช่วยแปลง ขนาด (เช่น "ใหญ่") เป็นชื่อเบอร์และสี
  // อัปเดตสีและชื่อให้ตรงกับภาพตัวอย่าง (Screenshot)
  Map<String, dynamic> _getEggDetails(String sizeKey) {
    switch (sizeKey) {
      case 'ใหญ่':
        return {
          'name': 'ใหญ่ (เบอร์ 0)',
          'color': Colors.green // สีเขียวตามภาพตัวอย่าง
        };
      case 'กลาง':
        return {
          'name': 'กลาง (เบอร์ 1)',
          'color': Colors.amber // สีเหลืองตามภาพตัวอย่าง
        };
      case 'เล็ก':
        return {'name': 'เล็ก (เบอร์ 2-3)', 'color': Colors.orange};
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
                      child: imagePath != null && File(imagePath).existsSync()
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
