import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// --- หน้าแสดงผลและ Save หลังจากถ่ายภาพ ---
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool isSaving = false;

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
