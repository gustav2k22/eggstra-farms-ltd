import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_overlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  
  // Settings state
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _orderUpdates = true;
  bool _promotionalEmails = false;
  bool _darkMode = false;
  String _language = 'English';
  String _currency = 'GHS (₵)';
  
  final List<String> _languages = ['English', 'Twi', 'Ga', 'Ewe'];
  final List<String> _currencies = ['GHS (₵)', 'USD (\$)', 'EUR (€)'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    // TODO: Load settings from SharedPreferences or Firebase
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildNotificationSettings(),
                const SizedBox(height: 24),
                _buildAppearanceSettings(),
                const SizedBox(height: 24),
                _buildLanguageAndRegion(),
                const SizedBox(height: 24),
                _buildPrivacyAndSecurity(),
                const SizedBox(height: 24),
                _buildSupportAndInfo(),
                const SizedBox(height: 24),
                _buildAccountActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsSection(
      'Notifications',
      Icons.notifications_outlined,
      [
        _buildSwitchTile(
          'Push Notifications',
          'Receive push notifications on your device',
          _pushNotifications,
          (value) => setState(() => _pushNotifications = value),
        ),
        _buildSwitchTile(
          'Email Notifications',
          'Receive notifications via email',
          _emailNotifications,
          (value) => setState(() => _emailNotifications = value),
        ),
        _buildSwitchTile(
          'Order Updates',
          'Get notified about order status changes',
          _orderUpdates,
          (value) => setState(() => _orderUpdates = value),
        ),
        _buildSwitchTile(
          'Promotional Emails',
          'Receive promotional offers and deals',
          _promotionalEmails,
          (value) => setState(() => _promotionalEmails = value),
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildSettingsSection(
      'Appearance',
      Icons.palette_outlined,
      [
        _buildSwitchTile(
          'Dark Mode',
          'Use dark theme throughout the app',
          _darkMode,
          (value) => setState(() => _darkMode = value),
        ),
      ],
    );
  }

  Widget _buildLanguageAndRegion() {
    return _buildSettingsSection(
      'Language & Region',
      Icons.language_outlined,
      [
        _buildDropdownTile(
          'Language',
          'Choose your preferred language',
          _language,
          _languages,
          (value) => setState(() => _language = value!),
        ),
        _buildDropdownTile(
          'Currency',
          'Select your preferred currency',
          _currency,
          _currencies,
          (value) => setState(() => _currency = value!),
        ),
      ],
    );
  }

  Widget _buildPrivacyAndSecurity() {
    return _buildSettingsSection(
      'Privacy & Security',
      Icons.security_outlined,
      [
        _buildNavigationTile(
          'Privacy Policy',
          'View our privacy policy',
          Icons.privacy_tip_outlined,
          () => _showPrivacyPolicy(),
        ),
        _buildNavigationTile(
          'Terms of Service',
          'Read our terms of service',
          Icons.description_outlined,
          () => _showTermsOfService(),
        ),
        _buildNavigationTile(
          'Data Management',
          'Manage your personal data',
          Icons.folder_outlined,
          () => _showDataManagement(),
        ),
        _buildNavigationTile(
          'Change Password',
          'Update your account password',
          Icons.lock_outlined,
          () => _changePassword(),
        ),
      ],
    );
  }

  Widget _buildSupportAndInfo() {
    return _buildSettingsSection(
      'Support & Information',
      Icons.help_outline,
      [
        _buildNavigationTile(
          'Help Center',
          'Get help and support',
          Icons.help_center_outlined,
          () => _showHelpCenter(),
        ),
        _buildNavigationTile(
          'Contact Us',
          'Reach out to our support team',
          Icons.contact_support_outlined,
          () => _contactSupport(),
        ),
        _buildNavigationTile(
          'Rate App',
          'Rate us on the app store',
          Icons.star_outline,
          () => _rateApp(),
        ),
        _buildNavigationTile(
          'About',
          'App version and information',
          Icons.info_outline,
          () => _showAbout(),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return _buildSettingsSection(
          'Account',
          Icons.account_circle_outlined,
          [
            _buildNavigationTile(
              'Export Data',
              'Download your account data',
              Icons.download_outlined,
              () => _exportData(),
            ),
            _buildNavigationTile(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_forever_outlined,
              () => _deleteAccount(),
              isDestructive: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Sign Out',
                onPressed: () => _signOut(authProvider),
                variant: ButtonVariant.outline,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder.withValues(alpha: 77)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder.withValues(alpha: 77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: options.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.inputBackground.withValues(alpha: 128),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder.withValues(alpha: 77)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive ? AppColors.error : AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? AppColors.error : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 128),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Eggstra Farms Ltd Privacy Policy\n\n'
            'We are committed to protecting your privacy and personal information. '
            'This policy explains how we collect, use, and protect your data.\n\n'
            '1. Information We Collect\n'
            '- Personal information (name, email, phone)\n'
            '- Order and payment information\n'
            '- App usage analytics\n\n'
            '2. How We Use Your Information\n'
            '- Process orders and payments\n'
            '- Improve our services\n'
            '- Send order updates\n\n'
            '3. Data Protection\n'
            'We use industry-standard security measures to protect your data.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Eggstra Farms Ltd Terms of Service\n\n'
            'By using our app, you agree to these terms:\n\n'
            '1. Service Usage\n'
            '- Use the app for legitimate purposes only\n'
            '- Provide accurate information\n'
            '- Respect other users\n\n'
            '2. Orders and Payments\n'
            '- All orders are subject to availability\n'
            '- Payments must be made in full\n'
            '- Cancellation policy applies\n\n'
            '3. Liability\n'
            'We are not liable for damages beyond our control.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Management'),
        content: const Text(
          'Manage your personal data:\n\n'
          '• View all data we have about you\n'
          '• Request data corrections\n'
          '• Download your data\n'
          '• Request data deletion\n\n'
          'Contact support for data management requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _contactSupport();
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    // Navigate to change password screen or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change password feature will be implemented'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showHelpCenter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const SingleChildScrollView(
          child: Text(
            'Frequently Asked Questions\n\n'
            'Q: How do I place an order?\n'
            'A: Browse products, add to cart, and checkout.\n\n'
            'Q: What payment methods do you accept?\n'
            'A: We accept mobile money, card payments, and cash on delivery.\n\n'
            'Q: How long does delivery take?\n'
            'A: Standard delivery is 1-2 days, express is same day.\n\n'
            'Q: Can I cancel my order?\n'
            'A: Orders can be cancelled within 1 hour of placement.\n\n'
            'For more help, contact our support team.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _contactSupport();
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'Get in touch with our support team:\n\n'
          '📧 Email: support@eggstrafarmsghana.com\n'
          '📞 Phone: +233 XX XXX XXXX\n'
          '💬 WhatsApp: +233 XX XXX XXXX\n\n'
          'Support hours: 8:00 AM - 6:00 PM (Mon-Sat)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Our App'),
        content: const Text(
          'We hope you\'re enjoying the Eggstra Farms app! '
          'Your feedback helps us improve.\n\n'
          'Would you like to rate us on the app store?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Open app store rating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Eggstra Farms'),
        content: const Text(
          'Eggstra Farms Ltd\n'
          'Version 1.0.0\n\n'
          'Your trusted source for fresh, organic farm products '
          'delivered straight to your door.\n\n'
          'Founded in Ghana, we\'re committed to providing the '
          'highest quality eggs, poultry, dairy, and produce '
          'from our sustainable farms.\n\n'
          '© 2024 Eggstra Farms Ltd. All rights reserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'We\'ll prepare your account data for download. '
          'This includes your profile information, order history, '
          'and preferences.\n\n'
          'You\'ll receive an email with the download link within 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export request submitted'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Request Export'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account?\n\n'
          'This action cannot be undone. All your data, including '
          'order history and preferences, will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion is not implemented yet'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _signOut(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
