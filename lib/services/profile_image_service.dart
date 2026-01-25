import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfileImageService {
  static const String _profileImageFolder = 'profile_images';
  
  /// ดึงโฟลเดอร์สำหรับเก็บรูปโปรไฟล์
  static Future<Directory> _getProfileImageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final profileDir = Directory(path.join(appDir.path, _profileImageFolder));
    
    // สร้างโฟลเดอร์ถ้ายังไม่มี
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    
    return profileDir;
  }
  
  /// บันทึกรูปโปรไฟล์และคืนค่า path
  static Future<String> saveProfileImage(File imageFile, int userId) async {
    try {
      final profileDir = await _getProfileImageDir();
      
      // สร้างชื่อไฟล์จาก userId และ timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'user_${userId}_$timestamp.jpg';
      final savedImagePath = path.join(profileDir.path, fileName);
      
      // คัดลอกไฟล์ไปยังโฟลเดอร์โปรไฟล์
      final savedFile = await imageFile.copy(savedImagePath);
      
      print('Profile image saved to: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      print('Error saving profile image: $e');
      throw Exception('ไม่สามารถบันทึกรูปโปรไฟล์ได้: $e');
    }
  }
  
  /// ดึงรูปโปรไฟล์จาก path
  static File? getProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    
    final file = File(imagePath);
    return file.existsSync() ? file : null;
  }
  
  /// ลบรูปโปรไฟล์เก่า
  static Future<void> deleteProfileImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('Profile image deleted: $imagePath');
      }
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }
  
  /// อัปเดตรูปโปรไฟล์ (ลบเก่า บันทึกใหม่)
  static Future<String> updateProfileImage(File newImageFile, int userId, String? oldImagePath) async {
    // ลบรูปเก่าก่อน
    await deleteProfileImage(oldImagePath);
    
    // บันทึกรูปใหม่
    return await saveProfileImage(newImageFile, userId);
  }
  
  /// ตรวจสอบว่ามีรูปโปรไฟล์หรือไม่
  static bool hasProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }
    
    return File(imagePath).existsSync();
  }
  
  /// ดึงขนาดของรูปโปรไฟล์
  static Future<int?> getImageFileSize(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Error getting image file size: $e');
    }
    
    return null;
  }
  
  /// ทำความสะอาดรูปโปรไฟล์ที่ไม่ได้ใช้ (optional)
  static Future<void> cleanupUnusedImages(List<String> activePaths) async {
    try {
      final profileDir = await _getProfileImageDir();
      final files = await profileDir.list().toList();
      
      for (final file in files) {
        if (file is File && !activePaths.contains(file.path)) {
          await file.delete();
          print('Deleted unused profile image: ${file.path}');
        }
      }
    } catch (e) {
      print('Error cleaning up profile images: $e');
    }
  }
}
