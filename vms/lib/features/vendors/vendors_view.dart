import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../services/visit_service.dart';
import '../../core/models/vendor.dart';
import 'vendor_detail_view.dart';

class VendorsView extends StatefulWidget {
  const VendorsView({super.key});

  @override
  State<VendorsView> createState() => _VendorsViewState();
}

class _VendorsViewState extends State<VendorsView> {
  Map<String, dynamic>? _currentVendorProfile;
  List<Vendor> _allVendors = [];
  final Set<String> _visitedCompanyNames = {};
  final Set<int> _visitorVendorIds = {};
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  
  // Use filter index instead of TabController for flexibility with "Pills"
  int _selectedFilterIndex = 0; // 0: All, 1: My Vendors, 2: Verified, 3: Pending

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final token = context.read<AuthService>().token;
    if (token != null) {
      setState(() => _isLoading = true);
      final vendorService = VendorService(token);
      final visitService = VisitService();

      try {
        final results = await Future.wait([
          vendorService.getAllVendors(),
          visitService.getMyVisits(token),
          vendorService.getVendorProfile(),
        ]);

        final data = results[0] as List<dynamic>?;
        final visits = results[1] as List<dynamic>?;
        final profile = results[2] as Map<String, dynamic>?;

        if (mounted) {
          _currentVendorProfile = profile;
          if (visits != null) {
            for (var v in visits) {
              String p = v['purpose'] ?? '';
              if (p.startsWith("Visiting: ")) {
                try {
                  String company = p.split("Visiting: ")[1].split(".")[0];
                  _visitedCompanyNames.add(company.toLowerCase().trim());
                } catch (e) {}
              }
              if (v['vendor_id'] != null && v['vendor_id'] is int) {
                _visitorVendorIds.add(v['vendor_id']);
              }
            }
          }

          setState(() {
            _allVendors = data?.map((e) => Vendor.fromJson(e)).toList() ?? [];
            _isLoading = false;
          });
          
          // Debug: Log vendor verification statuses
          print('DEBUG: Loaded ${_allVendors.length} vendors');
          for (var vendor in _allVendors) {
            print('DEBUG: Vendor ${vendor.id} (${vendor.companyName}): verification_status = "${vendor.verificationStatus}"');
          }
          
          // Debug: Count verified vendors
          final verifiedCount = _allVendors.where((v) => v.verificationStatus.toUpperCase() == 'VERIFIED').length;
          print('DEBUG: Found $verifiedCount verified vendors out of ${_allVendors.length} total');
        }
      } catch (e) {
        debugPrint('Error fetching vendors data: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _filterVendors(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Vendor> _getDisplayedVendors() {
    // 1. Search Filter
    List<Vendor> searchResults = _allVendors;
    if (_searchQuery.isNotEmpty) {
      searchResults = _allVendors
          .where(
            (v) =>
                (v.companyName ?? "").toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (v.fullName ?? "").toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (v.vendorUid ?? "").toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // 2. Category Filter
    if (_selectedFilterIndex == 0) {
      return searchResults; // All
    } else if (_selectedFilterIndex == 1) {
      // My Vendors (Visited)
      return searchResults.where((v) {
        if (_currentVendorProfile != null && v.id == _currentVendorProfile!['id']) {
          return false;
        }
        bool byName = v.companyName != null &&
            _visitedCompanyNames.contains(v.companyName!.toLowerCase().trim());
        bool byId = _visitorVendorIds.contains(v.id);
        return byName || byId;
      }).toList();
    } else if (_selectedFilterIndex == 2) {
      // Verified
      return searchResults
          .where((v) => v.verificationStatus.toUpperCase() == 'VERIFIED')
          .toList();
    } else if (_selectedFilterIndex == 3) {
      // Pending / Not Verified
      return searchResults
          .where((v) => v.verificationStatus.toUpperCase() != 'VERIFIED')
          .toList();
    }
    
    return searchResults;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    final displayedVendors = _getDisplayedVendors();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterVendors,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search vendors...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: isDark ? const Color(0xFF27272A) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
        
        // Tab Filters (Pill shaped)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
               _buildFilterChip("All", 0, primaryColor, isDark),
               const SizedBox(width: 10),
               _buildFilterChip("My Vendors", 1, primaryColor, isDark), // Was "Filters" in screenshot, mapping to "My Vendors" logic
               const SizedBox(width: 10),
               _buildFilterChip("Verified", 2, primaryColor, isDark), // Was "Visitors" in screenshot
               const SizedBox(width: 10),
               _buildFilterChip("Pending", 3, primaryColor, isDark), // Was "Vendors" in screenshot
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        Expanded(
          child: displayedVendors.isEmpty 
            ? Center(
                child: Text(
                  "No vendors found",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            : ListView.builder(
                itemCount: displayedVendors.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final vendor = displayedVendors[index];
                  return _buildVendorCard(vendor, isDark, primaryColor);
                },
              ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(String label, int index, Color primary, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    final bgColor = isSelected ? primary : Colors.transparent;
    final borderColor = isSelected ? primary : Colors.grey[600]!;
    // Adjust text color for readability against primary background
    final textColor = isSelected 
        ? (ThemeData.estimateBrightnessForColor(primary) == Brightness.dark ? Colors.white : Colors.black)
        : (isDark ? Colors.grey[400] : Colors.grey[600]);
        
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor, bool isDark, Color primary) {
    final bool isVerified = vendor.verificationStatus.toUpperCase() == 'VERIFIED';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorDetailView(vendor: vendor),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark 
              ? null 
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark ? const Color(0xFF3F3F46) : Colors.grey[200],
                  backgroundImage: vendor.logoUrl != null ? NetworkImage(vendor.logoUrl!) : null,
                  child: vendor.logoUrl == null
                      ? Text(
                          (vendor.companyName ?? "?")[0].toUpperCase(),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.companyName ?? "Unknown Company",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        vendor.fullName ?? "Contact not set",
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                         Icon(
                           Icons.check_circle, 
                           size: 14, 
                           color: ThemeData.estimateBrightnessForColor(primary) == Brightness.dark ? Colors.white : Colors.black
                         ),
                         const SizedBox(width: 4),
                         Text(
                           "Verified",
                           style: TextStyle(
                             color: ThemeData.estimateBrightnessForColor(primary) == Brightness.dark ? Colors.white : Colors.black,
                             fontSize: 12,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.location_on_outlined, vendor.officeAddress ?? "No Address", isDark),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email_outlined, vendor.email ?? "No Email", isDark),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone_outlined, vendor.phoneNumber ?? "No Phone", isDark),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey[500] : Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
