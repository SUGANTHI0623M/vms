import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/visit_service.dart';
import '../../services/location_service.dart';
import '../checkin/checkin_screen.dart';
import 'visit_action_screen.dart';
import '../verification/verification_screen.dart';

class VisitingRegisterView extends StatefulWidget {
  final VoidCallback? onCheckInComplete;
  final Map<String, dynamic>? vendorProfile;

  const VisitingRegisterView({super.key, this.onCheckInComplete, this.vendorProfile});

  @override
  State<VisitingRegisterView> createState() => _VisitingRegisterViewState();
}

class _VisitingRegisterViewState extends State<VisitingRegisterView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _visits = [];
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: History
  List<Map<String, dynamic>> _companyLocations = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanyLocations().then((_) {
      _fetchVisits();
    });
  }

  Future<void> _fetchVisits() async {
    setState(() => _isLoading = true);
    final token = context.read<AuthService>().token;
    if (token != null) {
      final visitService = VisitService();
      final data = await visitService.getMyVisits(token);
      if (mounted) {
        setState(() {
          _visits = data?.cast<Map<String, dynamic>>() ?? [];
          // Sort by latest
          _visits.sort((a, b) {
             final tA = a['requested_at'] ?? '';
             final tB = b['requested_at'] ?? '';
             return tB.compareTo(tA);
          });
          _isLoading = false;
        });
      }
    } else {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCompanyLocations() async {
    final token = context.read<AuthService>().token;
    if (token != null) {
      try {
        final visitService = VisitService();
        final locations = await visitService.getCompanyLocations(token);
        if (mounted) {
          setState(() {
            _companyLocations = locations ?? [];
          });
          print('DEBUG: Loaded ${_companyLocations.length} company locations');
          if (_companyLocations.isNotEmpty) {
            print('DEBUG: First location: ${_companyLocations.first}');
          }
        }
      } catch (e) {
        print('DEBUG: Error fetching company locations: $e');
        if (mounted) {
          setState(() {
            _companyLocations = [];
          });
        }
      }
    }
  }

  // Haversine formula to calculate distance in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth radius in meters
    final double phi1 = lat1 * (math.pi / 180);
    final double phi2 = lat2 * (math.pi / 180);
    final double deltaPhi = (lat2 - lat1) * (math.pi / 180);
    final double deltaLambda = (lon2 - lon1) * (math.pi / 180);

    final double a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) *
        math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  // Find company name based on location (within 300m)
  String? _detectCompanyName(double? lat, double? lon) {
    if (lat == null || lon == null) {
      print('DEBUG: Cannot detect company - lat or lon is null');
      return null;
    }
    
    if (_companyLocations.isEmpty) {
      print('DEBUG: No company locations loaded');
      return null;
    }

    const double thresholdMeters = 300.0;
    List<Map<String, dynamic>> nearbyCompanies = [];

    for (var location in _companyLocations) {
      final companyLat = location['latitude'];
      final companyLon = location['longitude'];
      
      double? parsedLat;
      double? parsedLon;
      
      if (companyLat != null) {
        parsedLat = companyLat is double ? companyLat : double.tryParse(companyLat.toString());
      }
      if (companyLon != null) {
        parsedLon = companyLon is double ? companyLon : double.tryParse(companyLon.toString());
      }
      
      if (parsedLat != null && parsedLon != null) {
        final distance = _calculateDistance(lat, lon, parsedLat, parsedLon);
        if (distance <= thresholdMeters) {
          nearbyCompanies.add({
            'company_name': location['company_name'] as String,
            'distance': distance,
          });
          print('DEBUG: Found nearby company: ${location['company_name']} at ${distance.toStringAsFixed(2)}m');
        }
      }
    }

    if (nearbyCompanies.isEmpty) {
      print('DEBUG: No companies found within 300m of lat: $lat, lon: $lon');
      return null;
    }

    // Sort by company name alphabetically, then return the first one
    nearbyCompanies.sort((a, b) {
      final nameA = (a['company_name'] as String).toLowerCase();
      final nameB = (b['company_name'] as String).toLowerCase();
      return nameA.compareTo(nameB);
    });

    final detectedName = nearbyCompanies.first['company_name'] as String;
    print('DEBUG: Detected company name: $detectedName');
    return detectedName;
  }

  Future<void> _handleCheckAction(Map<String, dynamic> visit, bool isCheckIn) async {
    final visitId = visit['id'];
    
    // Check for cached location first to speed up
    final locationService = context.read<LocationService>();
    if (locationService.currentPosition == null) {
       locationService.fetchLocation(); 
    }

    // Navigate to the new VisitActionScreen instead of showing dialog
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitActionScreen(
          visitId: visitId,
          isCheckIn: isCheckIn,
          onSuccess: () {
            // onSuccess is handled below by reloading
          },
        ),
      ),
    );
    // Reload visits after returning from action screen
    _fetchVisits();
    widget.onCheckInComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final locationService = context.watch<LocationService>();
    final currentAddress = locationService.currentAddress;
    final currentPosition = locationService.currentPosition;

    return Column(
      children: [
        // Location Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDark ? const Color(0xFF27272A) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                   Icon(Icons.location_on, color: primaryColor),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           currentAddress ?? "Fetching location...",
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             color: isDark ? Colors.white : Colors.black,
                             fontSize: 14,
                           ),
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
            ),
          ),
        ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                   final isVerified = widget.vendorProfile?['verification_status'] == 'VERIFIED';
                   
                   if (!isVerified) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(
                         content: Text("Get verified to check in"),
                         backgroundColor: Colors.orange,
                         duration: Duration(seconds: 2),
                       ),
                     );
                     
                     // Navigate to verification screen
                     final result = await Navigator.push(
                       context, 
                       MaterialPageRoute(builder: (_) => const VerificationScreen())
                     );
                     
                     if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Verified! Refreshing soon..."),
                            backgroundColor: Colors.green,
                          ),
                        );
                        widget.onCheckInComplete?.call();
                     }
                     return;
                   }

                   await Navigator.push(context, MaterialPageRoute(builder: (_) => CheckInScreen()));
                   _fetchVisits();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("New Visit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 10),
              _buildFilterChip("All Visits", 0, primaryColor, isDark),
              const SizedBox(width: 10),
              _buildFilterChip("Active", 1, primaryColor, isDark),
              const SizedBox(width: 10),
              _buildFilterChip("History", 2, primaryColor, isDark),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _visits.isEmpty
                  ? Center(child: Text("No visits found", style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _visits.length,
                      itemBuilder: (context, index) {
                        final visit = _visits[index];
                        // Try to get selfie and location from raw map
                        final checkInSelfieUrl = visit['check_in_selfie_url'] ?? visit['selfie_url'];
                        final checkOutSelfieUrl = visit['check_out_selfie_url'];
                        final lat = visit['check_in_latitude'];
                        final long = visit['check_in_longitude'];
                          final checkInAddress = visit['check_in_location'] ?? visit['location']; 
                        final checkOutAddress = visit['check_out_location'];
                        
                        return _buildVisitCard(visit, isDark, primaryColor, checkInSelfieUrl, checkOutSelfieUrl, lat, long, checkInAddress, checkOutAddress);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index, Color primary, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primary : Colors.grey[600]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? (ThemeData.estimateBrightnessForColor(primary) == Brightness.dark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit, bool isDark, Color primary, String? checkInSelfieUrl, String? checkOutSelfieUrl, dynamic lat, dynamic long, String? checkInAddress, String? checkOutAddress) {
    // First, try to detect company name based on location
    double? visitLat;
    double? visitLon;
    
    if (lat != null) {
      if (lat is double) {
        visitLat = lat;
      } else if (lat is int) {
        visitLat = lat.toDouble();
      } else {
        visitLat = double.tryParse(lat.toString());
      }
    }
    
    if (long != null) {
      if (long is double) {
        visitLon = long;
      } else if (long is int) {
        visitLon = long.toDouble();
      } else {
        visitLon = double.tryParse(long.toString());
      }
    }
    
    print('DEBUG: Visit card - lat: $visitLat, lon: $visitLon');
    final String? detectedCompanyName = _detectCompanyName(visitLat, visitLon);
    
    // Parsing purpose
    String fullPurpose = visit['purpose'] ?? 'Visit';
    String parsedCompanyName = fullPurpose;
    String? description;

    // Try to extract Company from "Visiting: Company. Description" or "Visiting: Company"
    if (fullPurpose.toLowerCase().startsWith('visiting: ')) {
      String temp = fullPurpose.substring(10); // Remove "Visiting: "
      if (temp.contains('.')) {
        int dotIndex = temp.indexOf('.');
        parsedCompanyName = temp.substring(0, dotIndex).trim();
        description = temp.substring(dotIndex + 1).trim();
      } else {
        parsedCompanyName = temp.trim();
        description = null;
      }
    } else {
        if (fullPurpose.contains('.')) {
             int dotIndex = fullPurpose.indexOf('.');
             parsedCompanyName = fullPurpose.substring(0, dotIndex).trim();
             description = fullPurpose.substring(dotIndex + 1).trim();
        }
    }
    
    // Use detected company name when available (same value we log)
    final String companyName = (detectedCompanyName != null && detectedCompanyName.isNotEmpty)
        ? detectedCompanyName
        : parsedCompanyName;
    
    if (detectedCompanyName != null && detectedCompanyName.isNotEmpty) {
      print('DEBUG: Using detected company name: $detectedCompanyName -> showing in card: "$companyName"');
    } else {
      print('DEBUG: No company detected, using parsed name: $companyName');
    }

    final dateRaw = visit['check_in_time'] ?? visit['requested_at'];
    final date = dateRaw != null ? (dateRaw as String).split('T')[0] : 'Unknown Date';
    
    final timeIn = visit['check_in_time'] != null 
        ? (visit['check_in_time'] as String).split('T')[1].substring(0, 5) 
        : '--:--';
        
    final timeOut = visit['check_out_time'] != null 
        ? (visit['check_out_time'] as String).split('T')[1].substring(0, 5) 
        : '--:--';
        
    final isCheckedIn = visit['check_in_time'] != null;
    final isCheckedOut = visit['check_out_time'] != null;
    final status = visit['status']; // APPROVED, COMPLETED, etc.
    
    // Filter logic
    if (_selectedFilterIndex == 1 && isCheckedOut) return const SizedBox.shrink(); // Active only
    if (_selectedFilterIndex == 2 && !isCheckedOut) return const SizedBox.shrink(); // History only (completed)
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null && description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          description,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCheckedOut ? Colors.grey : (isCheckedIn ? Colors.green : Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCheckedOut ? "Completed" : (isCheckedIn ? "Checked In" : (status ?? "Pending")),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if ((checkInSelfieUrl != null && checkInSelfieUrl.isNotEmpty) || (checkOutSelfieUrl != null && checkOutSelfieUrl.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                   if (checkInSelfieUrl != null && checkInSelfieUrl.isNotEmpty)
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text("Check In", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                         const SizedBox(height: 4),
                         ClipRRect(
                           borderRadius: BorderRadius.circular(8),
                           child: Image.network(
                             checkInSelfieUrl,
                             height: 60,
                             width: 60,
                             fit: BoxFit.cover,
                             errorBuilder: (ctx, err, stack) => Container(
                               height: 60,
                               width: 60,
                               color: Colors.grey[300],
                               child: const Center(child: Icon(Icons.broken_image, size: 20, color: Colors.grey)),
                             ),
                           ),
                         ),
                       ],
                     ),
                   if (checkInSelfieUrl != null && checkInSelfieUrl.isNotEmpty && checkOutSelfieUrl != null && checkOutSelfieUrl.isNotEmpty)
                     const SizedBox(width: 10),
                   if (checkOutSelfieUrl != null && checkOutSelfieUrl.isNotEmpty)
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text("Check Out", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                         const SizedBox(height: 4),
                         ClipRRect(
                           borderRadius: BorderRadius.circular(8),
                           child: Image.network(
                             checkOutSelfieUrl,
                             height: 60,
                             width: 60,
                             fit: BoxFit.cover,
                             errorBuilder: (ctx, err, stack) => Container(
                               height: 60,
                               width: 60,
                               color: Colors.grey[300],
                               child: const Center(child: Icon(Icons.broken_image, size: 20, color: Colors.grey)),
                             ),
                           ),
                         ),
                       ],
                     ),
                ],
              ),
            ),

          // Address / Location (Moved right after Selfie)
          if (checkInAddress != null || checkOutAddress != null || (lat != null && long != null))
             Padding(
               padding: const EdgeInsets.only(bottom: 8),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (checkInAddress != null && checkInAddress.isNotEmpty) ...[
                               Row(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Check In Location:", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold)),
                                          if (companyName.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2.0),
                                              child: Text(
                                                companyName,
                                                style: TextStyle(
                                                  color: isDark ? Colors.white : Colors.black,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          Text(
                                            checkInAddress,
                                            style: TextStyle(
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                 ],
                               ),
                               const SizedBox(height: 8),
                            ],
                            if (checkOutAddress != null && checkOutAddress.isNotEmpty) ...[
                               Row(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Check Out Location:", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold)),
                                          if (companyName.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2.0),
                                              child: Text(
                                                companyName,
                                                style: TextStyle(
                                                  color: isDark ? Colors.white : Colors.black,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          Text(
                                            checkOutAddress,
                                            style: TextStyle(
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                 ],
                               ),
                               const SizedBox(height: 8),
                            ],
                   // Fallback to Lat/Long if no address
                   if ((checkInAddress == null && checkOutAddress == null) && (lat != null && long != null))
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         if (companyName.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.only(bottom: 4.0),
                             child: Text(
                               companyName,
                               style: TextStyle(
                                 color: isDark ? Colors.white : Colors.black,
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold,
                               ),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         Row(
                           children: [
                             Icon(Icons.location_on, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                             const SizedBox(width: 4),
                             Expanded(
                               child: Text(
                                 "Lat: $lat, Long: $long",
                                 style: TextStyle(
                                   color: isDark ? Colors.grey[400] : Colors.grey[600],
                                   fontSize: 12,
                                 ),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                 ],
               ),
             ),

          const Divider(height: 20),
          
          // Date & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn("Date", date, isDark),
              _buildTimeColumn("In", timeIn, isDark),
              _buildTimeColumn("Out", timeOut, isDark),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Action Buttons
          if ((status == 'APPROVED' || status == 'WAITING') || (isCheckedIn && !isCheckedOut)) ...[
             const SizedBox(height: 16),
             SizedBox(
               width: double.infinity,
               child: !isCheckedIn 
                 ? ElevatedButton.icon(
                     onPressed: () => _handleCheckAction(visit, true),
                     icon: const Icon(Icons.login),
                     label: const Text("Check In"),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.green,
                       foregroundColor: Colors.white,
                     ),
                   )
                 : !isCheckedOut
                     ? ElevatedButton.icon(
                         onPressed: () => _handleCheckAction(visit, false),
                         icon: const Icon(Icons.logout),
                         label: const Text("Check Out"),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.red,
                           foregroundColor: Colors.white,
                         ),
                       )
                     : const SizedBox.shrink(),
             ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTimeColumn(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
