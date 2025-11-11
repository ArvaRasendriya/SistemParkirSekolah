import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'preview.dart';

class CropPage extends StatefulWidget {
  final File imageFile;

  const CropPage({super.key, required this.imageFile});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

Future<void> _cropImage() async {
final cropped = await ImageCropper().cropImage(
  sourcePath: widget.imageFile.path,
  aspectRatio: null,
  uiSettings: [
    AndroidUiSettings(
      toolbarTitle: 'Crop SIM',
      toolbarColor: const Color(0xFF3F37C9),
      statusBarColor: const Color(0xFF1D1879),
      toolbarWidgetColor: Colors.white,
      hideBottomControls: false,
      backgroundColor: Colors.black,
      showCropGrid: true,
      initAspectRatio: CropAspectRatioPreset.original,
      lockAspectRatio: false,
      activeControlsWidgetColor: const Color(0xFF4CAF50),
    ),
    IOSUiSettings(
      title: 'Crop SIM',
      aspectRatioPickerButtonHidden: false,
      resetButtonHidden: false,
      rotateButtonsHidden: false,
    ),
  ],
);


  if (cropped == null) return;

  // 👇 Tambahkan bagian ini setelah crop selesai
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PreviewPage(
        croppedFile: File(cropped.path),
        originalFile: widget.imageFile,
        onConfirm: (file) {
          Navigator.pop(context, file);
        },
      ),
    ),
  );

  // ✅ kalau user klik “Ulangi”
  if (result == 'retake') {
    _cropImage(); // panggil lagi crop tanpa buat halaman baru
    return;
  }

  // ✅ kalau user confirm (hasil foto dikirim)
  if (result is File && mounted) {
    Navigator.pop(context, result);
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
          child: Stack(
            children: [
              Column(
                children: [
                  // Header
                  _buildHeader(),

                  const SizedBox(height: 20),

                  // Image Preview
                  Expanded(
                    child: _buildImagePreview(),
                  ),

                  const SizedBox(height: 20),

                  // Instructions
                  _buildInstructions(),

                  const SizedBox(height: 24),

                  // Action Button
                  _buildCropButton(),

                  const SizedBox(height: 32),
                ],
              ),

              // Loading Overlay
              if (_isCropping) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Back Button
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _isCropping ? null : () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back,
                  color: _isCropping ? Colors.white54 : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Title
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.crop,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "ZON4",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          const SizedBox(width: 44), // Balance
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Image.file(
          widget.imageFile,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Perlu di-crop?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Tekan tombol crop untuk memotong foto",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFeatureChip(Icons.rotate_right, "Rotasi"),
              const SizedBox(width: 8),
              _buildFeatureChip(Icons.aspect_ratio, "Rasio"),
              const SizedBox(width: 8),
              _buildFeatureChip(Icons.grid_on, "Grid"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Crop button (primary)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isCropping ? null : _cropImage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isCropping
                        ? [
                            Colors.grey.shade400,
                            Colors.grey.shade500,
                          ]
                        : [
                            const Color(0xFF4CAF50),
                            const Color(0xFF66BB6A),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isCropping
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isCropping)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(
                        Icons.crop,
                        color: Colors.white,
                        size: 28,
                      ),
                    const SizedBox(width: 12),
                    Text(
                      _isCropping ? "Memproses..." : "Lanjutkan Crop Foto",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Use as-is button (secondary)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isCropping ? null : () {
                // Langsung return foto original tanpa crop
                Navigator.pop(context, widget.imageFile);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Pakai Foto Ini Saja",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF3F37C9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 4,
              ),
              SizedBox(height: 24),
              Text(
                'Membuka Editor...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Mohon tunggu sebentar',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}