import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TakePictureScreen(),
    ),
  );
}

// --- หน้าถ่ายรูป (ไม่มีกรอบ, โหลดกล้องเอง) ---
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({Key? key}) : super(key: key);

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  FlashMode _flashMode = FlashMode.off;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
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
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(cameraController.description);
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null) return;

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      if (!mounted) return;
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: (!_isCameraInitialized || _controller == null)
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                // 1. Layer กล้อง (เต็มจอ ไม่มี Overlay)
                SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CameraPreview(_controller!),
                ),
                
                // 2. Layer ปุ่มควบคุม
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ส่วนหัว
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGlassButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.pop(context), 
                            ),

                            // --- แก้ไขตรงนี้: ใส่รูปโลโก้คู่กับข้อความ ---
                            Center(
                              child: Image.asset(
                                'assets/images/number_egg_logo.png',
                                width: 230,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min, 
                              children: [
                              
                                const SizedBox(width: 10), // ระยะห่าง
                              //   const Text(
                              //     "วิเคราะห์เบอร์ไข่",
                              //     style: TextStyle(
                              //       color: Colors.white,
                              //       fontSize: 20,
                              //       fontWeight: FontWeight.bold,
                              //       shadows: [Shadow(blurRadius: 10, color: Colors.black, offset: Offset(0, 2))],
                              //     ),
                              //   ),
                              ]
                            ),
                            // ----------------------------------------

                            _buildGlassButton(
                              icon: _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                              onTap: () async {
                                setState(() {
                                  _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
                                });
                                await _controller?.setFlashMode(_flashMode);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // ส่วนท้าย (Control Bar)
                    Container(
                      height: 160,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildCircleButton(icon: Icons.image, size: 50, onTap: () {}),
                            
                            // ปุ่มชัตเตอร์
                            GestureDetector(
                              onTap: _takePicture,
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color.fromARGB(255, 231, 154, 38), width: 4),
                                  color: const Color.fromARGB(255, 231, 154, 38).withOpacity(0.2),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.fromARGB(255, 231, 154, 38),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
                                ),
                              ),
                            ),
                            
                            _buildCircleButton(icon: Icons.history, size: 50, onTap: () {}),
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

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required double size, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
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

// --- หน้าแสดงผลและ Save (คงเดิม) ---
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