import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../widgets/app_common_widgets.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  File? _imageFile;
  // Position managed by LocationService
  bool _isLoading = false;
  final _picker = ImagePicker();
  final _purposeController = TextEditingController();
  // Hardcoded agent ID for demo purposes, in real app this would be a selection
  final int _agentId = 1;

  @override
  void initState() {
    super.initState();
    // Location is fetched globally in main.dart
  }

  Future<void> _takeSelfie() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 600, // Optimize size
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitCheckIn() async {
    final locationService = context.read<LocationService>();
    final currentPosition = locationService.currentPosition;

    if (_imageFile == null || currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selfie and Location are required.')),
      );
      if (currentPosition == null) locationService.fetchLocation();
      return;
    }

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.checkIn}');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${authService.token}';
    request.fields['agent_id'] = _agentId.toString();
    request.fields['check_in_latitude'] = currentPosition.latitude.toString();
    request.fields['check_in_longitude'] = currentPosition.longitude.toString();
    if (_purposeController.text.isNotEmpty) {
      request.fields['purpose'] = _purposeController.text;
    }

    request.files.add(
      await http.MultipartFile.fromPath('selfie', _imageFile!.path),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-In Successful!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-In Failed.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('Check-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network Error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final currentPosition = locationService.currentPosition;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Vendor Check-In'),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentPosition != null
                                ? 'Lat: ${currentPosition.latitude.toStringAsFixed(4)}, Long: ${currentPosition.longitude.toStringAsFixed(4)}'
                                : (locationService.isLoading
                                      ? 'Fetching Location...'
                                      : 'Location Not Found'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Selfie Preview
            AspectRatio(
              aspectRatio: 1, // Square
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _takeSelfie,
                            child: const Text('Tap to Take Selfie'),
                          ),
                        ],
                      )
                    : Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: AppColors.primary,
                                ),
                                onPressed: _takeSelfie,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose of Visit (Optional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitCheckIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirm Check-In',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
