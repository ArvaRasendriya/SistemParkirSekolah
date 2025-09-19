// lib/pages/sim_scanner.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SimScannerPage extends StatefulWidget {
  const SimScannerPage({Key? key}) : super(key: key);

  @override
  State<SimScannerPage> createState() => _SimScannerPageState();
}

class _SimScannerPageState extends State<SimScannerPage> {
  CameraController? _controller;
  Future<void>? _initializeFuture;

  bool _processing = false;
  bool _simDetected = false;
  String? _lastOcrPreview;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      _initializeFuture = _controller!.initialize();
      await _initializeFuture;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  Future<void> _captureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _processing = true;
      _simDetected = false;
      _lastOcrPreview = null;
    });

    try {
      // Ambil foto
      final XFile picture = await _controller!.takePicture();

      // Baca bytes foto
      final bytes = await picture.readAsBytes();

      // Kirim ke backend OCR (ganti URL dengan alamat backend kamu)
      final uri = Uri.parse('http://your-deno-server/ocr');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'sim.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);

        final text = data['text'] as String? ?? '';

        debugPrint('OCR Result from backend:\n$text');

        final detected = _isSimText(text);

        setState(() {
          _simDetected = detected;
          _lastOcrPreview = text
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .take(3)
              .join(' ');
        });

        if (detected) {
          // Kembalikan foto ke halaman sebelumnya
          if (mounted) Navigator.of(context).pop(picture);
        } else {
          // Jika tidak terdeteksi, beri feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('SIM tidak terdeteksi, coba lagi')),
            );
          }
        }
      } else {
        debugPrint('OCR backend error: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memproses OCR')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capture and scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat scan')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  bool _isSimText(String text) {
    final lower = text.toLowerCase();

    final hasSimPhrase = lower.contains('surat') && lower.contains('izin');
    final hasSim = lower.contains('sim');
    final hasIndonesia = lower.contains('indonesia');

    final nikRegex = RegExp(r'\b\d{12,16}\b');
    final hasNik = nikRegex.hasMatch(lower);

    return ((hasSimPhrase || hasSim) && hasIndonesia) || hasNik;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null &&
              _controller!.value.isInitialized) {
            return Stack(
              children: [
                CameraPreview(_controller!),
                Center(
                  child: Container(
                    width: 320,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _simDetected ? Colors.greenAccent : Colors.white70,
                        width: 3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      Text(
                        _processing
                            ? 'Memproses OCR...'
                            : _simDetected
                                ? 'SIM terdeteksi'
                                : 'Arahkan SIM ke kotak dan tekan tombol foto',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      if (_lastOcrPreview != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _lastOcrPreview!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _processing ? null : _captureAndScan,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Ambil Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 12,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}