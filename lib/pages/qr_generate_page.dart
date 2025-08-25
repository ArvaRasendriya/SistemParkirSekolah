import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/user_data.dart';

class QrGeneratePage extends StatelessWidget {
  final UserData userData;

  const QrGeneratePage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final dataString = jsonEncode(userData.toJson());

    return Scaffold(
      appBar: AppBar(title: const Text("QR Code Anda")),
      body: Center(
        child: QrImageView(
          data: dataString,
          version: QrVersions.auto,
          size: 250,
        ),
      ),
    );
  }
}
