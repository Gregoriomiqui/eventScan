import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerWidget extends StatefulWidget {
  const QrScannerWidget({
    super.key,
    required this.onDetect,
    this.enabled = true,
  });

  final ValueChanged<String> onDetect;
  final bool enabled;

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  late final MobileScannerController _controller;
  String _lastCode = '';
  DateTime _lastReadAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _retryCamera() async {
    if (_isRetrying) {
      return;
    }

    setState(() => _isRetrying = true);

    try {
      await _controller.stop();
      await _controller.start();
    } catch (_) {
      // Keep UI responsive even if restart fails once; user can retry again.
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere(
          (value) => value.trim().isNotEmpty,
          orElse: () => '',
        );

    if (code.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final repeatedTooFast =
        code == _lastCode && now.difference(_lastReadAt).inMilliseconds < 1200;

    if (repeatedTooFast) {
      return;
    }

    _lastCode = code;
    _lastReadAt = now;
    widget.onDetect(code);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Escaner pausado durante la transaccion.')),
      );
    }

    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MobileScanner(
          controller: _controller,
          onDetect: _handleDetection,
          errorBuilder: (context, error) {
            return ColoredBox(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off, color: Colors.white),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'No se pudo iniciar la camara del emulador.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _isRetrying ? null : _retryCamera,
                      child: Text(
                        _isRetrying ? 'Reintentando...' : 'Reintentar camara',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
