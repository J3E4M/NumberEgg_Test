import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// 🎯 ตัวอย่างการใช้งาน Supabase Storage สำหรับเก็บรูปภาพไข่
class SupabaseStorageService {
  static final client = Supabase.instance.client;
  static const String bucketName = 'egg-images';

  /// 📤 อัพโหลดรูปภาพไข่
  static Future<String> uploadEggImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // สร้างชื่อไฟล์ที่ไม่ซ้ำกัน
      final uniqueFileName = 'eggs/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // อัพโหลดไฟล์
      await client.storage.from(bucketName).uploadBinary(
        uniqueFileName,
        imageBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );
      
      // ดึง public URL
      final publicUrl = client.storage.from(bucketName).getPublicUrl(uniqueFileName);
      
      return publicUrl;
    } catch (e) {
      throw Exception('อัพโหลดรูปภาพล้มเหลว: $e');
    }
  }

  /// 🗑️ ลบรูปภาพ
  static Future<void> deleteEggImage(String imageUrl) async {
    try {
      // แปลง URL เป็น path
      final path = imageUrl.split('/').last;
      await client.storage.from(bucketName).remove([path]);
    } catch (e) {
      throw Exception('ลบรูปภาพล้มเหลว: $e');
    }
  }

  /// 📋 ดึงรายการไฟล์ทั้งหมด
  static Future<List<String>> getAllEggImages() async {
    try {
      final response = await client.storage.from(bucketName).list();
      return response.map((file) => file.name).toList();
    } catch (e) {
      throw Exception('ดึงรายการรูปภาพล้มเหลว: $e');
    }
  }

  /// 🔍 ค้นหารูปภาพ
  static Future<List<String>> searchEggImages(String keyword) async {
    try {
      final allImages = await getAllEggImages();
      return allImages.where((image) => 
        image.toLowerCase().contains(keyword.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('ค้นหารูปภาพล้มเหลว: $e');
    }
  }
}

/// 🎨 UI สำหรับจัดการรูปภาพใน Supabase Storage
class EggImageGallery extends StatefulWidget {
  const EggImageGallery({super.key});

  @override
  State<EggImageGallery> createState() => _EggImageGalleryState();
}

class _EggImageGalleryState extends State<EggImageGallery> {
  List<String> imageUrls = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final images = await SupabaseStorageService.getAllEggImages();
      
      // แปลงชื่อไฟล์เป็น public URL
      final urls = images.map((image) => 
        Supabase.instance.client.storage
            .from('egg-images')
            .getPublicUrl(image)
      ).toList();
      
      setState(() {
        imageUrls = urls;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> uploadTestImage() async {
    // สร้างข้อมูลรูปภาพตัวอย่าง (สีเดียว)
    final imageBytes = List<int>.filled(100 * 100 * 3, 255); // 100x100 white image
    
    try {
      final url = await SupabaseStorageService.uploadEggImage(
        imageBytes: Uint8List.fromList(imageBytes),
        fileName: 'test_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพโหลดรูปภาพสำเร็จ: $url'),
          backgroundColor: Colors.green,
        ),
      );
      
      loadImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพโหลดล้มเหลว: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 Egg Image Gallery'),
        actions: [
          IconButton(
            onPressed: loadImages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Upload button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: uploadTestImage,
              icon: const Icon(Icons.upload),
              label: const Text('อัพโหลดรูปภาพทดสอบ'),
            ),
          ),
          
          // Image grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('❌ $error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: loadImages,
                              child: const Text('ลองใหม่'),
                            ),
                          ],
                        ),
                      )
                    : imageUrls.isEmpty
                        ? const Center(
                            child: Text('ยังไม่มีรูปภาพ'),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              final url = imageUrls[index];
                              return Card(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(Icons.broken_image),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        'Image ${index + 1}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
