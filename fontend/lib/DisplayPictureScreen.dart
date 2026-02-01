import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/egg_database.dart';
import 'services/supabase_service.dart';

// --- หน้าแสดงผลและ Save หลังจากถ่ายภาพ ---
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool isSaving = false;
  bool isSaved = false;
  bool isLocalSaved = false;

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

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('บันทึกรูปภาพลงเครื่องเรียบร้อย: $fileName'), 
                backgroundColor: const Color(0xFF4CAF50),
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() { isLocalSaved = true; });
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { isSaving = false; });
    }
  }

  // 📊 บันทึกลง History (Database)
  Future<void> saveToHistory() async {
    setState(() { isSaving = true; });
    try {
      // จำลองการบันทึกลง Database (เนื่องจากไม่มีข้อมูล detection)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;
      
      // สร้างข้อมูลจำลองใน Supabase (แทน local SQLite)
      try {
        // สร้าง egg items สำหรับส่งไป Supabase
        final eggItems = [
          {'grade': 3, 'confidence': 98.0}, // ไข่ใหญ่
          {'grade': 2, 'confidence': 92.0}, // ไข่กลาง
        ];

        // สร้าง session พร้อม items ใน Supabase
        await SupabaseService.createEggSessionWithItems(
          userId: userId,
          imagePath: widget.imagePath,
          eggCount: 2, // จำลองว่ามี 2 ฟอง
          successPercent: 95.0, // จำลอง
          bigCount: 1,
          mediumCount: 1,
          smallCount: 0,
          day: DateTime.now().toString().substring(0, 10),
          eggItems: eggItems,
        );
      } catch (e) {
        // Fallback ไป local SQLite ถ้า Supabase ล้มเหลว
        final sessionId = await EggDatabase.instance.insertSession(
          userId: userId,
          imagePath: widget.imagePath,
          eggCount: 2, // จำลองว่ามี 2 ฟอง
          successPercent: 95.0, // จำลอง
          bigCount: 1,
          mediumCount: 1,
          smallCount: 0,
          day: DateTime.now().toString().substring(0, 10),
        );

        // จำลองการเพิ่ม egg items
        await EggDatabase.instance.insertEggItem(
          sessionId: sessionId,
          grade: 3,
          confidence: 98.0,
        );
        
        await EggDatabase.instance.insertEggItem(
          sessionId: sessionId,
          grade: 2,
          confidence: 92.0,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกลง History เรียบร้อย'), 
            backgroundColor: Color(0xFFFFB300),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() { isSaved = true; });
      }
    } catch (e) {
      debugPrint("Save to history error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก History: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { isSaving = false; });
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
                    child: Image.file(
                      File(widget.imagePath), 
                      fit: BoxFit.cover, 
                      height: 300, 
                      width: double.infinity
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
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "การประมวลผล สำเร็จ",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "พบไข่ไก่จำนวน 2 ฟอง",
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

                  _buildResultItem(
                    title: "Egg 1",
                    subtitle: "ใหญ่ (เบอร์ 0)",
                    confidence: "98%",
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 10),
                  _buildResultItem(
                    title: "Egg 2",
                    subtitle: "กลาง (เบอร์ 1)",
                    confidence: "92%",
                    iconColor: Colors.amber,
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 📱 บันทึกลงเครื่อง
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (isSaving || isLocalSaved) ? null : saveImageToGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLocalSaved ? Colors.grey : const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 2,
                    ),
                    child: isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLocalSaved ? "บันทึกลงเครื่องแล้ว" : "บันทึกลงเครื่อง",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.download, color: Colors.white),
                          ],
                        ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 📊 บันทึกลง History
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (isSaving || isSaved) ? null : saveToHistory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSaved ? Colors.grey : const Color(0xFFFFC107),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 2,
                    ),
                    child: isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isSaved ? "บันทึกลง History แล้ว" : "บันทึกลง History",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.save_alt, color: Colors.white),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem({
    required String title,
    required String subtitle,
    required String confidence,
    required Color iconColor,
  }) {
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
            child: Icon(Icons.egg, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Column(
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
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              confidence,
              style: const TextStyle(
                color: Color.fromARGB(255, 175, 168, 76),
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
