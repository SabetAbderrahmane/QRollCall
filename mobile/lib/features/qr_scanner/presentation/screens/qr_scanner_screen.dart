import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/qr_scanner/models/scan_result_models.dart';
import 'package:qrollcall_mobile/features/qr_scanner/presentation/controllers/qr_scanner_controller.dart';
import 'package:qrollcall_mobile/features/qr_scanner/presentation/screens/scan_failure_screen.dart';
import 'package:qrollcall_mobile/features/qr_scanner/presentation/screens/scan_success_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _cameraController;
  late final AnimationController _scanLineController;
  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  bool _hasHandledBarcode = false;
  bool _isTorchEnabled = false;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();

    _cameraController = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      formats: const [BarcodeFormat.qrCode],
      torchEnabled: false,
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _barcodeSubscription = _cameraController.barcodes.listen(_onBarcodeCapture);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanner();
    });
  }

  @override
  void dispose() {
    _barcodeSubscription?.cancel();
    _scanLineController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _startScanner() async {
    if (!mounted) return;

    setState(() {
      _cameraErrorMessage = null;
      _hasHandledBarcode = false;
    });

    context.read<QrScannerController>().reset();

    try {
      await _cameraController.start();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cameraErrorMessage =
            'Unable to start the camera. Check camera permission and try again.';
      });
    }
  }

  Future<void> _onBarcodeCapture(BarcodeCapture capture) async {
    if (_hasHandledBarcode || capture.barcodes.isEmpty || !mounted) {
      return;
    }

    final rawValue = capture.barcodes.first.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    _hasHandledBarcode = true;
    await _cameraController.stop();

    final outcome = await context
        .read<QrScannerController>()
        .processDetectedValue(rawValue);

    if (!mounted) return;

    final action = await _presentScanOutcome(outcome);

    if (!mounted) return;

    if (action == null || action == ScanFlowExitAction.retry) {
      await _startScanner();
      return;
    }

    Navigator.of(context).pop(action);
  }

  Future<ScanFlowExitAction?> _presentScanOutcome(
    ScanProcessOutcome outcome,
  ) {
    if (outcome is ScanSuccessOutcome) {
      return Navigator.of(context).push<ScanFlowExitAction>(
        MaterialPageRoute(
          builder: (_) => ScanSuccessScreen(data: outcome.data),
        ),
      );
    }

    final failureOutcome = outcome as ScanFailureOutcome;
    return Navigator.of(context).push<ScanFlowExitAction>(
      MaterialPageRoute(
        builder: (_) => ScanFailureScreen(data: failureOutcome.data),
      ),
    );
  }

  Future<void> _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
      if (!mounted) return;
      setState(() => _isTorchEnabled = !_isTorchEnabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Torch is unavailable on this device.'),
        ),
      );
    }
  }

  void _handleGalleryTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery-based QR import will be added in a later batch.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanController = context.watch<QrScannerController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanSize = math.min(constraints.maxWidth * 0.72, 280.0);
          final scanLeft = (constraints.maxWidth - scanSize) / 2;
          final scanTop = math.max(170.0, constraints.maxHeight * 0.24);
          final scanRect = Rect.fromLTWH(scanLeft, scanTop, scanSize, scanSize);

          return Stack(
            children: [
              Positioned.fill(
                child: _cameraErrorMessage == null
                    ? MobileScanner(controller: _cameraController)
                    : Container(
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_off_rounded,
                              color: AppColors.textSecondary,
                              size: 54,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _cameraErrorMessage!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _startScanner,
                              child: const Text('Retry camera'),
                            ),
                          ],
                        ),
                      ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScannerMaskPainter(scanRect: scanRect),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        _RoundGlassButton(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Scan QR',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: scanRect.left,
                top: scanRect.top,
                child: _ScannerFrame(
                  size: scanSize,
                  scanLineController: _scanLineController,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: scanRect.bottom + 34,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'Point your camera at the QR code displayed by your teacher or event organizer.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.92),
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 42,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FloatingActionControl(
                        onTap: _handleGalleryTap,
                        icon: Icons.photo_library_outlined,
                      ),
                      const SizedBox(width: 28),
                      _FloatingActionControl(
                        onTap: _toggleTorch,
                        icon: _isTorchEnabled
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        highlighted: _isTorchEnabled,
                      ),
                    ],
                  ),
                ),
              ),
              if (scanController.isProcessing)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withOpacity(0.52),
                      alignment: Alignment.center,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 18),
                            Text(
                              'Verifying attendance…',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Checking QR token, time window, location, and attendance status.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({
    required this.size,
    required this.scanLineController,
  });

  final double size;
  final AnimationController scanLineController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.16),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.16),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: Center(
              child: Icon(
                Icons.qr_code_rounded,
                size: 88,
                color: Color(0x3DFFFFFF),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: scanLineController,
            builder: (context, child) {
              final top = 24 + ((size - 48) * scanLineController.value);

              return Positioned(
                left: 22,
                right: 22,
                top: top.clamp(24.0, size - 24),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withOpacity(0.75),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const _ScannerCorner(alignment: Alignment.topLeft),
          const _ScannerCorner(alignment: Alignment.topRight),
          const _ScannerCorner(alignment: Alignment.bottomLeft),
          const _ScannerCorner(alignment: Alignment.bottomRight),
        ],
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  const _ScannerCorner({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTop && isLeft ? 26 : 0),
            topRight: Radius.circular(isTop && !isLeft ? 26 : 0),
            bottomLeft: Radius.circular(!isTop && isLeft ? 26 : 0),
            bottomRight: Radius.circular(!isTop && !isLeft ? 26 : 0),
          ),
          border: Border(
            top: isTop
                ? const BorderSide(
                    color: AppColors.primaryContainer,
                    width: 4,
                  )
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(
                    color: AppColors.primaryContainer,
                    width: 4,
                  )
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(
                    color: AppColors.primaryContainer,
                    width: 4,
                  )
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(
                    color: AppColors.primaryContainer,
                    width: 4,
                  )
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _FloatingActionControl extends StatelessWidget {
  const _FloatingActionControl({
    required this.onTap,
    required this.icon,
    this.highlighted = false,
  });

  final VoidCallback onTap;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? AppColors.primaryContainer
          : Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            icon,
            size: 28,
            color: highlighted ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ScannerMaskPainter extends CustomPainter {
  const _ScannerMaskPainter({required this.scanRect});

  final Rect scanRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.58);

    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanRect,
          const Radius.circular(26),
        ),
      );

    final result = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      cutoutPath,
    );

    canvas.drawPath(result, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerMaskPainter oldDelegate) {
    return oldDelegate.scanRect != scanRect;
  }
}