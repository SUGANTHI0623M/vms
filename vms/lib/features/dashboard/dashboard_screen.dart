import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_common_widgets.dart';
import '../home/home_view.dart';
import '../vendors/vendors_view.dart';
import '../visit_register/visiting_register_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _vendorProfile;
  bool _isLoading = true;
  int _currentIndex = 1; // Default to Home (middle)
  final List<String> _titles = ['Vendors', 'Home Feed', 'Visit Register'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Key _viewKey = UniqueKey();

  Future<void> _loadProfile() async {
    final authService = context.read<AuthService>();
    if (authService.token != null) {
      final vendorService = VendorService(authService.token!);
      final profile = await vendorService.getVendorProfile();
      if (mounted) {
        setState(() {
          _vendorProfile = profile;
          _isLoading = false;
          // Force refresh of children views by updating key
          _viewKey = UniqueKey();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = _vendorProfile?['verification_status'] ?? 'PENDING';

    final List<Widget> views = [
      VendorsView(key: _viewKey),
      HomeView(vendorProfile: _vendorProfile), // Home takes profile directly
      VisitingRegisterView(
        onCheckInComplete: _loadProfile,
      ), // Pass callback to refresh global state
    ];

    return Scaffold(
      appBar: CommonAppBar(
        title: _titles[_currentIndex],
        verificationStatus: status,
        onRefresh: _loadProfile,
      ),
      drawer: AppDrawer(vendorProfile: _vendorProfile, onRefresh: _loadProfile),
      body: Container(color: Colors.white, child: views[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Vendors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Register',
            ),
          ],
        ),
      ),
    );
  }
}
