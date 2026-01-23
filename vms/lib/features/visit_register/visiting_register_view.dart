import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http; // For direct Check-In call
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../services/visit_service.dart';
import '../../services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';

class VisitingRegisterView extends StatefulWidget {
  final VoidCallback? onCheckInComplete;
  const VisitingRegisterView({super.key, this.onCheckInComplete});

  @override
  State<VisitingRegisterView> createState() => _VisitingRegisterViewState();
}

class _VisitingRegisterViewState extends State<VisitingRegisterView> {
  // Data
  List<String> _companySuggestions = [];
  List<dynamic> _visits = [];
  Map<String, dynamic>? _activeVisit;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _verificationStatus;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  int _selectedTab = 0; // 0: History, 1: Top 5, 2: Least Visited

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final token = auth.token;

    if (token != null) {
      final vendorService = VendorService(token);
      final visitService = VisitService();

      try {
        final results = await Future.wait([
          vendorService.getVendorProfile(),
          vendorService.getVerifiedCompanies(),
          visitService.getMyVisits(token),
        ]);

        final profile = results[0] as Map<String, dynamic>?;
        final companies = results[1] as List<String>?;
        final visits = results[2] as List<dynamic>?;

        _verificationStatus = profile?['verification_status'];
        _companySuggestions = companies ?? [];

        if (visits != null) {
          // Sort by ID desc
          visits.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
          _visits = visits;
          // Find active visit (no check_out_time)
          try {
            _activeVisit = visits.firstWhere(
              (v) => v['check_out_time'] == null,
            );
          } catch (e) {
            _activeVisit = null;
          }
        }
      } catch (e) {
        debugPrint('Error fetching initial data: $e');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _fetchInitialData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_verificationStatus != 'VERIFIED')
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Verification Pending. You cannot check in yet.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // ACTION SECTION
                  if (_activeVisit != null)
                    _buildActiveVisitCard(_activeVisit!)
                  else
                    _buildCheckInButton(),

                  const SizedBox(height: 30),

                  // TABS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTabItem(0, "History", Icons.history),
                      _buildTabItem(1, "Top 5", Icons.trending_up),
                      _buildTabItem(2, "Least", Icons.trending_down),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (_selectedTab == 0) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _buildFilters()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            _buildSliverHistoryList(),
          ] else if (_selectedTab == 1) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _buildCompanyStats(isTop: true),
              ),
            ),
          ] else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _buildCompanyStats(isTop: false),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    bool isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search company...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? "Filter by date"
                    : "Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}",
              ),
            ),
            if (_selectedDate != null)
              TextButton(
                onPressed: () => setState(() => _selectedDate = null),
                child: const Text("Clear"),
              ),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2025),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: const Text("Select Date"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompanyStats({required bool isTop}) {
    // Aggregate
    Map<String, int> counts = {};
    for (var v in _visits) {
      String p = v['purpose'] ?? '';
      // Extract company: "Visiting: Company. ..."
      String company = "Unknown";
      if (p.startsWith("Visiting: ")) {
        company = p.split("Visiting: ")[1].split(".")[0];
      }
      counts[company] = (counts[company] ?? 0) + 1;
    }

    var sorted = counts.entries.toList()
      ..sort(
        (a, b) =>
            isTop ? b.value.compareTo(a.value) : a.value.compareTo(b.value),
      );

    var displayList = sorted.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            isTop ? "5 Most Visited Companies" : "Least Visited Companies",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...displayList.map(
          (e) => ListTile(
            title: Text(e.key),
            trailing: CircleAvatar(child: Text(e.value.toString())),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInButton() {
    return ElevatedButton.icon(
      onPressed: _verificationStatus == 'VERIFIED' ? _handleCheckInPress : null,
      icon: const Icon(Icons.login),
      label: const Text('Check In'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildActiveVisitCard(Map<String, dynamic> visit) {
    // Determine company request
    String title = visit['purpose'] ?? 'Unknown Visit';
    // Attempt to parse company from "Visiting: Company. Purpose"

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Currently Checked In",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text("Checked in at: ${visit['check_in_time'] ?? '--'}"),
            const SizedBox(height: 15),
            _isActionLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: () => _handleCheckOutPress(visit['id']),
                    icon: const Icon(Icons.logout),
                    label: const Text("Check Out"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckInPress() async {
    // 1. Company Selection Dialog
    final company = await showDialog<String>(
      context: context,
      builder: (context) =>
          _CompanySelectionDialog(suggestions: _companySuggestions),
    );

    if (company == null || company.isEmpty) return;

    // 2. Camera
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50, // Reduce file size significantly
      maxWidth: 1024, // Limit resolution
    );

    if (photo == null) return;

    // 3. Location
    setState(() => _isActionLoading = true);
    final locService = context.read<LocationService>();
    await locService
        .refreshLocation(); // FORCE REFRESH to ensure accurate tracking

    if (locService.currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Location not found.")));
      }
      setState(() => _isActionLoading = false);
      return;
    }

    // 4. Submit
    final auth = context.read<AuthService>();
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/visits/check-in'),
      );
      request.headers['Authorization'] = 'Bearer ${auth.token}';
      request.fields['check_in_latitude'] = locService.currentPosition!.latitude
          .toString();
      request.fields['check_in_longitude'] = locService
          .currentPosition!
          .longitude
          .toString();
      request.fields['company_name'] = company;

      // Pass valid parts
      final parts = locService.addressParts;
      request.fields['area'] = parts['area'] ?? '';
      request.fields['city'] = parts['city'] ?? '';
      request.fields['state'] = parts['state'] ?? '';
      request.fields['pincode'] = parts['pincode'] ?? '';

      request.files.add(
        await http.MultipartFile.fromPath('selfie', photo.path),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        await _fetchInitialData(); // Refresh to show active visit
        if (widget.onCheckInComplete != null) widget.onCheckInComplete!();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Checked In Successfully!")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Check-in Failed.")));
        }
      }
    } catch (e) {
      debugPrint("Checkin error: $e");
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleCheckOutPress(int visitId) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
      maxWidth: 1024,
    );

    if (photo == null) return;

    setState(() => _isActionLoading = true);
    final locService = context.read<LocationService>();
    await locService
        .refreshLocation(); // Ensure we get fresh coords for checkout

    if (locService.currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Location not found.")));
      }
      setState(() => _isActionLoading = false);
      return;
    }

    final auth = context.read<AuthService>();
    final service = VisitService();
    final success = await service.checkOut(
      visitId,
      locService.currentPosition!.latitude,
      locService.currentPosition!.longitude,
      File(photo.path),
      auth.token!,
    );

    if (success) {
      await _fetchInitialData();
      if (widget.onCheckInComplete != null) widget.onCheckInComplete!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Checked Out Successfully!")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Check-out Failed.")));
      }
    }
    if (mounted) setState(() => _isActionLoading = false);
  }

  Widget _buildSliverHistoryList() {
    var filtered = _visits.where((v) {
      final purpose = v['purpose']?.toString().toLowerCase() ?? '';
      final search = _searchController.text.toLowerCase();
      final dateMatch =
          _selectedDate == null ||
          v['check_in_time']?.toString().startsWith(
                _selectedDate!.toLocal().toString().split(' ')[0],
              ) ==
              true;
      return purpose.contains(search) && dateMatch;
    }).toList();

    if (filtered.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("No visits matching your filters."),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final v = filtered[index];
          final purpose = v['purpose'] ?? 'Visit';
          final checkInTimeStr = v['check_in_time']?.toString() ?? '';
          final date = checkInTimeStr.split('T')[0];
          final timeIn = checkInTimeStr.contains('T')
              ? checkInTimeStr.split('T')[1].split('.')[0]
              : '--';
          final timeOut = v['check_out_time']?.toString().contains('T') == true
              ? v['check_out_time']?.toString().split('T')[1].split('.')[0]
              : '--';

          final url = v['check_in_selfie_url'];

          // Address parts
          final address = [v['area'], v['city'], v['state'], v['pincode']]
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .join(', ');

          final lat = v['check_in_latitude'];
          final long = v['check_in_longitude'];
          final outLat = v['check_out_latitude'];
          final outLong = v['check_out_longitude'];

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: url != null
                  ? CircleAvatar(backgroundImage: NetworkImage(url))
                  : const Icon(Icons.location_on),
              title: Text(
                purpose,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text("$date | In: $timeIn Out: $timeOut"),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Full Address:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(address.isEmpty ? "No address recorded" : address),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Check-In Coords:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "Lat: $lat\nLong: $long",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (outLat != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Check-Out Coords:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "Lat: $outLat\nLong: $outLong",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }, childCount: filtered.length),
      ),
    );
  }
}

