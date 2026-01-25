import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Appearance'),
          
          // Theme Mode Toggle
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme for the app'),
            value: themeService.isDarkMode,
            activeColor: themeService.primaryColor,
            onChanged: (value) {
              themeService.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
            secondary: Icon(
              themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: themeService.primaryColor,
            ),
          ),
          
          const Divider(),
          
          // Color Palette Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Accent Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildColorOption(context, AppColors.primaryBlue, "Blue"),
                _buildColorOption(context, AppColors.primaryRose, "Rose"),
                _buildColorOption(context, AppColors.primaryGreen, "Green"),
                _buildColorOption(context, AppColors.primaryYellow, "Gold"),
                _buildColorOption(context, AppColors.primaryPurple, "Purple"),
              ],
            ),
          ),

          const Divider(),
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: Icon(Icons.person, color: themeService.primaryColor),
            title: const Text('Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to profile
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications, color: themeService.primaryColor),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to notifications settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(BuildContext context, Color color, String label) {
    final themeService = context.read<ThemeService>();
    final isSelected = themeService.primaryColor.value == color.value;
    
    return GestureDetector(
      onTap: () => themeService.setPrimaryColor(color),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected 
                  ? Border.all(color: Theme.of(context).colorScheme.onBackground, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: isSelected 
                ? const Icon(Icons.check, color: Colors.white) 
                : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthService>().logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
