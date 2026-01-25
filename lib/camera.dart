import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Import ไฟล์ที่จำเป็น
import 'DisplayPictureScreen.dart';
import 'utils/server_config.dart';
import 'utils/mock_detection.dart';

const List<String> yoloClasses = ["egg"];

/// ================== DETECTION MODEL ==================
/// (Class นี้ต้อง public เพื่อให้หน้า DisplayPictureScreen เรียกใช้ได้)
class Detection {
  final double x1, y1, x2, y2;
  final double confidence;
  final String eggSize; // ขนาดไข่ไก่ตามมาตรฐาน
  final int eggNumber; // grade 0-5
  final String eggLabel; // ชื่อเต็มของขนาดไข่
  final double? diameterMm; // เส้นผ่านศูนย์กลางในมิลลิเมตร
  final double? areaMm2; // พื้นที่ในมม²
  final Map<String, dynamic>? sizeClassification; // ข้อมูลการจำแนกขนาด
  final Map<String, dynamic>? coinReference; // ข้อมูลเหรียญอ้างอิง

  Detection.fromJson(Map<String, dynamic> json)
      : x1 = (json['bbox']['x1'] as num).toDouble(),
        y1 = (json['bbox']['y1'] as num).toDouble(),
        x2 = (json['bbox']['x2'] as num).toDouble(),
        y2 = (json['bbox']['y2'] as num).toDouble(),
        confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0,
        eggSize = _extractEggSize(json),
        eggNumber = _extractEggNumber(json),
        eggLabel = _extractEggLabel(json),
        diameterMm = (json['measurements']?['diameter_mm'] as num?)?.toDouble(),
        areaMm2 = (json['measurements']?['area_mm2'] as num?)?.toDouble(),
        sizeClassification = json['size_classification'] as Map<String, dynamic>?,
        coinReference = json['coin_reference'] as Map<String, dynamic>?;

  static String _extractEggSize(Map<String, dynamic> json) {
    // ดึงขนาดจาก size classification
    final sizeClass = json['size_classification'] as Map<String, dynamic>?;
    if (sizeClass != null) {
      return sizeClass['category'] as String? ?? 'unknown';
    }
    
    // fallback สำหรับข้อมูลเก่า
    double width = ((json['bbox']['x2'] as num).toDouble() - (json['bbox']['x1'] as num).toDouble()).abs();
    double height = ((json['bbox']['y2'] as num).toDouble() - (json['bbox']['y1'] as num).toDouble()).abs();
    double area = width * height;

    if (area > 15000) return 'large';
    if (area > 10000) return 'medium';
    return 'small';
  }

  static int _extractEggNumber(Map<String, dynamic> json) {
    // ดึงเกรดจาก size classification
    final sizeClass = json['size_classification'] as Map<String, dynamic>?;
    if (sizeClass != null) {
      return (sizeClass['grade'] as num?)?.toInt() ?? 3;
    }
    
    // fallback สำหรับข้อมูลเก่า
    String size = _extractEggSize(json);
    switch (size) {
      case 'jumbo': return 0;
      case 'extra_large': return 1;
      case 'large': return 2;
      case 'medium': return 3;
      case 'small': return 4;
      case 'peewee': return 5;
      default: return 3;
    }
  }

  static String _extractEggLabel(Map<String, dynamic> json) {
    // ดึงชื่อเต็มจาก size classification
    final sizeClass = json['size_classification'] as Map<String, dynamic>?;
    if (sizeClass != null) {
      return sizeClass['label'] as String? ?? 'ไข่ไก่ทั่วไป';
    }
    
    // fallback
    String size = _extractEggSize(json);
    switch (size) {
      case 'jumbo': return 'ไข่ไก่ยักษ์';
      case 'extra_large': return 'ไข่ไก่ใหญ่พิเศษ';
      case 'large': return 'ไข่ไก่ใหญ่';
      case 'medium': return 'ไข่ไก่กลาง';
      case 'small': return 'ไข่ไก่เล็ก';
      case 'peewee': return 'ไข่ไก่พิเศษเล็ก';
      default: return 'ไข่ไก่ทั่วไป';
    }
  }

