import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'DisplayPictureScreen.dart';
import 'HistoryPage.dart'; 

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

  // ฟังก์ชันเลือกรูปและไปหน้า DisplayPictureScreen
  Future<void> _pickImageAndGoToDisplay() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // เมื่อเลือกรูปเสร็จ ส่งไปหน้า DisplayPictureScreen ตามที่ต้องการ
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
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
                SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CameraPreview(_controller!),
                ),
                
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                            Flexible(
                              child: Center(
                                child: Image.asset(
                                  'assets/images/number_egg_logo.png',
                                  width: 200,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
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
                            // ปุ่มซ้าย (Image) - คงไว้เหมือนเดิมหรือทำงานเหมือนกันตามบริบท
                            _buildCircleButton(
                              icon: Icons.image, 
                              size: 50, 
                              onTap: _pickImageAndGoToDisplay 
                            ),
                            
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
                            
                            // [แก้ไข] ปุ่มขวา (History) - กดแล้วไป DisplayPictureScreen (ผ่านการเลือกรูป)
                            // ปุ่มขวา (History)
                            _buildCircleButton(
                              icon: Icons.history,
                              size: 50,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                                );
                              },
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