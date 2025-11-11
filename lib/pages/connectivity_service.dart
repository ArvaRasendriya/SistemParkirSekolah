import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  final Duration onlineBannerDuration;
  final Color offlineColor;
  final Color onlineColor;

  const ConnectivityBanner({
    super.key,
    required this.child,
    this.onlineBannerDuration = const Duration(seconds: 2),
    this.offlineColor = const Color(0xFFDC2626),
    this.onlineColor = const Color(0xFF16A34A),
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;
  bool _showBanner = false;
  bool _hasInitialized = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _setupListener();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final isOffline = _isConnectivityOffline(result);
      if (mounted) {
        setState(() {
          _isOffline = isOffline;
          _hasInitialized = true;
          _showBanner = isOffline;
        });
      }
    } catch (e) {
      debugPrint('Error initializing connectivity: $e');
      if (mounted) setState(() => _hasInitialized = true);
    }
  }

  void _setupListener() {
    _subscription =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (!_hasInitialized || !mounted) return;
    final isOffline = _isConnectivityOffline(results);

    if (_isOffline != isOffline) {
      setState(() {
        _isOffline = isOffline;
        _showBanner = true;
      });

      if (!isOffline) {
        _scheduleHideBanner();
      } else {
        _cancelHideTimer();
      }
    }
  }

  bool _isConnectivityOffline(List<ConnectivityResult> results) {
    return results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  }

  void _scheduleHideBanner() {
    _cancelHideTimer();
    _hideTimer = Timer(widget.onlineBannerDuration, () {
      if (mounted && !_isOffline) {
        setState(() => _showBanner = false);
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  @override
  void dispose() {
    _cancelHideTimer();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bannerHeight = 48.0;

    return Column(
      children: [
        // Child utama
        Expanded(child: widget.child),

        // Banner (dengan animasi tinggi, bukan Stack)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: _showBanner ? bannerHeight : 0,
          child: ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: _showBanner ? 1 : 0,
              child: _ConnectivityBannerContent(
                isOffline: _isOffline,
                offlineColor: widget.offlineColor,
                onlineColor: widget.onlineColor,
                height: bannerHeight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectivityBannerContent extends StatelessWidget {
  final bool isOffline;
  final Color offlineColor;
  final Color onlineColor;
  final double height;

  const _ConnectivityBannerContent({
    required this.isOffline,
    required this.offlineColor,
    required this.onlineColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOffline ? offlineColor : onlineColor,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isOffline ? 'Tidak ada koneksi internet' : 'Kembali online',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (!isOffline) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
