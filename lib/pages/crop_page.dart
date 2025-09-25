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
          toolbarTitle: 'Crop SIM/KTP',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop SIM/KTP',
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
      appBar: AppBar(title: const Text("Crop Gambar")),
      body: Column(
        children: [
          Expanded(child: Image.file(imageFile)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _cropImage(context),
              icon: const Icon(Icons.crop),
              label: const Text("Crop"),
            ),
          ),
        ],
      ),
    );
  }
}
