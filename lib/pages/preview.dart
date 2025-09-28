import 'dart:io';
import 'package:flutter/material.dart';
import 'crop_page.dart';

class PreviewPage extends StatelessWidget {
  final File croppedFile;

  const PreviewPage({super.key, required this.croppedFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Preview"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027), // hitam kebiruan
              Color(0xFF203443), // biru gelapan
              Color(0xFF2C5364), // biru gradasi
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Hero(
            tag: "previewImage",
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                croppedFile,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF203443),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  elevation: 6,
                  shadowColor: Colors.black54,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 400),
                      pageBuilder: (_, __, ___) =>
                          CropPage(imageFile: croppedFile),
                      transitionsBuilder:
                          (_, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  "Ulangi",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  elevation: 6,
                  shadowColor: Colors.black54,
                ),
                onPressed: () {
                  Navigator.pop(context, croppedFile);
                },
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  "Gunakan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
