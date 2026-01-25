import 'dart:math';
import '../camera.dart';

class MockDetection {
  /// สร้าง mock data สำหรับ real-time detection
  static List<Detection> generateRealTimeDetections({
    required double imageWidth,
    required double imageHeight,
  }) {
    final random = Random();
    final numDetections = random.nextInt(3) + 1; // 1-3 detections
    
    return List.generate(numDetections, (index) {
      final x1 = random.nextDouble() * (imageWidth - 100);
      final y1 = random.nextDouble() * (imageHeight - 100);
      final size = random.nextDouble() * 50 + 50; // 50-100px
      
      final detection = Detection.fromJson({
        'bbox': {
          'x1': x1,
          'y1': y1,
          'x2': x1 + size,
          'y2': y1 + size,
        },
        'confidence': random.nextDouble() * 0.3 + 0.7, // 0.7-1.0
        'class': 0,
        'size_classification': {
          'category': _getRandomSize(random),
          'grade': random.nextInt(3) + 1,
          'label': _getRandomLabel(random),
        },
        'measurements': {
          'diameter_mm': random.nextDouble() * 10 + 40, // 40-50mm
          'area_mm2': random.nextDouble() * 100 + 1500, // 1500-1600mm²
        },
      });
      
      return detection;
    });
  }
  
  /// สร้าง mock data สำหรับ accurate detection
  static List<Detection> generateAccurateDetections({
    required double imageWidth,
    required double imageHeight,
  }) {
    final random = Random();
    final numDetections = random.nextInt(5) + 2; // 2-6 detections
    
    return List.generate(numDetections, (index) {
      final x1 = random.nextDouble() * (imageWidth - 150);
      final y1 = random.nextDouble() * (imageHeight - 150);
      final size = random.nextDouble() * 80 + 70; // 70-150px
      
      final detection = Detection.fromJson({
        'bbox': {
          'x1': x1,
          'y1': y1,
          'x2': x1 + size,
          'y2': y1 + size,
        },
        'confidence': random.nextDouble() * 0.2 + 0.8, // 0.8-1.0
        'class': 0,
        'size_classification': {
          'category': _getRandomSize(random),
          'grade': random.nextInt(3) + 1,
          'label': _getRandomLabel(random),
        },
        'measurements': {
          'diameter_mm': random.nextDouble() * 15 + 35, // 35-50mm
          'area_mm2': random.nextDouble() * 200 + 1400, // 1400-1600mm²
        },
        'coin_reference': {
          'detected': true,
          'diameter_mm': 25.0, // Standard coin size
        },
      });
      
      return detection;
    });
  }
  
  static String _getRandomSize(Random random) {
    final sizes = ['large', 'medium', 'small'];
    return sizes[random.nextInt(sizes.length)];
  }
  
  static String _getRandomLabel(Random random) {
    final labels = ['ไข่ไก่ใหญ่', 'ไข่ไก่กลาง', 'ไข่ไก่เล็ก'];
    return labels[random.nextInt(labels.length)];
  }
}
