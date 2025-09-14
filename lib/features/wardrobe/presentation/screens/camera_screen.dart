import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/image_preview_screen.dart';
// For saving image path
// For Directory
// For p.join

// Provider to hold the list of available cameras
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((
  ref,
) async {
  return await availableCameras();
});

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  FlashMode _currentFlashMode = FlashMode.auto;
  // bool _isRearCameraSelected = true; // For switching camera if multiple exist

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize camera when the widget is built and dependencies are available
    final camerasAsyncValue = ref.watch(availableCamerasProvider);
    camerasAsyncValue.whenData((cameras) {
      if (cameras.isNotEmpty && _controller == null) {
        _initCamera(cameras.first); // Default to the first available camera
      }
    });
  }

  void _initCamera(CameraDescription cameraDescription) {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false, // We don't need audio for clothing pictures
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller!
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {}); // Update UI once controller is initialized
        })
        .catchError((Object e) {
          if (e is CameraException) {
            print('Error initializing camera: ${e.code}\n${e.description}');
            // Handle camera initialization errors (e.g., show a message)
          }
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final newFlashMode =
          _currentFlashMode == FlashMode.auto
              ? FlashMode.torch
              : _currentFlashMode == FlashMode.torch
              ? FlashMode.off
              : FlashMode.auto;
      await _controller!.setFlashMode(newFlashMode);
      setState(() {
        _currentFlashMode = newFlashMode;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.torch:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
      default:
        return Icons.flash_auto;
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture) {
      return;
    }
    try {
      final XFile imageFile = await _controller!.takePicture();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(imagePath: imageFile.path),
          ),
        );
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final camerasAsyncValue = ref.watch(availableCamerasProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Typical for camera screens
      appBar: AppBar(
        title: const Text('Capture Item'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_getFlashIcon()),
            tooltip: 'Toggle Flash',
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: camerasAsyncValue.when(
        data: (cameras) {
          if (cameras.isEmpty) {
            return const Center(
              child: Text(
                'No cameras available.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (_controller == null || _initializeControllerFuture == null) {
            // This can happen briefly if _initCamera hasn't been called yet
            // or if there was an issue finding a camera in didChangeDependencies
            _initCamera(cameras.first); // Attempt to initialize if not already
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (_controller!.value.hasError) {
                  return Center(
                    child: Text(
                      'Camera error: ${_controller!.value.errorDescription}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(child: CameraPreview(_controller!)),
                    // Optional: Clothing frame guide
                    Positioned.fill(
                      child: CustomPaint(painter: CameraFramePainter()),
                    ),
                    Positioned(
                      bottom: 100, // Guidance text position
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Position item against a plain background',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) => Center(
              child: Text(
                'Error loading cameras: $err',
                style: const TextStyle(color: Colors.white),
              ),
            ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt, size: 40),
      ),
    );
  }
}

// Simple frame painter for guidance
class CameraFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Example: A simple rectangle in the middle
    final frameWidth = size.width * 0.8;
    final frameHeight = size.height * 0.6;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;
    final rect = Rect.fromLTWH(left, top, frameWidth, frameHeight);
    canvas.drawRect(rect, paint);

    // You can add more complex guides, like corner brackets or aspect ratio lines
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
