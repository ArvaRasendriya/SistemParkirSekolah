import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'crop_page.dart';

class SimScannerPage extends StatefulWidget {
  const SimScannerPage({super.key});

  @override
  State<SimScannerPage> createState() => _SimScannerPageState();
}

class _SimScannerPageState extends State<SimScannerPage>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  Offset? _focusPoint;
  bool _showFocusCircle = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();
    final backCamera =
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;
      final picture = await _controller!.takePicture();

      if (mounted) {
        final croppedFile = await Navigator.push<File?>(
          context,
          MaterialPageRoute(
            builder: (_) => CropPage(imageFile: File(picture.path)),
          ),
        );

        if (croppedFile != null && mounted) {
          Navigator.pop(context, croppedFile);
        }
      }
    } catch (e) {
      debugPrint("Error capture: $e");
    }
  }

  void _onViewTapped(TapUpDetails details, BoxConstraints constraints) async {
    if (_controller == null) return;

    final offset = details.localPosition;
    final normalizedX = offset.dx / constraints.maxWidth;
    final normalizedY = offset.dy / constraints.maxHeight;

    await _controller!.setFocusPoint(Offset(normalizedX, normalizedY));

    setState(() {
      _focusPoint = offset;
      _showFocusCircle = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _showFocusCircle = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027), // hitam kebiruan
              Color(0xFF203A43), // biru gelapan
              Color(0xFF2C5364), // biru gradasi
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                _controller != null) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      GestureDetector(
                        onTapUp: (details) =>
                            _onViewTapped(details, constraints),
                        child: CameraPreview(_controller!),
                      ),

                      // Animasi lingkaran fokus
                      if (_showFocusCircle && _focusPoint != null)
                        Positioned(
                          left: _focusPoint!.dx - 25,
                          top: _focusPoint!.dy - 25,
                          child: AnimatedOpacity(
                            opacity: _showFocusCircle ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.yellow,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Tombol cancel & capture
                      Positioned(
                        bottom: 30,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _animatedButton(
                              color: Colors.red,
                              icon: Icons.close,
                              label: "Cancel",
                              onPressed: () => Navigator.pop(context),
                            ),
                            _animatedButton(
                              color: Colors.green,
                              icon: Icons.camera_alt,
                              label: "Capture",
                              onPressed: _captureImage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  /// Widget tombol dengan animasi
  Widget _animatedButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 6,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
