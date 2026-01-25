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
    final status = vendorProfile!['verification_status'] ?? 'PENDING';
    
    // We can simulate some static data for the dashboard as requested
    final activeVisit = {
      'visitor': 'Ariento',
      'amount': '\$3', 
      'status': 'Recipient 1 Today',
      'last_month': 'Last month 12, 2023'
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Visit Card (Gradient based on primary color)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.8),
                  primaryColor.withOpacity(0.6),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
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
                    const Text(
                      'Active Visit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.8)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  activeVisit['amount']! + ' ' + activeVisit['visitor']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeVisit['status']!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // Pagination dots simulation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(true),
                    const SizedBox(width: 4),
                    _buildDot(false),
                    const SizedBox(width: 4),
                    _buildDot(false),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activeVisit['last_month']!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Quick Actions Grid (News, Stats, Visitor, Venos)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAction(context, Icons.bar_chart, 'News', isDark, primaryColor),
              _buildQuickAction(context, Icons.pie_chart, 'Stats', isDark, primaryColor),
              _buildQuickAction(context, Icons.person_add, 'Visitor', isDark, primaryColor),
              _buildQuickAction(context, Icons.settings, 'Venos', isDark, primaryColor),
            ],
          ),

          const SizedBox(height: 30),

          // Recent Activity Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'See All',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Activity List
          _buildActivityItem(context, 'Recent Activity', '1 hours ago', isDark, primaryColor),
          const SizedBox(height: 12),
          _buildActivityItem(context, 'Recent Activity', '1 hours ago', isDark, primaryColor),
        ],
      ),
    );
  }
  
  Widget _buildDot(bool isActive) {
    return Container(
      width: isActive ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, bool isDark, Color primaryColor) {
    final bgColor = isDark ? const Color(0xFF27272A) : Colors.white;
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark 
                ? null 
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Icon(icon, color: primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String subtitle, bool isDark, Color primaryColor) {
     final bgColor = isDark ? const Color(0xFF27272A) : Colors.white;
     
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
       decoration: BoxDecoration(
         color: bgColor,
         borderRadius: BorderRadius.circular(16),
         boxShadow: isDark 
             ? null 
             : [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.05),
                   blurRadius: 10,
                   offset: const Offset(0, 5),
                 ),
               ],
       ),
       child: Row(
         children: [
           Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: primaryColor.withOpacity(0.1),
               shape: BoxShape.circle,
               border: Border.all(color: primaryColor, width: 1),
             ),
             child: Icon(Icons.history, color: primaryColor, size: 20),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   title,
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                 ),
                 Text(
                   subtitle,
                   style: TextStyle(
                     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                     fontSize: 12
                   ),
                 ),
               ],
             ),
           ),
           Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
         ],
       ),
     );
  }
}
