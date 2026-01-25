import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_colors.dart';

import '../../features/verification/verification_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';

class AppDrawer extends StatelessWidget {
  final Map<String, dynamic>? vendorProfile;
  final VoidCallback? onRefresh;

  const AppDrawer({super.key, this.vendorProfile, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final email = vendorProfile?['email'] ?? 'Vendor';
    final uid = vendorProfile?['id']?.toString() ?? vendorProfile?['vendor_id'] ?? 'N/A';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Drawer(
      backgroundColor: isDark ? Colors.black : Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    top: 60,
                    left: 20,
                    right: 20,
                    bottom: 30,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).cardColor,
                          radius: 35,
                          child: Icon(
                            Icons.person,
                            size: 45,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        email,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Vendor ID: $uid',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(Icons.home, color: isDark ? Colors.white : Colors.black87),
                  title: Text('Home', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person, color: isDark ? Colors.white : Colors.black87),
                  title: Text('Profile', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                if (vendorProfile?['verification_status'] != 'VERIFIED')
                  ListTile(
                    leading: Icon(Icons.verified_user, color: isDark ? Colors.white : Colors.black87),
                    title: Text('Get Verified', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VerificationScreen(),
                        ),
                      );
                      if (result == true && onRefresh != null) {
                        onRefresh!();
                      }
                    },
                  ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
    );
  }
}

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? verificationStatus;
  final VoidCallback? onRefresh;

  const CommonAppBar({
    super.key,
    required this.title,
    this.verificationStatus,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 18,
        ),
      ),
      elevation: 0,
      centerTitle: true,
      actions: [
        if (verificationStatus != null)
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VerificationScreen(),
                ),
              );
              if (result == true && onRefresh != null) {
                onRefresh!();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: verificationStatus == 'VERIFIED'
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: verificationStatus == 'VERIFIED'
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    verificationStatus == 'VERIFIED'
                        ? Icons.verified
                        : Icons.pending,
                    size: 14,
                    color: verificationStatus == 'VERIFIED'
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    verificationStatus ?? 'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      color: verificationStatus == 'VERIFIED'
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
