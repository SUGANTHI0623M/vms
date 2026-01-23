import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_common_widgets.dart';
import '../verification/verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _vendorProfile;
  List<dynamic> _documents = [];
  bool _isUploading = false;

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

      final profile = results[0] as Map<String, dynamic>?;
      final docs = results[1] as List<dynamic>?;

      if (mounted) {
        final List<dynamic> processedDocs = [];
        if (docs != null) {
          // Keep mandatory ones unique, allow multiple OTHER
          final Map<String, dynamic> mandatoryDocs = {};
          for (var doc in docs) {
            final type = doc['document_type'] ?? 'OTHER';
            if (type == 'AADHAR' || type == 'PAN') {
              mandatoryDocs[type] = doc;
            } else {
              processedDocs.add(doc);
            }
          }
          processedDocs.addAll(mandatoryDocs.values);
        }

        setState(() {
          _vendorProfile = profile;
          _documents = processedDocs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    // Show dialog to select type
    String? type = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Document Type'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'AADHAR'),
            child: const Text('Aadhar Card'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'PAN'),
            child: const Text('PAN Card'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'OTHER'),
            child: const Text('Other'),
          ),
        ],
      ),
    );

    if (type == null) return;

    String finalType = type;
    if (type == 'OTHER') {
      final nameController = TextEditingController();
      final customName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Document Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter document name (e.g. MSME)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (customName == null || customName.isEmpty) return;
      finalType = customName;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    setState(() => _isUploading = true);
    final token = context.read<AuthService>().token!;
    final service = VendorService(token);

    final success = await service.uploadDocument(
      finalType,
      result.files.single.path!,
    );

    setState(() => _isUploading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
        _fetchData(); // Refresh list
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload document')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open file')));
      }
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value ?? '--', style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'My Profile'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(title: 'My Profile', onRefresh: _fetchData),
      body: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Profile Picture
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // Personal Details Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Personal Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => _navigateToEdit(0),
                  ),
                ],
              ),
              const Divider(),
              _buildDetailRow('Email', _vendorProfile?['email']),
              _buildDetailRow('Phone', _vendorProfile?['phone_number']),
              _buildDetailRow('Vendor ID', _vendorProfile?['vendor_uid']),
              _buildDetailRow('DOB', _vendorProfile?['dob']),
              _buildDetailRow('Gender', _vendorProfile?['gender']),

              const SizedBox(height: 24),

              // Switching Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Company Details'),
                    Tab(text: 'Documents'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400, // Fixed height for TabBarView in ScrollView
                child: TabBarView(
                  children: [_buildCompanyTab(), _buildDocumentsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: (_vendorProfile?['logo_url'] != null)
                  ? NetworkImage(_vendorProfile!['logo_url'])
                  : null,
              child: (_vendorProfile?['logo_url'] == null)
                  ? const Icon(Icons.person, size: 55, color: AppColors.primary)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _vendorProfile?['full_name'] ?? 'Vendor User',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_vendorProfile?['company_name'] != null)
                Text(
                  _vendorProfile!['company_name'],
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (_vendorProfile?['description'] != null)
                Text(
                  _vendorProfile!['description'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              _buildStatusBadge(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final status = _vendorProfile?['verification_status'] ?? 'PENDING';
    final isVerified = status == 'VERIFIED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.pending,
            size: 14,
            color: isVerified ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: isVerified ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Business Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: () => _navigateToEdit(1),
              ),
            ],
          ),
          const Divider(),
          _buildDetailRow('Company', _vendorProfile?['company_name']),
          _buildDetailRow('Website', _vendorProfile?['website']),
          _buildDetailRow('GSTIN', _vendorProfile?['gstin']),
          _buildDetailRow('Address', _vendorProfile?['office_address']),
          _buildDetailRow('Description', _vendorProfile?['description']),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Verification Documents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.upload_file,
                      color: AppColors.primary,
                      size: 20,
                    ),
              onPressed: _isUploading ? null : _pickAndUploadDocument,
            ),
          ],
        ),
        const Divider(),
        if (_documents.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No documents uploaded yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return _buildDocCard(doc);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description, color: AppColors.primary),
        ),
        title: Text(
          doc['document_type'] == 'AADHAR'
              ? 'Aadhar Card'
              : (doc['document_type'] == 'PAN'
                    ? 'PAN Card'
                    : (doc['document_type'] ?? 'Unknown')),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Uploaded at: ${doc['id']}',
        ), // Could show date if available
        trailing: TextButton(
          onPressed: () => _launchUrl(doc['file_url']),
          child: const Text('VIEW'),
        ),
      ),
    );
  }

  void _navigateToEdit(int step) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VerificationScreen(initialStep: step, isSingleStep: true),
      ),
    );
    if (result == true) {
      _fetchData();
    }
  }
}
