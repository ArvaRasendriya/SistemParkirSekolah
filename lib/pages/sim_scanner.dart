// lib/pages/sim_scanner.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class SimScannerPage extends StatefulWidget {
  const SimScannerPage({Key? key}) : super(key: key);

  @override
  State<SimScannerPage> createState() => _SimScannerPageState();
}

class _SimScannerPageState extends State<SimScannerPage> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  Timer? _captureTimer;
  bool _processing = false;
  bool _simDetected = false;
  String? _lastOcrPreview;

  // ganti ini dengan URL function Vercel mu setelah deploy
  static const String ocrEndpoint = 'https://<YOUR_VERCEL_DEPLOYMENT>/api/ocr';

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);

      _controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      _initializeFuture = _controller!.initialize();
      await _initializeFuture;

      // mulai timer untuk auto-capture tiap 1400ms
      _captureTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) => _maybeCapture());
      setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  Future<void> _maybeCapture() async {
    if (_processing || _simDetected || _controller == null || !_controller!.value.isInitialized) return;
    _processing = true;
    try {
      // ambil foto resolusi medium/high
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      // kirim ke OCR endpoint
      final detected = await _sendToOcrAndCheck(bytes);

      if (detected) {
        _simDetected = true;
        // delay kecil supaya user lihat indikator
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          // kembalikan file ke pemanggil (DaftarPage)
          Navigator.of(context).pop(file);
        }
      } else {
        // optional: update preview snippet
      }
    } catch (e) {
      debugPrint('Error in auto-capture: $e');
    } finally {
      _processing = false;
    }
  }

  Future<bool> _sendToOcrAndCheck(Uint8List bytes) async {
    try {
      final base64Img = base64Encode(bytes);
      final resp = await http.post(
        Uri.parse(ocrEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Img}),
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final Map<String, dynamic> j = jsonDecode(resp.body);
        final bool simDetected = j['simDetected'] == true;
        final String ocrText = (j['text'] ?? '').toString();
        if (mounted) setState(() => _lastOcrPreview = ocrText.split('\n').where((s)=>s.trim().isNotEmpty).take(3).join(' '));
        return simDetected;
      } else {
        debugPrint('OCR endpoint error: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error sending to OCR: $e');
    }
    return false;
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
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
          if (snapshot.connectionState == ConnectionState.done && _controller != null && _controller!.value.isInitialized) {
            return Stack(
              children: [
                CameraPreview(_controller!),

                // overlay kotak fokus di tengah
                Center(
                  child: Container(
                    width: 320,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _simDetected ? Colors.greenAccent : Colors.white70,
                        width: 3,
                      ),
                    ),
                  ),
                ),

                // hint & preview OCR kecil
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      Text(
                        _simDetected ? 'SIM terdeteksi — mengambil foto...' : 'Arahkan SIM ke kotak (auto capture)',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      if (_lastOcrPreview != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _lastOcrPreview!,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                // tombol close
                Positioned(
                  top: 40,
                  left: 12,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),

                // manual capture tombol (opsional)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () async {
                      if (_processing || _controller == null) return;
                      _processing = true;
                      try {
                        final XFile file = await _controller!.takePicture();
                        final bytes = await file.readAsBytes();
                        final detected = await _sendToOcrAndCheck(bytes);
                        if (detected) {
                          if (mounted) Navigator.of(context).pop(file);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak terdeteksi sebagai SIM')));
                        }
                      } catch (e) {
                        debugPrint('Manual capture error: $e');
                      } finally {
                        _processing = false;
                      }
                    },
                    child: const Icon(Icons.camera_alt),
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
