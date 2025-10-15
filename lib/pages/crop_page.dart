import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'preview.dart';

class CropPage extends StatelessWidget {
  final File imageFile;

  const CropPage({super.key, required this.imageFile});

  Future<void> _cropImage(BuildContext context) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: null,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop SIM',
          toolbarColor: const Color(0xFF2E239D), // 🔹 Warna tengah gradasi
          statusBarColor: const Color(0xFF1D1879),
          toolbarWidgetColor: Colors.white,
          hideBottomControls: false,
          backgroundColor: Colors.black,
          showCropGrid: true,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop SIM',
        ),
      ],
    );

    if (cropped != null && context.mounted) {
      final file = await Navigator.push<File?>(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewPage(croppedFile: File(cropped.path)),
        ),
      );

      if (file != null && context.mounted) {
        Navigator.pop(context, file);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3F37C9),
              Color(0xFF1D1879),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 Header atas
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "ZON4",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.white24,
                                offset: Offset(0, 3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.crop, color: Colors.white, size: 26),
                      onPressed: () => _cropImage(context),
                    ),
                  ],
                ),
              ),

              // 🔹 Gambar
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  "Lanjutkan untuk crop foto anda",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

