import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_common_widgets.dart';
import '../home/home_view.dart';
import '../vendors/vendors_view.dart';
import '../visit_register/visiting_register_view.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _vendorProfile;
  bool _isLoading = true;
  int _currentIndex = 1; // Default to Home (middle)
  final List<String> _titles = ['Vendors', 'Home Feed', 'Visit Register', 'Settings'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Key _viewKey = UniqueKey();

  Future<void> _loadProfile() async {
    final authService = context.read<AuthService>();
    if (authService.token != null) {
      print('Dashboard: Loading profile for token: ${authService.token!.substring(0, 20)}...');
      final vendorService = VendorService(authService.token!);
      final profile = await vendorService.getVendorProfile();
      if (mounted) {
        print('Dashboard: Profile loaded - ID: ${profile?['id']}, Email: ${profile?['email']}, Company: ${profile?['company_name']}');
        setState(() {
          _vendorProfile = profile;
          _isLoading = false;
          // Force refresh of children views by updating key
          _viewKey = UniqueKey();
        });
      }
    } else {
      print('Dashboard: No token available');
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        vendorProfile: _vendorProfile,
      ), // Pass callback to refresh global state
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: _currentIndex == 3 // Hide CommonAppBar for Settings as it has its own
          ? null 
          : CommonAppBar(
              title: _titles[_currentIndex],
              verificationStatus: status,
              onRefresh: _loadProfile,
            ),
      drawer: AppDrawer(vendorProfile: _vendorProfile, onRefresh: _loadProfile),
      body: views[_currentIndex], // Removed hardcoded color container
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
          // Use theme colors
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? AppColors.primary,
          unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[400],
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
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
