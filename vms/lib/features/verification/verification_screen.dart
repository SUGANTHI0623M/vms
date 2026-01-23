import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_common_widgets.dart';

class VerificationScreen extends StatefulWidget {
  final int initialStep;
  final bool isSingleStep;

  const VerificationScreen({
    super.key,
    this.initialStep = 0,
    this.isSingleStep = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late int _currentStep;
  bool _isLoading = false;
  final _personalFormKey = GlobalKey<FormState>();
  final _companyFormKey = GlobalKey<FormState>();

  // Personal Details Controllers
  final _dobController = TextEditingController();
  String? _selectedGender;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Company Details Controllers
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _gstinController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _logoFile;

  Map<String, dynamic>? _vendorProfile;

  // Documents
  File? _aadharDoc;
  File? _panDoc;
  File? _companyProofDoc;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = context.read<AuthService>().token;
    if (token != null) {
      final profile = await VendorService(token).getVendorProfile();
      if (profile != null) {
        setState(() {
          _vendorProfile = profile;
          _dobController.text = profile['dob'] ?? '';
          _selectedGender = profile['gender'];
          _phoneController.text = profile['phone_number'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _companyNameController.text = profile['company_name'] ?? '';
          _companyAddressController.text = profile['office_address'] ?? '';
          _websiteController.text = profile['website'] ?? '';
          _gstinController.text = profile['gstin'] ?? '';
          _descriptionController.text = profile['description'] ?? '';
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() => _logoFile = File(image.path));
    }
  }

  Future<void> _savePersonalDetails({bool isSingle = false}) async {
    if (!_personalFormKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select gender')));
      return;
    }

    setState(() => _isLoading = true);
    final token = context.read<AuthService>().token!;
    final success = await VendorService(token).updateVendor({
      'dob': _dobController.text,
      'gender': _selectedGender,
      'phone_number': _phoneController.text,
      'email': _emailController.text,
    });

    setState(() => _isLoading = false);
    if (success) {
      if (isSingle) {
        Navigator.pop(context, true);
      } else {
        setState(() => _currentStep++);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save details.')));
    }
  }

  Future<void> _saveCompanyDetails({bool isSingle = false}) async {
    // None mandatory per user request
    setState(() => _isLoading = true);
    final token = context.read<AuthService>().token!;

    // Upload logo first if selected
    if (_logoFile != null) {
      // We'll reuse uploadDocument for logo if backend handles it
      await VendorService(token).uploadDocument('LOGO', _logoFile!.path);
    }

    final success = await VendorService(token).updateVendor({
      'company_name': _companyNameController.text,
      'office_address': _companyAddressController.text,
      'website': _websiteController.text,
      'gstin': _gstinController.text,
      'description': _descriptionController.text,
    });

    setState(() => _isLoading = false);
    if (success) {
      if (isSingle) {
        Navigator.pop(context, true);
      } else {
        setState(() => _currentStep++);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save company details.')),
      );
    }
  }

  Future<void> _pickDocument(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        if (type == 'AADHAR') _aadharDoc = File(result.files.single.path!);
        if (type == 'PAN') _panDoc = File(result.files.single.path!);
        if (type == 'COMPANY_PROOF') {
          _companyProofDoc = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _uploadAllDocuments() async {
    if (_aadharDoc == null || _panDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload mandatory Aadhar and PAN')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final token = context.read<AuthService>().token!;
    final service = VendorService(token);

    try {
      final futures = <Future<bool>>[
        service.uploadDocument('AADHAR', _aadharDoc!.path),
        service.uploadDocument('PAN', _panDoc!.path),
      ];

      if (_companyProofDoc != null) {
        futures.add(
          service.uploadDocument('COMPANY_PROOF', _companyProofDoc!.path),
        );
      }

      final results = await Future.wait(futures);
      final aSuccess = results[0];
      final pSuccess = results[1];
      // Optional doc success check if needed, but not strictly mandatory to block verification if optional fails?
      // Assuming if optional fails we might warn or ignore. But let's assume we proceed if mandatory are okay.

      if (aSuccess && pSuccess) {
        final verifySuccess = await service.verifyProfile();
        if (verifySuccess) {
          await _loadProfile();
          setState(() => _currentStep++);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Verification failed')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload mandatory documents')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSingleStep) {
      final step = _getSteps()[_currentStep];
      return Scaffold(
        appBar: CommonAppBar(
          title:
              'Edit ${step.title is Text ? (step.title as Text).data : "Details"}',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              step.content,
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_currentStep == 0) {
                            _savePersonalDetails(isSingle: true);
                          } else if (_currentStep == 1)
                            _saveCompanyDetails(isSingle: true);
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(title: 'Verification'),
      drawer: const AppDrawer(),
      body: Stepper(
        type: MediaQuery.of(context).size.width > 600
            ? StepperType.horizontal
            : StepperType.vertical,
        currentStep: _currentStep,
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          if (_currentStep == 3) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : details.onStepContinue,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == 2 ? 'Finish & Verify' : 'Continue',
                        ),
                ),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        onStepContinue: () {
          if (_currentStep == 0) {
            _savePersonalDetails();
          } else if (_currentStep == 1)
            _saveCompanyDetails();
          else if (_currentStep == 2)
            _uploadAllDocuments();
        },
        steps: _getSteps(),
      ),
    );
  }

  List<Step> _getSteps() {
    return [
      // Step 1: Personal Details
      Step(
        title: const Text('Personal'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.editing,
        content: Form(
          key: _personalFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'DOB (DD/MM/YYYY)',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectDate(context),
                validator: (value) =>
                    value!.isEmpty ? 'Please select DOB' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                items: ['Female', 'Male', 'Other']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGender = v),
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Please select Gender' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is mandatory';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      // Step 2: Company Details
      Step(
        title: const Text('Company'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.editing,
        content: Form(
          key: _companyFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyAddressController,
                decoration: const InputDecoration(
                  labelText: 'Office Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gstinController,
                decoration: const InputDecoration(
                  labelText: 'GSTIN (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Short Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Company Logo'),
                subtitle: Text(_logoFile != null ? 'Selected' : 'Not selected'),
                trailing: IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickLogo,
                ),
              ),
            ],
          ),
        ),
      ),
      // Step 3: Documents
      Step(
        title: const Text('Docs'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.editing,
        content: Column(
          children: [
            ListTile(
              title: const Text('Aadhar Card (Mandatory)'),
              subtitle: Text(_aadharDoc?.path.split('/').last ?? 'None'),
              trailing: IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () => _pickDocument('AADHAR'),
              ),
            ),
            ListTile(
              title: const Text('PAN Card (Mandatory)'),
              subtitle: Text(_panDoc?.path.split('/').last ?? 'None'),
              trailing: IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () => _pickDocument('PAN'),
              ),
            ),
            ListTile(
              title: const Text('Company Proof (Optional)'),
              subtitle: Text(_companyProofDoc?.path.split('/').last ?? 'None'),
              trailing: IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () => _pickDocument('COMPANY_PROOF'),
              ),
            ),
          ],
        ),
      ),
      // Step 4: Status
      Step(
        title: const Text('Status'),
        isActive: _currentStep >= 3,
        content: Center(
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Verified Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Unique ID: ${_vendorProfile?['vendor_uid'] ?? 'GENERATING...'}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  true,
                ), // Pass true to indicate success
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
