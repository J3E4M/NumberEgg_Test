// Egg Training Service for custom model training
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'railway_api.dart';

class EggTrainingService {
  static const String _baseUrl = 'https://numbereggrailway-production.up.railway.app'; // Railway URL (production)
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'multipart/form-data',
      'Accept': 'application/json',
    },
  ));

  /// Upload training data for custom egg detection model
  static Future<TrainingResult> uploadTrainingData({
    required List<File> images,
    required List<Map<String, dynamic>> annotations,
    required String modelName,
  }) async {
    try {
      debugPrint('Uploading training data for model: $modelName');
      
      final formData = FormData.fromMap({
        'model_name': modelName,
        'images': await _prepareImagesForUpload(images),
        'annotations': jsonEncode(annotations),
      });

      final response = await _dio.post('/train/upload', data: formData);
      
      if (response.statusCode == 200) {
        return TrainingResult.fromJson(response.data);
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading training data: $e');
      throw Exception('Failed to upload training data: $e');
    }
  }

  /// Start training process
  static Future<TrainingStatus> startTraining(String trainingId) async {
    try {
      final response = await _dio.post('/train/start', data: {
        'training_id': trainingId,
      });

      if (response.statusCode == 200) {
        return TrainingStatus.fromJson(response.data);
      } else {
        throw Exception('Training start failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error starting training: $e');
      throw Exception('Failed to start training: $e');
    }
  }

  /// Check training status
  static Future<TrainingStatus> checkTrainingStatus(String trainingId) async {
    try {
      final response = await _dio.get('/train/status/$trainingId');

      if (response.statusCode == 200) {
        return TrainingStatus.fromJson(response.data);
      } else {
        throw Exception('Status check failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking training status: $e');
      throw Exception('Failed to check training status: $e');
    }
  }

  /// Download trained model
  static Future<String> downloadTrainedModel(String trainingId) async {
    try {
      final response = await _dio.get('/train/download/$trainingId');

      if (response.statusCode == 200) {
        return response.data['download_url'];
      } else {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading model: $e');
      throw Exception('Failed to download model: $e');
    }
  }

  /// Get available trained models
  static Future<List<TrainedModel>> getAvailableModels() async {
    try {
      final response = await _dio.get('/train/models');

      if (response.statusCode == 200) {
        final models = <TrainedModel>[];
        for (final model in response.data['models']) {
          models.add(TrainedModel.fromJson(model));
        }
        return models;
      } else {
        throw Exception('Failed to get models with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting available models: $e');
      return [];
    }
  }

  /// Prepare images for upload
  static Future<List<MultipartFile>> _prepareImagesForUpload(List<File> images) async {
    final multipartFiles = <MultipartFile>[];
    
    for (final image in images) {
      if (await image.exists()) {
        multipartFiles.add(await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ));
      }
    }
    
    return multipartFiles;
  }

  /// Create egg annotation data
  static Map<String, dynamic> createEggAnnotation({
    required String imagePath,
    required List<EggBoundingBox> eggs,
  }) {
    return {
      'image_path': imagePath,
      'eggs': eggs.map((egg) => egg.toJson()).toList(),
    };
  }
}

class TrainingResult {
  final bool success;
  final String trainingId;
  final String message;
  final int uploadedImages;

  TrainingResult({
    required this.success,
    required this.trainingId,
    required this.message,
    required this.uploadedImages,
  });

  factory TrainingResult.fromJson(Map<String, dynamic> json) {
    return TrainingResult(
      success: json['success'] ?? false,
      trainingId: json['training_id'] ?? '',
      message: json['message'] ?? '',
      uploadedImages: json['uploaded_images'] ?? 0,
    );
  }
}

class TrainingStatus {
  final String trainingId;
  final String status;
  final double progress;
  final String message;
  final String? modelUrl;

  TrainingStatus({
    required this.trainingId,
    required this.status,
    required this.progress,
    required this.message,
    this.modelUrl,
  });

  factory TrainingStatus.fromJson(Map<String, dynamic> json) {
    return TrainingStatus(
      trainingId: json['training_id'] ?? '',
      status: json['status'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      message: json['message'] ?? '',
      modelUrl: json['model_url'],
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRunning => status == 'running';
  bool get isPending => status == 'pending';
}

class TrainedModel {
  final String id;
  final String name;
  final String description;
  final double accuracy;
  final String createdAt;
  final String downloadUrl;

  TrainedModel({
    required this.id,
    required this.name,
    required this.description,
    required this.accuracy,
    required this.createdAt,
    required this.downloadUrl,
  });

  factory TrainedModel.fromJson(Map<String, dynamic> json) {
    return TrainedModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] ?? '',
      downloadUrl: json['download_url'] ?? '',
    );
  }
}

class EggBoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final String grade; // 'big', 'medium', 'small'

  EggBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'grade': grade,
    };
  }

  factory EggBoundingBox.fromJson(Map<String, dynamic> json) {
    return EggBoundingBox(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      width: (json['width'] ?? 0.0).toDouble(),
      height: (json['height'] ?? 0.0).toDouble(),
      grade: json['grade'] ?? '',
    );
  }
}
