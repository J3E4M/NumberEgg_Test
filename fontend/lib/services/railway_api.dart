// Railway API Service for YOLO Egg Detection
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RailwayApiService {
  static const String _baseUrl = 'https://numberegg-railway-production.up.railway.app'; // Railway deployment URL
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'multipart/form-data',
      'Accept': 'application/json',
    },
  ));

  /// Update Railway URL
  static void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
    debugPrint('Railway API URL updated to: $url');
  }

  /// Check API health
  static Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// Detect eggs in image
  static Future<EggDetectionResult> detectEggs(File imageFile) async {
    try {
      debugPrint('Starting egg detection for: ${imageFile.path}');
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post('/detect', data: formData);
      
      if (response.statusCode == 200) {
        final result = EggDetectionResult.fromJson(response.data);
        debugPrint('Detection successful: ${result.eggCount} eggs detected');
        return result;
      } else {
        throw Exception('Detection failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Dio error during detection: ${e.message}');
      throw Exception('Detection API error: ${e.message}');
    } catch (e) {
      debugPrint('Error during detection: $e');
      throw Exception('Detection failed: $e');
    }
  }

  /// Get API info
  static Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final response = await _dio.get('/');
      return response.data;
    } catch (e) {
      debugPrint('Error getting API info: $e');
      throw Exception('Failed to get API info: $e');
    }
  }
}

class EggDetectionResult {
  final bool success;
  final String timestamp;
  final ImageInfo imageInfo;
  final DetectionResults detectionResults;
  final String processedImage;

  EggDetectionResult({
    required this.success,
    required this.timestamp,
    required this.imageInfo,
    required this.detectionResults,
    required this.processedImage,
  });

  factory EggDetectionResult.fromJson(Map<String, dynamic> json) {
    return EggDetectionResult(
      success: json['success'] ?? false,
      timestamp: json['timestamp'] ?? '',
      imageInfo: ImageInfo.fromJson(json['image_info'] ?? {}),
      detectionResults: DetectionResults.fromJson(json['detection_results'] ?? {}),
      processedImage: json['processed_image'] ?? '',
    );
  }

  int get eggCount => detectionResults.eggCount;
  int get bigCount => detectionResults.bigCount;
  int get mediumCount => detectionResults.mediumCount;
  int get smallCount => detectionResults.smallCount;
  double get successPercent => detectionResults.successPercent;
  List<Detection> get detections => detectionResults.detections;
}

class ImageInfo {
  final String filename;
  final int size;
  final String format;
  final String dimensions;

  ImageInfo({
    required this.filename,
    required this.size,
    required this.format,
    required this.dimensions,
  });

  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(
      filename: json['filename'] ?? '',
      size: json['size'] ?? 0,
      format: json['format'] ?? '',
      dimensions: json['dimensions'] ?? '',
    );
  }
}

class DetectionResults {
  final int eggCount;
  final int bigCount;
  final int mediumCount;
  final int smallCount;
  final double successPercent;
  final List<Detection> detections;

  DetectionResults({
    required this.eggCount,
    required this.bigCount,
    required this.mediumCount,
    required this.smallCount,
    required this.successPercent,
    required this.detections,
  });

  factory DetectionResults.fromJson(Map<String, dynamic> json) {
    final detectionsList = <Detection>[];
    if (json['detections'] != null) {
      for (final detection in json['detections']) {
        detectionsList.add(Detection.fromJson(detection));
      }
    }

    return DetectionResults(
      eggCount: json['egg_count'] ?? 0,
      bigCount: json['big_count'] ?? 0,
      mediumCount: json['medium_count'] ?? 0,
      smallCount: json['small_count'] ?? 0,
      successPercent: (json['success_percent'] ?? 0.0).toDouble(),
      detections: detectionsList,
    );
  }
}

class Detection {
  final int id;
  final String grade;
  final double confidence;
  final BoundingBox bbox;

  Detection({
    required this.id,
    required this.grade,
    required this.confidence,
    required this.bbox,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      id: json['id'] ?? 0,
      grade: json['grade'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      bbox: BoundingBox.fromJson(json['bbox'] ?? {}),
    );
  }
}

class BoundingBox {
  final double x1, y1, x2, y2, width, height, area;

  BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.width,
    required this.height,
    required this.area,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x1: (json['x1'] ?? 0.0).toDouble(),
      y1: (json['y1'] ?? 0.0).toDouble(),
      x2: (json['x2'] ?? 0.0).toDouble(),
      y2: (json['y2'] ?? 0.0).toDouble(),
      width: (json['width'] ?? 0.0).toDouble(),
      height: (json['height'] ?? 0.0).toDouble(),
      area: (json['area'] ?? 0.0).toDouble(),
    );
  }
}
