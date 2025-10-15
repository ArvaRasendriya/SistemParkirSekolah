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
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTapUp: (details) => _onViewTapped(details, constraints),
                      child: CameraPreview(_controller!),
                    ),

                    // Garis frame tengah (16:9)
                    Center(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Lingkaran fokus
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

                    // Bagian atas (Back + ZON4)
                    Positioned(
                      top: 40,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tombol back (panah)
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),

                          // Tulisan ZON4 di tengah
                          const Expanded(
                            child: Center(
                              child: Text(
                                "ZON4",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 40), // Spacer biar seimbang
                        ],
                      ),
                    ),

                    // Tulisan "Pastikan Kartu Anda Sesuai"
                    Positioned(
                      bottom: 120,
                      left: 0,
                      right: 0,
                      child: const Text(
                        "Pastikan kartu anda sesuai",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // Tombol capture (ikon kamera putih bulat)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _captureImage,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
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
    );
  }
}
