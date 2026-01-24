import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../services/visit_service.dart';
import '../../core/models/vendor.dart';
import '../../core/theme/app_colors.dart';
import 'vendor_detail_view.dart';

class VendorsView extends StatefulWidget {
  const VendorsView({super.key});

  @override
  State<VendorsView> createState() => _VendorsViewState();
}

class _VendorsViewState extends State<VendorsView> {
  Map<String, dynamic>? _currentVendorProfile;
  List<Vendor> _allVendors = [];
  List<Vendor> _filteredVendors = [];
  final Set<String> _visitedCompanyNames = {};
  final Set<int> _visitorVendorIds = {};
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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
              // Outgoing visits: parsed from purpose
              String p = v['purpose'] ?? '';
              if (p.startsWith("Visiting: ")) {
                try {
                  String company = p.split("Visiting: ")[1].split(".")[0];
                  _visitedCompanyNames.add(company.toLowerCase().trim());
                } catch (e) {
                  // ignore parse error
                }
              }
              // Incoming visits: capture vendor_id
              if (v['vendor_id'] != null && v['vendor_id'] is int) {
                _visitorVendorIds.add(v['vendor_id']);
              }
            }
          }

          setState(() {
            _allVendors = data?.map((e) => Vendor.fromJson(e)).toList() ?? [];
            _filteredVendors = _allVendors;
            _isLoading = false;
          });
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
      _filteredVendors = _allVendors
          .where(
            (v) =>
                (v.companyName ?? "").toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (v.fullName ?? "").toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (v.vendorUid ?? "").toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final myVendors = _filteredVendors.where((v) {
      // Exclude self
      if (_currentVendorProfile != null &&
          v.id == _currentVendorProfile!['id']) {
        return false;
      }

      bool byName =
          v.companyName != null &&
          _visitedCompanyNames.contains(v.companyName!.toLowerCase().trim());
      bool byId = _visitorVendorIds.contains(v.id);
      return byName || byId;
    }).toList();

    final verifiedVendors = _filteredVendors
        .where((v) => v.verificationStatus.toUpperCase() == 'VERIFIED')
        .toList();
    final pendingVendors = _filteredVendors
        .where((v) => v.verificationStatus.toUpperCase() != 'VERIFIED')
        .toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterVendors,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search vendors...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterVendors("");
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              isScrollable: true,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark ? AppColors.darkPrimary : Colors.white,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: isDark ? Colors.black : AppColors.primary,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.business_center, size: 16),
                      const SizedBox(width: 6),
                      Text('My Vendors (${myVendors.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, size: 16),
                      const SizedBox(width: 6),
                      Text('Verified (${verifiedVendors.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending, size: 16),
                      const SizedBox(width: 6),
                      Text('Pending (${pendingVendors.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBarView(
                children: [
                  _buildVendorList(myVendors),
                  _buildVendorList(verifiedVendors),
                  _buildVendorList(pendingVendors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorList(List<Vendor> vendors) {
    if (vendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No vendors in this category'
                  : 'No matches found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: vendors.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (context, index) {
        final vendor = vendors[index];
        return _buildVendorCard(vendor);
      },
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    final bool isVerified =
        vendor.verificationStatus.toUpperCase() == 'VERIFIED';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VendorDetailView(vendor: vendor),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo or Initial
                Hero(
                  tag: 'vendor-logo-${vendor.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isVerified
                            ? [Colors.blue[400]!, Colors.blue[700]!]
                            : [Colors.orange[300]!, Colors.orange[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      image: vendor.logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(vendor.logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: vendor.logoUrl == null
                        ? Center(
                            child: Text(
                              (vendor.companyName ?? "?")[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendor.companyName ?? 'Unnamed Company',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified)
                            Icon(
                              Icons.verified,
                              color: isDark ? AppColors.darkPrimary : Colors.blue,
                              size: 18,
                            ),
                        ],
                      ),
                      if (vendor.description != null &&
                          vendor.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            vendor.description!,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        vendor.fullName ?? 'Contact person not set',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMiniTag(
                            icon: Icons.qr_code,
                            label: vendor.vendorUid ?? 'No ID',
                            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                            textColor: isDark ? Colors.grey[400]! : Colors.grey[700]!,
                          ),
                          const SizedBox(width: 8),
                          _buildMiniTag(
                            icon: Icons.phone,
                            label: vendor.phoneNumber ?? 'No Phone',
                            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                            textColor: isDark ? Colors.grey[400]! : Colors.grey[700]!,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
