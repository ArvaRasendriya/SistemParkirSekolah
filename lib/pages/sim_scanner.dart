import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'crop_page.dart';

class SimScannerPage extends StatefulWidget {
  const SimScannerPage({super.key});

  @override
  State<SimScannerPage> createState() => _SimScannerPageState();
}

class _SimScannerPageState extends State<SimScannerPage> {
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
      body: FutureBuilder(
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

                    if (_showFocusCircle && _focusPoint != null)
                      Positioned(
                        left: _focusPoint!.dx - 20,
                        top: _focusPoint!.dy - 20,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.yellow,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text("Cancel"),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: _captureImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Capture"),
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
    );
  }
}