class _CompanySelectionDialog extends StatefulWidget {
  final List<String> suggestions;
  const _CompanySelectionDialog({required this.suggestions});

  @override
  State<_CompanySelectionDialog> createState() =>
      _CompanySelectionDialogState();
}

class _CompanySelectionDialogState extends State<_CompanySelectionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Who are you visiting?"),
      content: TypeAheadField<String>(
        suggestionsCallback: (pattern) {
          return widget.suggestions
              .where((c) => c.toLowerCase().contains(pattern.toLowerCase()))
              .toList();
        },
        builder: (context, controller, focusNode) {
          // TypeAheadField provides a controller that manages the text field
          // But we need to extract the value when user clicks Next.
          // Effectively, we can use the `controller` provided by builder and read it on button press?
          // The `controller` here is likely owned by TypeAhead.
          // Let's hook our own _controller to it if possible? Use `controller: _controller` in TypeAheadField props?
          // New version of TypeAheadField requires passing controller to TextField.
          // We can synchronize.
          controller.addListener(() {
            _controller.text = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Company Name",
            ),
          );
        },
        itemBuilder: (context, suggestion) {
          return ListTile(title: Text(suggestion));
        },
        onSelected: (suggestion) {
          // Set text handled by TypeAhead internal controller usually,
          // but we need to know we selected something.
          _controller.text = suggestion;
          Navigator.pop(context, suggestion);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            // Use typed text if not selected
            Navigator.pop(context, _controller.text);
          },
          child: const Text("Next"),
        ),
      ],
    );
  }
}
