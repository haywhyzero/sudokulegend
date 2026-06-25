import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Introduction',
              'Sudoku Legend ("we", "us", "our", or "Company") operates the Sudoku Legend mobile application (the "App"). This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our App.'),
            _buildSection('2. Information We Collect',
              '''
a) Account Information:
• Name and email address (when creating an account via email or Google Sign-In)
• Profile picture and username
• Country/region information for localization

b) Game Data:
• Game progress, scores, and statistics
• Completed puzzles and game history
• Difficulty levels played
• Time spent playing
• Achievements and badges earned

c) Device Information:
• Device type and operating system
• App version
• Device identifier (for analytics)
• Crash logs and error reports

d) Usage Information:
• Features used and frequency
• Game settings preferences
• Audio and notification preferences

e) Media Access:
• Camera access (if user grants permission)
• Photos/gallery access (if user grants permission)
• Audio files for game sounds'''),
            _buildSection('3. How We Use Your Information',
              '''
We use the collected information for:
• Creating and maintaining your account
• Personalizing your gaming experience
• Generating leaderboards and rankings
• Tracking game progress and statistics
• Sending game notifications and achievements
• Improving app features and performance
• Detecting and preventing fraud or misuse
• Complying with legal requirements
• Analytics and crash reporting
• Firebase-based cloud synchronization'''),
            _buildSection('4. Data Storage & Security',
              '''
• Your data is stored securely using Google Firebase services
• Authentication is handled through Firebase Authentication
• Game data is synchronized across your devices via Firebase Firestore
• We use industry-standard encryption for data transmission (SSL/TLS)
• Your password is never stored in plain text
• Access to personal data is restricted to authorized personnel only'''),
            _buildSection('5. Third-Party Services',
              '''
Our App uses the following third-party services:
• Firebase (Google) - for authentication, cloud storage, and analytics
• Google Sign-In - for account creation and authentication
• Google Analytics - for app usage analytics
• Firebase Crashlytics - for crash reporting and diagnostics

These services have their own privacy policies that govern their data handling practices.'''),
            _buildSection('6. Permissions',
              '''
The App requests the following permissions:
• Camera - for potential future features (optional)
• Photos/Gallery Access - for profile pictures (optional)
• Audio - for game sounds and notifications
• Internet - for cloud sync and online features
• Notifications - for game alerts and achievements

You can manage these permissions through your device settings.'''),
            _buildSection('7. Data Retention',
              '''
• Account data is retained as long as your account is active
• Game statistics are retained indefinitely for leaderboard purposes
• Crash logs are retained for 90 days
• You can request data deletion by contacting us'''),
            _buildSection('8. User Rights',
              '''
You have the right to:
• Access your personal data
• Correct inaccurate information
• Request deletion of your account and data
• Opt-out of non-essential communications
• Export your game data

Contact us at [support email] to exercise these rights.'''),
            _buildSection('9. Children\'s Privacy',
              '''
The App does not knowingly collect personal information from children under 13. If we learn that we have collected personal information from a child under 13 without parental consent, we will delete such information promptly.'''),
            _buildSection('10. Changes to Privacy Policy',
              '''
We may update this Privacy Policy from time to time. We will notify you of any material changes by updating the "Last Updated" date and posting the revised policy in the App. Your continued use of the App constitutes acceptance of the updated Privacy Policy.'''),
            _buildSection('11. Contact Us',
              '''
If you have questions about this Privacy Policy or our privacy practices, please contact us at:
Email: aregbeayomide@gmail.com

We will respond to your inquiry within 30 days.'''),
            _buildSection('Last Updated', 'June 5, 2026'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF53698A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}