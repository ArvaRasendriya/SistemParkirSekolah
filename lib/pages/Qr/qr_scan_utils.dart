import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'qr_result_page.dart';

Future<void> playBeep(AudioPlayer player) async {
  try {
    if (kIsWeb) {
      await player.play(UrlSource("assets/sounds/beep.mp3"));
    } else {
      await player.play(AssetSource("sounds/beep.mp3"));
    }
  } catch (e) {
    debugPrint("Audio error: $e");
  }
}

Future<void> vibrate() async {
  try {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  } catch (e) {
    debugPrint("Vibration error: $e");
  }
}

bool isValidUuid(String input) {
  try {
    Uuid.parse(input);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> fetchUserAndNavigate({
  required BuildContext context,
  required SupabaseClient supabase,
  required String userId,
}) async {
  if (!isValidUuid(userId)) {
    // QR tidak valid
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(
            userData: {},
            isApproved: false,
            message: "QR Code tidak valid",
          ),
        ),
      );
    }
    return;
  }

  try {
    final user = await supabase
        .from('siswa')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (user == null) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultPage(
              userData: {},
              isApproved: false,
              message: "Siswa tidak ditemukan",
            ),
          ),
        );
      }
      return;
    }

    final result = await _logScan(supabase, userId);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(
            userData: user,
            isApproved: result.isApproved,
            message: result.message,
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(
            userData: {},
            isApproved: false,
            message: "Error: $e",
          ),
        ),
      );
    }
  }
}

/// Hasil log scan
class _LogScanResult {
  final bool isApproved;
  final String? message;
  _LogScanResult({required this.isApproved, this.message});
}

Future<_LogScanResult> _logScan(SupabaseClient supabase, String siswaId) async {
  try {
    final lastScan = await supabase
        .from('parkir')
        .select('created_at')
        .eq('siswa_id', siswaId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (lastScan != null) {
      final lastTime = DateTime.parse(lastScan['created_at']).toLocal();
      final diff = DateTime.now().difference(lastTime);
      final cooldownHours = 15;
      final remaining = Duration(hours: cooldownHours) - diff;
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;

      if (diff.inHours < cooldownHours) {
        // Reject jika masih dalam cooldown 15 jam
        return _LogScanResult(
          isApproved: false,
          message: "Siswa sudah parkir. Sisa cooldown: ${hours} jam ${minutes} menit",
        );
      }
    }

    // Insert baru jika lolos cooldown
    await supabase.from('parkir').insert({
      'siswa_id': siswaId,
      'scanned_by': supabase.auth.currentUser?.email ?? supabase.auth.currentUser?.id,
    });

    return _LogScanResult(
      isApproved: true,
      message: "Scan berhasil, Approved",
    );
  } catch (e) {
    debugPrint('Failed to log scan: $e');
    return _LogScanResult(
      isApproved: false,
      message: "Gagal log scan: $e",
    );
  }
}


class QrScanAnimations {
  late AnimationController scanLineController;
  late AnimationController pulseController;
  late AnimationController successController;
  late Animation<double> scanLineAnimation;
  late Animation<double> pulseAnimation;
  late Animation<double> successAnimation;

  QrScanAnimations(TickerProvider vsync) {
    scanLineController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: scanLineController,
        curve: Curves.easeInOut,
      ),
    );

    pulseController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: pulseController,
        curve: Curves.easeInOut,
      ),
    );

    successController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500),
    );
    
    successAnimation = CurvedAnimation(
      parent: successController,
      curve: Curves.easeOutBack,
    );
  }

  void dispose() {
    scanLineController.dispose();
    pulseController.dispose();
    successController.dispose();
  }
}