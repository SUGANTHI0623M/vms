import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _vendorProfile;
  List<dynamic> _documents = [];
  int _selectedTabIndex = 1; // 0: Company Details, 1: Documents
  bool _isUploading = false;
  String? _qrCodeError;

  final List<String> _mandatoryDocTypes = [
    'LOGO',
    'COMPANY_PROOF',
    'AADHAR_CARD',
    'PAN_CARD'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final token = context.read<AuthService>().token;
    if (token == null) return;

    setState(() => _isLoading = true);
    final service = VendorService(token);

    try {
      final results = await Future.wait([
        service.getVendorProfile(),
        service.getDocuments(),
      ]);

      if (mounted) {
        final profile = results[0] as Map<String, dynamic>?;
        // Check verification status (case-insensitive)
        final verificationStatus = profile?['verification_status']?.toString().toUpperCase();
        final isVerified = verificationStatus == 'VERIFIED';
        
        print('Fetching data - isVerified: $isVerified, verification_status: ${profile?['verification_status']}');
        
        // Always fetch QR code if verified (even if profile already has one, refresh it)
        if (isVerified && profile != null) {
          print('User is verified, fetching QR code...');
          try {
            final qrCodeData = await service.getQrCode().timeout(
              const Duration(seconds: 25),
              onTimeout: () {
                print('QR code fetch timeout after 25 seconds');
                return null;
              },
            );
            if (qrCodeData != null && mounted) {
              final qrUrl = qrCodeData['qr_code_image_url'];
              if (qrUrl != null && qrUrl.toString().isNotEmpty) {
                profile['qr_code_image_url'] = qrUrl;
                profile['qr_code_data'] = qrCodeData['qr_code_data'];
                _qrCodeError = null; // Clear any previous error
                print('QR code loaded successfully: $qrUrl');
              } else {
                print('QR code URL is empty in response');
                if (mounted) {
                  _qrCodeError = 'QR code generation in progress. Please refresh.';
                }
              }
            } else {
              print('QR code data is null or empty');
              if (mounted) {
                _qrCodeError = 'QR code generation failed. Please try again later.';
              }
            }
          } catch (e) {
            print('Error fetching QR code: $e');
            if (mounted) {
              _qrCodeError = 'Unable to load QR code: ${e.toString()}';
            }
          }
        } else if (profile != null) {
          print('User is not verified (status: ${profile['verification_status']}), skipping QR code');
        }
        
        setState(() {
          _vendorProfile = profile;
          final docs = results[1] as List<dynamic>? ?? [];
          _documents = docs;
          print('Profile screen: Loaded ${docs.length} documents');
          for (var doc in docs) {
            print('Document loaded: type=${doc['document_type']}, file_url=${doc['file_url']}');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _getDocByType(String type) {
    try {
      print('Looking for document type: $type');
      print('Available documents count: ${_documents.length}');
      
      // Log all document types for debugging
      for (var doc in _documents) {
        final docType = (doc['document_type'] ?? '').toString();
        print('  - Document type in DB: "$docType" (looking for "$type")');
      }
      
      // Normalize the search type (handle PAN_CARD -> PAN, AADHAR_CARD -> AADHAR)
      final normalizedType = type.toUpperCase().trim();
      
      // Create search variants - try both full name and short name
      final searchVariants = <String>[
        normalizedType, // Try exact match first (PAN_CARD, AADHAR_CARD)
      ];
      
      // Add variants without _CARD suffix
      if (normalizedType.endsWith('_CARD')) {
        searchVariants.add(normalizedType.replaceAll('_CARD', '')); // PAN, AADHAR
      }
      
      // Add variant without CARD at all
      if (normalizedType.contains('CARD')) {
        final withoutCard = normalizedType.replaceAll('CARD', '').replaceAll('_', '').trim();
        if (withoutCard.isNotEmpty) {
          searchVariants.add(withoutCard); // PAN, AADHAR
        }
      }
      
      print('Search variants for "$type": $searchVariants');
      
      // Try to find matching document - handle both exact match and case-insensitive
      for (var doc in _documents) {
        final docType = (doc['document_type'] ?? '').toString().toUpperCase().trim();
        
        // Check against all search variants
        for (var searchVariant in searchVariants) {
          if (docType == searchVariant) {
            print('Found exact matching document: ${doc['document_type']} (matched variant: $searchVariant)');
            return doc;
          }
        }
        
        // Also try partial matching (e.g., "PAN" matches "PAN_CARD" and vice versa)
        if (docType.contains(normalizedType) || normalizedType.contains(docType)) {
          // But only if one is a substring of the other and they're related
          if ((docType.contains('PAN') && normalizedType.contains('PAN')) ||
              (docType.contains('AADHAR') && normalizedType.contains('AADHAR'))) {
            print('Found partial matching document: ${doc['document_type']} (matched: $docType contains or is contained in $normalizedType)');
            return doc;
          }
        }
      }
      
      print('No document found for type: $type');
      return null;
    } catch (e) {
      print('Error getting doc by type $type: $e');
      print('Available documents: $_documents');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Default values if data is missing
    final name = _vendorProfile?['full_name'] ?? 'Test User 5';
    final companyName = _vendorProfile?['company_name'] ?? 'Test User 5 Co';
    final industry = _vendorProfile?['industry'] ?? 'Food Business';
    // Check verification status (case-insensitive)
    final verificationStatus = _vendorProfile?['verification_status']?.toString().toUpperCase();
    final isVerified = verificationStatus == 'VERIFIED';
    
    print('Profile Screen - isVerified: $isVerified, verification_status: ${_vendorProfile?['verification_status']}');
    
    // Personal Details
    final email = _vendorProfile?['email'] ?? 'test5@gmail.com';
    final phone = _vendorProfile?['phone_number'] ?? '9000000005';
    final vendorId = _vendorProfile?['id']?.toString() ?? _vendorProfile?['vendor_id'] ?? '9B7DACA7';
    final dob = _vendorProfile?['dob'] ?? '18/01/2011';
    final gender = _vendorProfile?['gender'] ?? 'Female';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    // Logo logic: "what uploaded in logo show in profile"
    final logoDoc = _getDocByType('LOGO');
    final logoUrl = logoDoc?['file_url'] ?? logoDoc?['url'] ?? _vendorProfile?['logo_url'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              color: primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: [
                  // Profile Image
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).cardColor, width: 3),
                          image: DecorationImage(
                            image: logoUrl != null 
                                ? NetworkImage(logoUrl) 
                                : const AssetImage('assets/images/placeholder_avatar.png') as ImageProvider,
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          ),
                          color: Colors.grey[300],
                        ),
                        child: logoUrl == null 
                            ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () => _uploadDocument('LOGO'),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Name and Company Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          companyName,
                          style: TextStyle(
                            fontSize: 16,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          industry,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle, size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Personal Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: primaryColor, size: 20),
                        onPressed: _showEditPersonalDetails,
                      ),
                    ],
                  ),
                  _buildDetailRow('Email', email, isDark),
                  _buildDetailRow('Phone', phone, isDark),
                  _buildDetailRow('Vendor ID', vendorId, isDark),
                  _buildDetailRow('DOB', dob, isDark),
                  _buildDetailRow('Gender', gender, isDark),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton('Company Details', 0, primaryColor, isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTabButton('Documents', 1, primaryColor, isDark)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab Content
            if (_selectedTabIndex == 1) ...[
              // DOCUMENTS TAB
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Verification Documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    // Optional: could add a generic upload button if needed, but per-row is better
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _mandatoryDocTypes.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final type = _mandatoryDocTypes[index];
                  // Map display names
                  String displayName;
                  switch (type) {
                    case 'LOGO': displayName = 'Profile Photo (Logo)'; break;
                    case 'COMPANY_PROOF': displayName = 'Company Proof'; break;
                    case 'AADHAR_CARD': displayName = 'Aadhar Card'; break;
                    case 'PAN_CARD': displayName = 'PAN Card'; break;
                    default: displayName = type;
                  }
                  
                  return _buildDocumentRow(displayName, type, isDark);
                },
              ),
            ] else ...[
              // COMPANY DETAILS TAB
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Company Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: primaryColor, size: 20),
                          onPressed: _showEditCompanyDetails,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Company Name', companyName, isDark),
                    _buildDetailRow('Industry', industry, isDark),
                    _buildDetailRow('Address', _vendorProfile?['address'] ?? 'Not Provided', isDark),
                    _buildDetailRow('City', _vendorProfile?['city'] ?? 'Not Provided', isDark),
                    _buildDetailRow('State', _vendorProfile?['state'] ?? 'Not Provided', isDark),
                    _buildDetailRow('Pincode', _vendorProfile?['pincode'] ?? 'Not Provided', isDark),
                    const SizedBox(height: 24),
                    // QR Code Section - Always show if verified
                    if (isVerified) 
                      _buildQrCodeSection(isDark, primaryColor)
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'QR Code will be available after verification',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            if (_isUploading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        "Uploading Document...",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(String title, String type, bool isDark) {
    final doc = _getDocByType(type);
    final isUploaded = doc != null;
    final uploadedAt = doc?['uploaded_at'] ?? 'Just now';
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
        border: isUploaded ? null : Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUploaded ? primaryColor.withOpacity(0.1) : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUploaded ? Icons.description : Icons.warning_amber_rounded,
              color: isUploaded ? primaryColor : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUploaded ? 'Uploaded at: $uploadedAt' : 'Missing (Mandatory)',
                  style: TextStyle(
                    color: isUploaded ? (isDark ? Colors.grey[400] : Colors.grey[600]) : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isUploaded)
            TextButton(
              onPressed: () async {
                 final url = doc['file_url'] ?? doc['url'];
                 if (url != null && url.isNotEmpty) {
                   try {
                     await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                   } catch (e) {
                     if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Error opening document: $e')),
                       );
                     }
                   }
                 } else {
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Document URL not available')),
                     );
                   }
                 }
              },
              child: Text('VIEW', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: Icon(isUploaded ? Icons.edit : Icons.upload_file, color: primaryColor),
            onPressed: () => _uploadDocument(type),
            tooltip: isUploaded ? 'Replace' : 'Upload',
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);
        final token = context.read<AuthService>().token;
        if (token != null) {
          final service = VendorService(token);
          final success = await service.uploadDocument(type, result.files.single.path!);
          
          if (success) {
            await _fetchData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document uploaded successfully')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to upload document')),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showEditPersonalDetails() async {
    final nameCtrl = TextEditingController(text: _vendorProfile?['full_name']);
    final emailCtrl = TextEditingController(text: _vendorProfile?['email']);
    final phoneCtrl = TextEditingController(text: _vendorProfile?['phone_number']);
    final dobCtrl = TextEditingController(text: _vendorProfile?['dob']);
    final genderCtrl = TextEditingController(text: _vendorProfile?['gender']);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Personal Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: dobCtrl, decoration: const InputDecoration(labelText: 'DOB (DD/MM/YYYY)')),
              TextField(controller: genderCtrl, decoration: const InputDecoration(labelText: 'Gender')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateProfile({
                'full_name': nameCtrl.text,
                'email': emailCtrl.text,
                'phone_number': phoneCtrl.text,
                'dob': dobCtrl.text,
                'gender': genderCtrl.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCompanyDetails() async {
    final companyNameCtrl = TextEditingController(text: _vendorProfile?['company_name']);
    final industryCtrl = TextEditingController(text: _vendorProfile?['industry']);
    final addressCtrl = TextEditingController(text: _vendorProfile?['address']);
    final cityCtrl = TextEditingController(text: _vendorProfile?['city']);
    final stateCtrl = TextEditingController(text: _vendorProfile?['state']);
    final pincodeCtrl = TextEditingController(text: _vendorProfile?['pincode']);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Company Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: companyNameCtrl, decoration: const InputDecoration(labelText: 'Company Name')),
              TextField(controller: industryCtrl, decoration: const InputDecoration(labelText: 'Industry')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State')),
              TextField(controller: pincodeCtrl, decoration: const InputDecoration(labelText: 'Pincode')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateProfile({
                'company_name': companyNameCtrl.text,
                'industry': industryCtrl.text,
                'address': addressCtrl.text,
                'city': cityCtrl.text,
                'state': stateCtrl.text,
                'pincode': pincodeCtrl.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    final token = context.read<AuthService>().token;
    if (token == null) return;

    final service = VendorService(token);
    // Filter out null/empty values if needed, but API usually handles partial updates if PATCH, 
    // but here we are sending what was edited.
    // If updateVendor expects all fields, we might need to merge with existing.
    // Assuming API handles partial updates or we should merge.
    final currentData = _vendorProfile ?? {};
    final updatedData = {...currentData, ...data};
    
    final success = await service.updateVendor(updatedData);
    
    if (success) {
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection(bool isDark, Color primaryColor) {
    final qrCodeUrl = _vendorProfile?['qr_code_image_url'];
    
    // Check if QR code URL exists and is not empty
    final hasQrCode = qrCodeUrl != null && qrCodeUrl.toString().isNotEmpty && qrCodeUrl.toString().trim().isNotEmpty;
    
    print('QR Code Section - qrCodeUrl: $qrCodeUrl, hasQrCode: $hasQrCode, _qrCodeError: $_qrCodeError');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            'Company QR Code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (hasQrCode)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Image.network(
                qrCodeUrl.toString(),
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 250,
                    height: 250,
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('QR code image load error: $error');
                  return Container(
                    width: 250,
                    height: 250,
                    padding: const EdgeInsets.all(20),
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 50, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load QR code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else if (_qrCodeError != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'QR Code Error',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _qrCodeError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _qrCodeError = null;
                      });
                      _fetchData();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            // Show loading state while QR code is being generated
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Generating QR Code...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Scan this QR code to check in at this company',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, Color primaryColor, bool isDark) {
    final isSelected = _selectedTabIndex == index;
    // For selected tab:
    // If dark mode: primary color background, black/white text depending on primary color contrast
    // If light mode: white background, primary color text
    // BUT user said: "download all text is in blue color change as primary colr text according to theme"
    
    // Let's stick to standard tab look:
    // Selected: Primary Color BG, White text (if dark primary) or Black text (if light primary)
    // Unselected: Surface color (grey/white), Grey text
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? primaryColor : Colors.white) 
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected 
                ? (isDark ? Colors.white : primaryColor)
                : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
