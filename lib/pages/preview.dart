import 'dart:io';
import 'package:flutter/material.dart';
import 'crop_page.dart';

class PreviewPage extends StatelessWidget {
  final File croppedFile;

  const PreviewPage({super.key, required this.croppedFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview")),
      body: Center(
        child: Image.file(croppedFile),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CropPage(imageFile: croppedFile),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Ulangi"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context, croppedFile);
              },
              icon: const Icon(Icons.check),
              label: const Text("Gunakan"),
            ),
          ],
        ),
      ),
    );
  }
}