  /// ตรวจสอบว่ามีเหรียญอ้างอิงหรือไม่
  bool get hasCoinReference => coinReference != null && (coinReference!['detected'] as bool? ?? false);

  /// ตรวจสอบว่าการวัดมีความแม่นยำหรือไม่
  bool get isAccurate => hasCoinReference && diameterMm != null;

  /// ดึงข้อมูลสรุปการวัด
  String get measurementSummary {
    if (!isAccurate) return 'ไม่มีเหรียญอ้างอิง';
    return 'เส้นผ่านศูนย์กลาง: ${diameterMm?.toStringAsFixed(1)} มม.';
  }
}

/// ================== MAIN CAMERA SCREEN ==================
class TakePictureScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;

  const TakePictureScreen({Key? key, this.cameras}) : super(key: key);

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  FlashMode _flashMode = FlashMode.off;
  bool _isCameraInitialized = false;
  bool _isProcessing = false; // ตัวแปรเช็คสถานะกำลังประมวลผล
  
  // Real-time detection
  bool _isRealTimeDetectionEnabled = false;
  Timer? _detectionTimer;
  List<Detection> _currentDetections = [];
  Size? _cameraPreviewSize;
  
  // Mock mode (สำหรับทดสอบเมื่อ server ไม่ตอบ)
  static const bool _useMockWhenOffline = true; // ตั้งเป็น true เพื่อใช้ mock data เมื่อ server ไม่ตอบ
  
  // Real-time detection settings
  static const Duration _detectionInterval = Duration(seconds: 3); // ลดเวลาเป็น 3 วินาที
  static const int _maxDetections = 10; // จำนวน detections สูงสุดที่แสดง

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = widget.cameras ?? await availableCameras();
      if (cameras.isNotEmpty) {
        _initCamera(cameras.first);
      } else {
        debugPrint("No cameras found");
      }
    } catch (e) {
      debugPrint("Error loading camera: $e");
    }
  }

  Future<void> _initCamera(CameraDescription cameraDescription) async {
    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;
    _initializeControllerFuture = controller.initialize();

    try {
      await _initializeControllerFuture;
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        // เริ่ม real-time detection ถ้าเปิดอยู่
        if (_isRealTimeDetectionEnabled) {
          _startRealTimeDetection();
        }
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(cameraController.description);
    }
  }

  /// ส่ง image bytes ไป YOLO (สำหรับ real-time detection)
  Future<List<Detection>> _sendImageBytesToYolo(Uint8List imageBytes) async {
    try {
      final baseUrl = await ServerConfig.getDetectUrl();
      debugPrint("Sending image bytes to: $baseUrl");

      final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'frame.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Connection timeout',
            const Duration(seconds: 10),
          );
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint('✅ Real-time detection response: ${response.body}');
        if (jsonData.containsKey('detections')) {
          final detections = (jsonData['detections'] as List)
              .map((e) => Detection.fromJson(e))
              .toList();
          debugPrint('✅ Found ${detections.length} detections');
          return detections;
        } else {
          debugPrint('⚠️ No detections key in response');
        }
      } else {
        debugPrint('⚠️ Server returned status: ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      debugPrint('⚠️ Real-time detection error: $e');
      
      // ใช้ mock data เมื่อ server ไม่ตอบ (ถ้าเปิดใช้งาน)
      if (_useMockWhenOffline && _controller != null && _controller!.value.isInitialized) {
        try {
          final previewSize = _controller!.value.previewSize;
          if (previewSize != null) {
            return MockDetection.generateRealTimeDetections(
              imageWidth: previewSize.width.toDouble(),
              imageHeight: previewSize.height.toDouble(),
            );
          }
        } catch (_) {
          // Ignore mock error
        }
      }
      
      return [];
    }
  }

  /// -------------------------------------------------------------------
  /// ส่วนที่แก้ไข: ส่ง API แบบ Bytes เพื่อเลี่ยงปัญหา _Namespace
  /// -------------------------------------------------------------------
  Future<List<Detection>> _sendToYolo(String imagePath) async {
    try {
      // 1. ดึง URL จาก config (รองรับการตั้งค่า IP address จริง)
      final baseUrl = await ServerConfig.getDetectUrl();

      debugPrint("Sending image to: $baseUrl");

      // 2. อ่านไฟล์เป็น Bytes (แก้ปัญหา _Namespace)
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        throw Exception("File not found");
      }
      final imageBytes = await imageFile.readAsBytes();

      // 3. สร้าง Request
      final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      
      // ใช้ fromBytes แทน fromPath
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'upload.jpg',
        ),
      );

      // 4. ส่งและรอรับผล (เพิ่ม timeout)
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Connection timeout: ไม่สามารถเชื่อมต่อกับ server ได้ภายใน 30 วินาที\n'
            'กรุณาตรวจสอบว่า:\n'
            '1. Server รันอยู่ที่ port 8000\n'
            '2. สำหรับ Emulator: ใช้ http://10.0.2.2:8000\n'
            '3. สำหรับ Device จริง: ใช้ IP address ของเครื่องที่รัน server',
            const Duration(seconds: 30),
          );
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = response.body;
        final jsonData = jsonDecode(body);
        
        if (jsonData.containsKey('detections')) {
          return (jsonData['detections'] as List)
              .map((e) => Detection.fromJson(e))
              .toList();
        }
      }
      
      debugPrint("Server Error: ${response.statusCode} ${response.body}");
      throw Exception('API call failed');

    } catch (e) {
      debugPrint('⚠️ Connection Error: $e');
      
      // แสดง error dialog แทนการ return mock data
      if (mounted) {
        String errorMessage = 'ไม่สามารถเชื่อมต่อกับ server ได้';
        String errorDetail = '';
        
        if (e is TimeoutException) {
          errorMessage = 'Connection Timeout';
          errorDetail = e.message ?? 'ไม่สามารถเชื่อมต่อได้ภายใน 30 วินาที';
        } else if (e is SocketException) {
          errorMessage = 'Connection Failed';
          errorDetail = 'ไม่สามารถเชื่อมต่อกับ server ได้\n'
              'กรุณาตรวจสอบว่า:\n'
              '• Server รันอยู่ที่ port 8000\n'
              '• สำหรับ Emulator: ใช้ http://10.0.2.2:8000\n'
              '• สำหรับ Device จริง: ตรวจสอบการเชื่อมต่อเครือข่าย';
        } else {
          errorDetail = e.toString();
        }
        
        // แสดง dialog แจ้งเตือน
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(errorMessage),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(errorDetail),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ],
          ),
        );
      }
      
      // ใช้ mock data เมื่อ server ไม่ตอบ (ถ้าเปิดใช้งาน)
      if (_useMockWhenOffline) {
        try {
          final imageFile = File(imagePath);
          if (imageFile.existsSync()) {
            final imageBytes = await imageFile.readAsBytes();
            final image = await decodeImageFromList(imageBytes);
            return MockDetection.generateAccurateDetections(
              imageWidth: image.width.toDouble(),
              imageHeight: image.height.toDouble(),
            );
          }
        } catch (_) {
          // Ignore mock error
        }
      }
      
      // Return empty list เพื่อไม่ให้แสดงผลผิดพลาด
      return [];
    }
  }

  /// ถ่ายรูปและส่งไปประมวลผล
  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      
      // ส่งไป YOLO
      final detections = await _sendToYolo(image.path);

      if (!mounted) return;

      // ไปหน้าแสดงผล (DisplayPictureScreen)
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            imagePath: image.path,
            detections: detections, // ✅ ส่งข้อมูล Detection ไปด้วย
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error capturing: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// เริ่ม real-time detection ที่ดีขึ้น
  void _startRealTimeDetection() {
    _stopRealTimeDetection(); // หยุด timer เก่าก่อน
    
    debugPrint('🚀 Starting real-time detection with interval: ${_detectionInterval.inSeconds}s');
    
    _detectionTimer = Timer.periodic(_detectionInterval, (timer) async {
      if (!_isRealTimeDetectionEnabled || 
          !_isCameraInitialized || 
          _controller == null ||
          !_controller!.value.isInitialized ||
          _isProcessing) {
        debugPrint('⏸️ Pausing real-time detection - conditions not met');
        return;
      }

      debugPrint('📸 Capturing frame for real-time detection...');
      
      try {
        // ถ่ายรูปจาก camera preview
        final image = await _controller!.takePicture();
        final imageBytes = await File(image.path).readAsBytes();
        
        // ลบไฟล์ชั่วคราวทันที
        try {
          await File(image.path).delete();
        } catch (e) {
          debugPrint('⚠️ Error deleting temp file: $e');
        }

        // ส่งไป YOLO พร้อม timeout สั้นสำหรับ real-time
        final detections = await _sendImageBytesToYolo(imageBytes).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('⏰ Real-time detection timeout');
            return <Detection>[];
          },
        );
        
        // จำกัดจำนวน detections ที่แสดง
        final limitedDetections = detections.take(_maxDetections).toList();
        
        debugPrint('📊 Real-time detection result: ${limitedDetections.length} eggs found');
        
        if (mounted) {
          setState(() {
            _currentDetections = limitedDetections;
          });
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Real-time detection error: $e');
        debugPrint('Stack trace: $stackTrace');
        
        // ใช้ mock data เมื่อเกิด error (ถ้าเปิดใช้งาน)
        if (_useMockWhenOffline && _controller != null && _controller!.value.isInitialized) {
          try {
            final previewSize = _controller!.value.previewSize;
            if (previewSize != null) {
              final mockDetections = MockDetection.generateRealTimeDetections(
                imageWidth: previewSize.width.toDouble(),
                imageHeight: previewSize.height.toDouble(),
              ).take(_maxDetections).toList();
              
              if (mounted) {
                setState(() {
                  _currentDetections = mockDetections;
                });
              }
              debugPrint('🔄 Using mock data: ${mockDetections.length} eggs');
            }
          } catch (mockError) {
            debugPrint('❌ Mock detection error: $mockError');
          }
        }
      }
    });
  }

  /// หยุด real-time detection
  void _stopRealTimeDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    if (mounted) {
      setState(() {
        _currentDetections = [];
      });
    }
  }

  /// Toggle real-time detection
  void _toggleRealTimeDetection() {
    setState(() {
      _isRealTimeDetectionEnabled = !_isRealTimeDetectionEnabled;
    });

    if (_isRealTimeDetectionEnabled) {
      _startRealTimeDetection();
    } else {
      _stopRealTimeDetection();
    }
  }

  /// เลือกรูปจาก Gallery
  Future<void> _pickImageAndAnalyze() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        final detections = await _sendToYolo(image.path);

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DisplayPictureScreen(
                imagePath: image.path,
                detections: detections,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Gallery error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// ================== UI BUILD ==================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: (!_isCameraInitialized || _controller == null)
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : Stack(
              children: [
                // 1. Camera Preview
                SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CameraPreview(_controller!),
                ),

                // 2. Detection Overlay (วาด detection boxes)
                if (_isRealTimeDetectionEnabled && 
                    _controller != null &&
                    _controller!.value.isInitialized)
                  CustomPaint(
                    size: size,
                    painter: DetectionOverlayPainter(
                      detections: _currentDetections,
                      cameraValue: _controller!.value,
                      screenSize: size,
                    ),
                  ),

                // 3. Scan Overlay (กรอบเหลือง)
                CustomPaint(
                  size: size,
                  painter: ScanOverlayPainter(),
                ),

                // 4. UI Controls
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildGlassButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Image.asset(
                                  'assets/images/number_egg_logo1.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const SizedBox(),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Real-time Detection Toggle
                                _buildGlassButton(
                                  icon: _isRealTimeDetectionEnabled
                                      ? Icons.camera_alt
                                      : Icons.camera,
                                  onTap: _toggleRealTimeDetection,
                                  color: _isRealTimeDetectionEnabled
                                      ? const Color(0xFFFFC107)
                                      : Colors.white,
                                ),
                                const SizedBox(width: 8),
                                // Flash Toggle
                                _buildGlassButton(
                                  icon: _flashMode == FlashMode.off
                                      ? Icons.flash_off
                                      : Icons.flash_on,
                                  onTap: () async {
                                    setState(() {
                                      _flashMode = _flashMode == FlashMode.off
                                          ? FlashMode.torch
                                          : FlashMode.off;
                                    });
                                    await _controller?.setFlashMode(_flashMode);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Bottom Controls
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // คำแนะนำและสถานะ
                            Column(
                              children: [
                                // Real-time Detection Status
                                if (_isRealTimeDetectionEnabled)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: _currentDetections.isNotEmpty 
                                            ? Colors.green.withOpacity(0.8)
                                            : Colors.orange.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Animated indicator
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _currentDetections.isNotEmpty
                                                  ? '🥚 ตรวจจับ ${_currentDetections.length} ฟอง'
                                                  : '🔍 กำลังสแกน...',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // คำแนะนำและสถิติ
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFC107).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    // child: Column(
                                    //   children: [
                                    //     Text(
                                    //       _isRealTimeDetectionEnabled
                                    //           ? '🎯 ตรวจจับไข่แบบ Real-time'
                                    //           : '📸 กดปุ่มถ่ายเพื่อตรวจจับ',
                                    //       style: const TextStyle(
                                    //         color: Colors.white,
                                    //         fontSize: 14,
                                    //         fontWeight: FontWeight.w600,
                                    //       ),
                                    //       textAlign: TextAlign.center,
                                    //     ),
                                    //     if (_isRealTimeDetectionEnabled && _currentDetections.isNotEmpty)
                                    //       Padding(
                                    //         padding: const EdgeInsets.only(top: 4),
                                    //         child: Text(
                                    //           'อัตราการตรวจ: ${_detectionInterval.inSeconds}วินาที/ครั้ง',
                                    //           style: TextStyle(
                                    //             color: Colors.white.withOpacity(0.8),
                                    //             fontSize: 10,
                                    //           ),
                                    //         ),
                                    //       ),
                                    //   ],
                                    // ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Buttons Row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Gallery
                                  _buildCircleButton(
                                    icon: Icons.image,
                                    size: 50,
                                    onTap: _pickImageAndAnalyze,
                                  ),

                                  // Shutter Button
                                  GestureDetector(
                                    onTap: _isProcessing ? null : _takePicture,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFFFFC107), width: 4),
                                        color: const Color(0xFFFFC107).withOpacity(0.2),
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFFFC107),
                                        ),
                                        child: _isProcessing
                                            ? const Padding(
                                                padding: EdgeInsets.all(20),
                                                child: CircularProgressIndicator(
                                                  color: Colors.black,
                                                  strokeWidth: 3,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.camera_alt,
                                                color: Colors.black,
                                                size: 30,
                                              ),
                                      ),
                                    ),
                                  ),

                                  // History Button
                                  _buildCircleButton(
                                    icon: Icons.history,
                                    size: 50,
                                    onTap: () {
                                      Navigator.pushNamed(context, '/history');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 24),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required double size, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

/// ================== DETECTION OVERLAY PAINTER ==================
class DetectionOverlayPainter extends CustomPainter {
  final List<Detection> detections;
  final CameraValue cameraValue;
  final Size screenSize;

  DetectionOverlayPainter({
    required this.detections,
    required this.cameraValue,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!cameraValue.isInitialized) return;
    if (detections.isEmpty) return;

    // ใช้ previewSize จาก cameraValue หรือใช้ screen size เป็น fallback
    final previewSize = cameraValue.previewSize;
    if (previewSize == null) {
      debugPrint('⚠️ No previewSize, using direct coordinates');
      // ถ้าไม่มี previewSize ให้ใช้ screen size โดยตรง (ไม่ scale)
      for (var detection in detections) {
        final rect = Rect.fromLTRB(
          detection.x1,
          detection.y1,
          detection.x2,
          detection.y2,
        );
        _drawDetection(canvas, detection, rect);
      }
      return;
    }

    // คำนวณ scale factor ระหว่าง preview และ screen
    // โดยปกติ camera preview จะถูก scale ให้ fit หน้าจอแบบ maintain aspect ratio
    final scaleX = size.width / previewSize.width;
    final scaleY = size.height / previewSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY; // ใช้ scale ที่เล็กกว่าเพื่อ maintain aspect ratio

    final scaledWidth = previewSize.width * scale;
    final scaledHeight = previewSize.height * scale;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    debugPrint('📐 Preview: ${previewSize.width}x${previewSize.height}, Screen: ${size.width}x${size.height}, Scale: $scale');

    for (var detection in detections) {
      // แปลง coordinates จาก image space (ตาม detection ที่ได้จาก server)
      // เป็น screen space โดยใช้ previewSize เป็น reference
      // สมมติว่า detection coordinates เป็น relative to preview size
      final rect = Rect.fromLTRB(
        detection.x1 * scale + offsetX,
        detection.y1 * scale + offsetY,
        detection.x2 * scale + offsetX,
        detection.y2 * scale + offsetY,
      );

      debugPrint('🎯 Detection: (${detection.x1}, ${detection.y1}) -> (${detection.x2}, ${detection.y2}) -> Screen: (${rect.left}, ${rect.top}) -> (${rect.right}, ${rect.bottom})');
      _drawDetection(canvas, detection, rect);
    }
  }

  void _drawDetection(Canvas canvas, Detection detection, Rect rect) {
    // วาด box สีเขียว
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);

    // วาด label แสดงเบอร์ไข่และขนาด
    final eggNumberText = TextPainter(
      text: TextSpan(
        text: 'เบอร์ ${detection.eggNumber} : ${detection.eggSize}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    eggNumberText.layout();

    // วาด label แสดงความถูกต้อง
    final accuracyText = TextPainter(
      text: TextSpan(
        text: '${(detection.confidence * 100).toStringAsFixed(0)}% ความถูกต้อง',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    accuracyText.layout();

    // คำนวณขนาด label background
    final labelWidth = eggNumberText.width > accuracyText.width 
        ? eggNumberText.width + 16 
        : accuracyText.width + 16;
    final labelHeight = eggNumberText.height + accuracyText.height + 12;

    final labelRect = Rect.fromLTWH(
      rect.left,
      rect.top - labelHeight - 4,
      labelWidth,
      labelHeight,
    );

    // วาด background สีเขียวอ่อน
    final labelPaint = Paint()
      ..color = Colors.green.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
      labelPaint,
    );

    // วาดข้อความเบอร์ไข่
    eggNumberText.paint(
      canvas, 
      Offset(rect.left + 8, rect.top - labelHeight + 4),
    );

    // วาดข้อความความถูกต้อง
    accuracyText.paint(
      canvas, 
      Offset(rect.left + 8, rect.top - labelHeight + eggNumberText.height + 6),
    );
  }

  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) {
    // วาดใหม่เสมอเมื่อ detections เปลี่ยน
    if (oldDelegate.detections.length != detections.length) return true;
    if (oldDelegate.cameraValue.previewSize != cameraValue.previewSize) return true;
    if (oldDelegate.screenSize != screenSize) return true;
    
    // ตรวจสอบว่า detection values เปลี่ยนหรือไม่
    for (int i = 0; i < detections.length; i++) {
      if (i >= oldDelegate.detections.length) return true;
      final old = oldDelegate.detections[i];
      final current = detections[i];
      if (old.x1 != current.x1 || old.y1 != current.y1 || 
          old.x2 != current.x2 || old.y2 != current.y2) {
        return true;
      }
    }
    
    return false;
  }
}

/// ================== SCAN OVERLAY PAINTER ==================
class ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC107)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.4,
    );

    final cornerLength = 30.0;

    // วาดมุมทั้ง 4
    // Top Left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerLength, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerLength), paint);

    // Top Right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-cornerLength, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, cornerLength), paint);

    // Bottom Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(cornerLength, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -cornerLength), paint);

    // Bottom Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-cornerLength, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
