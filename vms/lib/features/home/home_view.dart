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
                colors: [AppColors.primary, AppColors.primary.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
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
                          style: const TextStyle(
                            color: Colors.white,
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
                    _buildHomeBadge(icon: Icons.fingerprint, label: 'ID: $uid'),
                    const SizedBox(width: 12),
                    _buildHomeBadge(
                      icon: isVerified ? Icons.verified : Icons.pending,
                      label: status,
                      isSuccess: isVerified,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Quick Actions or Stats section could go here
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildHomeBadge({
    required IconData icon,
    required String label,
    bool isSuccess = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.insights, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Activity feed coming soon...',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
