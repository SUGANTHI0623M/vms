import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HomeView extends StatelessWidget {
  final Map<String, dynamic>? vendorProfile;

  const HomeView({super.key, this.vendorProfile});

  @override
  Widget build(BuildContext context) {
    if (vendorProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final email = vendorProfile!['email'] ?? 'User';
    final name = vendorProfile!['full_name'] ?? email.split('@')[0];
    final uid =
        vendorProfile!['vendor_uid'] ??
        vendorProfile!['id']?.toString() ??
        '...';
    final status = vendorProfile!['verification_status'] ?? 'PENDING';
    final bool isVerified = status == 'VERIFIED';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium Welcome Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF3F3F46), const Color(0xFF18181B)] // Dark grey gradient
                    : [AppColors.primary, AppColors.primary.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.5) : AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: isDark ? Border.all(color: AppColors.darkPrimary.withOpacity(0.3)) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: TextStyle(
                            color: isDark ? AppColors.darkPrimary : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildHomeBadge(icon: Icons.fingerprint, label: 'ID: $uid', isDark: isDark),
                    const SizedBox(width: 12),
                    _buildHomeBadge(
                      icon: isVerified ? Icons.verified : Icons.pending,
                      label: status,
                      isSuccess: isVerified,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Quick Actions or Stats section could go here
          Text(
            'Recent Activities',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityPlaceholder(context),
        ],
      ),
    );
  }

  Widget _buildHomeBadge({
    required IconData icon,
    required String label,
    bool isSuccess = false,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: isDark && isSuccess ? Border.all(color: AppColors.darkPrimary) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark && isSuccess ? AppColors.darkPrimary : Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark && isSuccess ? AppColors.darkPrimary : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.insights, size: 48, color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Activity feed coming soon...',
            style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
