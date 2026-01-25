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
import '../../services/visit_service.dart';
import '../../services/vendor_service.dart';
import 'qr_code_scanner_screen.dart';

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
  
  // Use a String to hold the current company input because Autocomplete manages its own controller in view builder
  // BUT we want to initialize it or allow editing. 
  // We will sync changes from Autocomplete's text field to this variable.
  String _companyName = '';
  
  List<String> _companyOptions = [];

  @override
  void initState() {
    super.initState();
    // Location is fetched globally in main.dart or dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<LocationService>();
      if (loc.currentPosition == null) {
        loc.fetchLocation();
      }
      _fetchCompanyHistory();
    });
  }
  
  Future<void> _fetchCompanyHistory() async {
    final token = context.read<AuthService>().token;
    if (token == null) return;
    
    final service = VisitService();
    final visits = await service.getMyVisits(token);
    
    if (visits != null) {
      final Set<String> companies = {};
      for (var v in visits) {
        // Parse "Visiting: Company Name. Purpose"
        final purpose = (v['purpose'] ?? '').toString();
        if (purpose.startsWith('Visiting: ')) {
          // Extract company name
          // E.g. "Visiting: Google. Meeting" -> "Google"
          // E.g. "Visiting: Google" -> "Google"
          var name = purpose.substring(10); // Remove "Visiting: "
          if (name.contains('.')) {
            name = name.split('.')[0];
          }
          name = name.trim();
          if (name.isNotEmpty) {
            companies.add(name);
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _companyOptions = companies.toList()..sort();
        });
      }
    }
  }

  Future<void> _takeSelfie() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 600, // Optimize size
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _scanQrCode() async {
    final token = context.read<AuthService>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to scan QR code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show QR code scanner
    if (!mounted) return;
    
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QrCodeScannerScreen(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Validate QR code with backend
      setState(() => _isLoading = true);
      
      try {
        final vendorService = VendorService(token);
        final qrResult = await vendorService.scanQrCode(result);
        
        if (qrResult != null && qrResult['valid'] == true) {
          final companyName = qrResult['company_name'] as String?;
          final isVerified = qrResult['is_verified'] == true;
          
          if (companyName != null && companyName.isNotEmpty) {
            if (isVerified) {
              setState(() {
                _companyName = companyName;
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('QR Code scanned successfully: $companyName'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Company is not verified. Please contact the company.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid QR code data'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid or expired QR code'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        print('QR code scan error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error validating QR code: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitCheckIn() async {
    final locationService = context.read<LocationService>();
    final currentPosition = locationService.currentPosition;

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

    final authService = context.read<AuthService>();
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.checkIn}');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${authService.token}';
    
    request.fields['check_in_latitude'] = currentPosition.latitude.toString();
    request.fields['check_in_longitude'] = currentPosition.longitude.toString();
    
    // Add Company Name and Purpose
    if (_companyName.isNotEmpty) {
      request.fields['company_name'] = _companyName;
    }
    
    if (_purposeController.text.isNotEmpty) {
      request.fields['purpose'] = _purposeController.text;
    }
    
    // Add Address components if available (optional but good for backend)
    final parts = locationService.addressParts;
    // For saving full address in check_in_location
    if (locationService.currentAddress != null) {
      request.fields['check_in_location'] = locationService.currentAddress!;
    }
    
    if (parts.isNotEmpty) {
      if (parts['city']?.isNotEmpty == true) request.fields['city'] = parts['city']!;
      if (parts['state']?.isNotEmpty == true) request.fields['state'] = parts['state']!;
      if (parts['pincode']?.isNotEmpty == true) request.fields['pincode'] = parts['pincode']!;
      if (parts['area']?.isNotEmpty == true) request.fields['area'] = parts['area']!;
    }

    request.files.add(
      await http.MultipartFile.fromPath('selfie', _imageFile!.path),
    );

    try {
      print('Sending Check-In Request...');
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      print('Check-In Response: ${response.statusCode} - $respStr');

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
          String errorMsg = 'Check-In Failed (${response.statusCode})';
          try {
            if (respStr.contains("detail")) {
              final start = respStr.indexOf('"detail":"');
              if (start != -1) {
                final end = respStr.indexOf('"', start + 10);
                if (end != -1) {
                  errorMsg = respStr.substring(start + 10, end);
                }
              }
            }
          } catch (_) {}
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Check-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network Error: $e'),
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

    return Scaffold(
      appBar: const CommonAppBar(title: 'New Visit Check-In'),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary),
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

            // Selfie Preview
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

            // QR Code Scan Button
            OutlinedButton.icon(
              onPressed: _scanQrCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Company QR Code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppColors.primary),
              ),
            ),

            const SizedBox(height: 16),

            // Company AutoComplete
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return _companyOptions.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                setState(() => _companyName = selection);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                // Ensure the controller has the current value if needed, but usually 
                // textEditingController manages it. We just need to sync back to _companyName
                // when typed manually.
                
                // Add listener once to sync manually typed values
                // But fieldViewBuilder is called on build, so don't add listeners repeatedly.
                // Actually, the best way is to assign onChanged to the TextField.
                
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onSubmitted: (_) => onFieldSubmitted(),
                  onChanged: (val) {
                    _companyName = val;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Company/Client Name (Optional)',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose of Visit (Optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitCheckIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text(
                      'Confirm Check-In',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
