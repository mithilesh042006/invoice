import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Conditional import: mobile_scanner only works on Android/iOS/macOS
import 'package:mobile_scanner/mobile_scanner.dart'
    if (dart.library.io) 'package:mobile_scanner/mobile_scanner.dart';

/// Whether the current platform supports camera-based barcode scanning.
/// mobile_scanner works on Android, iOS, macOS — NOT on Windows or Linux.
bool get _isCameraSupported =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

/// Barcode scanner screen with two modes:
/// 1. **Camera mode** — live camera scanning (Android / iOS / macOS only)
/// 2. **Manual mode** — text input for USB barcode scanners / manual typing
///
/// On Windows/Linux, only manual mode is available since mobile_scanner
/// doesn't have a native Windows implementation.
///
/// Returns the scanned barcode string via Navigator.pop(), or null if cancelled.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late bool _useCameraMode;
  bool _hasScanned = false;
  MobileScannerController? _cameraController;

  // Manual input
  final _barcodeCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Default to camera on supported platforms, manual on Windows/Linux
    _useCameraMode = _isCameraSupported;
    if (_useCameraMode) {
      _cameraController = MobileScannerController();
    }

    if (!_useCameraMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _hasScanned = true;
      Navigator.pop(context, barcodes.first.rawValue!);
    }
  }

  void _submitManual() {
    final code = _barcodeCtrl.text.trim();
    if (code.isNotEmpty) {
      Navigator.pop(context, code);
    }
  }

  void _toggleMode() {
    if (!_isCameraSupported) return; // Can't toggle on unsupported platforms
    setState(() {
      _useCameraMode = !_useCameraMode;
      if (_useCameraMode && _cameraController == null) {
        _cameraController = MobileScannerController();
      }
      if (!_useCameraMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _useCameraMode ? Colors.black : AppColors.background,
      appBar: AppBar(
        title: Text(_useCameraMode ? 'Scan Barcode' : 'Enter Barcode'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Only show toggle on platforms that support camera
          if (_isCameraSupported)
            IconButton(
              icon: Icon(_useCameraMode ? Icons.keyboard : Icons.camera_alt),
              tooltip: _useCameraMode ? 'Type manually' : 'Use camera',
              onPressed: _toggleMode,
            ),
          if (_useCameraMode && _cameraController != null) ...[
            IconButton(
              icon: const Icon(Icons.flash_on),
              tooltip: 'Toggle Flash',
              onPressed: () => _cameraController!.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              tooltip: 'Switch Camera',
              onPressed: () => _cameraController!.switchCamera(),
            ),
          ],
        ],
      ),
      body: _useCameraMode ? _buildCameraView() : _buildManualInput(),
    );
  }

  // ── Camera Mode (Android / iOS / macOS only) ──
  Widget _buildCameraView() {
    if (_cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _cameraController!,
          onDetect: _onDetect,
        ),

        // Scan region overlay
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 2.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.center_focus_strong,
                      color: AppColors.accent, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Point the camera at a barcode',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        // Bottom toggle
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: TextButton.icon(
                onPressed: _toggleMode,
                icon:
                    const Icon(Icons.keyboard, color: Colors.white70, size: 20),
                label: const Text('Type barcode manually',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Manual Input Mode ──
  Widget _buildManualInput() {
    final isDesktop = Platform.isWindows || Platform.isLinux;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      size: 48, color: AppColors.accent),
                ),
                const SizedBox(height: 20),

                Text(
                  isDesktop ? 'Scan with USB Scanner' : 'Enter Barcode',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isDesktop
                      ? 'Connect a USB barcode scanner and scan any product.\n'
                        'The barcode will appear below and auto-submit.'
                      : 'Type the barcode number manually.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Barcode input field
                TextField(
                  controller: _barcodeCtrl,
                  focusNode: _focusNode,
                  autofocus: true,
                  onSubmitted: (_) => _submitManual(),
                  style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'e.g., 8901234567890',
                    hintStyle: const TextStyle(
                        letterSpacing: 1, fontWeight: FontWeight.normal),
                    prefixIcon:
                        const Icon(Icons.qr_code, color: AppColors.accent),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.primary),
                      tooltip: 'Submit',
                      onPressed: _submitManual,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _submitManual,
                    icon: const Icon(Icons.search),
                    label: const Text('Look Up Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                // Camera toggle (only on supported mobile platforms)
                if (_isCameraSupported) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _toggleMode,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Switch to camera'),
                  ),
                ],

                // Desktop USB scanner info
                if (isDesktop) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.usb, color: AppColors.info, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'USB barcode scanners work like a keyboard — just scan and the code appears here automatically.',
                            style:
                                TextStyle(color: AppColors.info, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
