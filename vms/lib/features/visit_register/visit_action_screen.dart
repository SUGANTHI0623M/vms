import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/visit_service.dart';
import '../../widgets/app_common_widgets.dart';

class VisitActionScreen extends StatefulWidget {
  final int visitId;
  final bool isCheckIn;
  final VoidCallback onSuccess;

  const VisitActionScreen({
    super.key,
    required this.visitId,
    required this.isCheckIn,
    required this.onSuccess,
  });

  @override
  State<VisitActionScreen> createState() => _VisitActionScreenState();
}

class _VisitActionScreenState extends State<VisitActionScreen> {
  File? _imageFile;
  bool _isLoading = false;
  final _picker = ImagePicker();
  
  // Controllers for Check-In mode (if we want to show/edit details, though usually existing visits have them)
  // For now, based on "exclude in checkout", we assume we might show them in checkin or just keep the UI consistent.
  // Since it's an existing visit, the user probably doesn't need to re-enter Company/Purpose unless updating.
  // However, to match the UI of "New Visit", I will include placeholders or empty fields if it's Check-In, 
  // but if it's an *existing* visit, maybe we should fetch and show?
  // The user instruction "exclude company name purpose of visit in checkout" implies they *might* be there for checkin.
  // But for an existing visit, we don't usually edit these on checkin. 
  // I will hide them for now for simplicity and just focus on the visual style (Location + Selfie), 
  // as updating visit details during check-in wasn't explicitly requested, just the UI style.
  // Wait, if I hide them for Check-In too, it won't look *exactly* like the screenshot which has them.
  // But providing empty fields for an existing visit is confusing.
  // I'll stick to: Hide for Checkout. Show for Checkin (maybe read-only or just hidden if not relevant).
  // Actually, for "Check In" of an existing visit, usually you just confirm presence. 
  // I'll hide them for both for now to be safe, or just follow "exclude in checkout" strictly.
  // Let's hide for both because typically you don't edit purpose at the gate for a pre-approved visit. 
  // The "New Visit" screen creates a visit. This action creates a "Check In" event.
  // If the user *really* wants the fields, they would have said "allow editing". 
  // I will hide them for both to avoid confusion, but use the large layout.
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<LocationService>();
      if (loc.currentPosition == null) {
        loc.fetchLocation();
      }
    });
  }

  Future<void> _takeSelfie() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 600,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitAction() async {
    final locationService = context.read<LocationService>();
    final currentPosition = locationService.currentPosition;
    final currentAddress = locationService.currentAddress;

    if (_imageFile == null || currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_imageFile == null ? 'Selfie is required.' : 'Location not found. Please wait or retry.'),
          backgroundColor: AppColors.error,
        ),
      );
      if (currentPosition == null) locationService.fetchLocation();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthService>().token;
      final visitService = VisitService();
      
      bool success;
      if (widget.isCheckIn) {
        success = await visitService.checkIn(
          widget.visitId, 
          currentPosition.latitude, 
          currentPosition.longitude, 
          _imageFile!, 
          token!,
          address: currentAddress
        );
      } else {
        success = await visitService.checkOut(
          widget.visitId, 
          currentPosition.latitude, 
          currentPosition.longitude, 
          _imageFile!, 
          token!,
          address: currentAddress
        );
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isCheckIn ? 'Checked In Successfully' : 'Checked Out Successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          widget.onSuccess();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action failed. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: CommonAppBar(title: widget.isCheckIn ? 'Visit Check-In' : 'Visit Check-Out'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locationService.currentAddress ?? "Fetching location...",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (currentPosition != null)
                                Text(
                                  'Lat: ${currentPosition.latitude.toStringAsFixed(4)}, Long: ${currentPosition.longitude.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: isDark ? Colors.grey[400] : Colors.grey[600]
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (locationService.isLoading)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Selfie Area
            AspectRatio(
              aspectRatio: 1, // Square
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
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
                    ? InkWell(
                        onTap: _takeSelfie,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 64,
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to Take Selfie',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  color: primaryColor,
                                ),
                                onPressed: _takeSelfie,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitAction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: primaryColor, // Theme color
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Text(
                      widget.isCheckIn ? 'Confirm Check-In' : 'Confirm Check-Out',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
