import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCodeScannerScreen extends StatefulWidget {
  const QrCodeScannerScreen({super.key});

  @override
  State<QrCodeScannerScreen> createState() => _QrCodeScannerScreenState();
}

class _QrCodeScannerScreenState extends State<QrCodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _torchEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    controller.toggleTorch();
  }

  void _switchCamera() {
    setState(() {
      _cameraFacing = _cameraFacing == CameraFacing.back 
          ? CameraFacing.front 
          : CameraFacing.back;
    });
    controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: _torchEnabled ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: Icon(
              _cameraFacing == CameraFacing.back 
                  ? Icons.camera_rear 
                  : Icons.camera_front,
              color: Colors.white,
            ),
            onPressed: _switchCamera,
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // Return the scanned QR code data
                  Navigator.pop(context, barcode.rawValue);
                  return;
                }
              }
            },
          ),
          // Overlay with scanning area
          CustomPaint(
            painter: QrScannerOverlay(),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position the QR code within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    // Draw overlay with cutout
    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;
    
    // Draw top rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, scanAreaTop),
      paint,
    );
    
    // Draw bottom rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, scanAreaTop + scanAreaSize, size.width, size.height - scanAreaTop - scanAreaSize),
      paint,
    );
    
    // Draw left rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, scanAreaTop, scanAreaLeft, scanAreaSize),
      paint,
    );
    
    // Draw right rectangle
    canvas.drawRect(
      Rect.fromLTWH(scanAreaLeft + scanAreaSize, scanAreaTop, size.width - scanAreaLeft - scanAreaSize, scanAreaSize),
      paint,
    );
    
    // Draw corner brackets
    final cornerLength = 30.0;
    final cornerWidth = 4.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke;
    
    // Top-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop),
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerLength),
      cornerPaint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - cornerLength),
      cornerPaint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
