import 'package:flutter/material.dart';

class TermsOfService extends StatelessWidget {
  const TermsOfService({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Acceptance of Terms',
              'By downloading, installing, and using the Sudoku Legend mobile application ("App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.'),
            _buildSection('2. License Grant',
              '''
We grant you a limited, non-exclusive, non-transferable, revocable license to:
• Download and install the App on your personal devices
• Use the App for your personal, non-commercial entertainment purposes
• Access content and features provided within the App

You may not:
• Copy, modify, or create derivative works of the App
• Reverse engineer, decompile, or disassemble the App
• Rent, lease, or lend the App to others
• Use the App for commercial purposes
• Remove or alter any copyright, trademark, or other proprietary notices'''),
            _buildSection('3. User Accounts',
              '''
• You are responsible for maintaining the confidentiality of your account credentials
• You agree to provide accurate, current, and complete information
• You are responsible for all activities that occur under your account
• You agree to notify us immediately of unauthorized account access
• Accounts may be suspended or terminated for violation of these terms'''),
            _buildSection('4. User Conduct',
              '''
You agree not to:
• Harass, abuse, or threaten other users
• Post offensive, explicit, or discriminatory content
• Attempt to manipulate leaderboards or game scores
• Use cheats, hacks, or exploits
• Engage in any illegal activity
• Impersonate another person
• Attempt to access unauthorized areas of the App
• Create multiple accounts to gain unfair advantages
• Share or sell your account credentials'''),
            _buildSection('5. Intellectual Property Rights',
              '''
• All content, code, graphics, design, and functionality are owned by Sudoku Legend or its licensors
• "Sudoku Legend" name and logo are trademarks of Sudoku Legend
• You may not use our intellectual property without explicit permission
• User-generated content (profiles, usernames) may be used by us for service improvement'''),
            _buildSection('6. Game Features & Leaderboards',
              '''
• Leaderboard rankings are based on verified game scores
• Cheating, hacking, or manipulating scores may result in permanent ban
• Rankings may be reset due to app updates or maintenance
• We reserve the right to remove or disqualify scores obtained through prohibited means
• Daily challenges reset at midnight (user's timezone)
• Achievements and badges are earned through legitimate gameplay'''),
            _buildSection('7. In-App Purchases & Content',
              '''
• Prices are subject to change
• Purchases are final and non-refundable except as required by law
• Digital items do not transfer between accounts
• We may discontinue features, content, or services at any time'''),
            _buildSection('8. Limitation of Liability',
              '''
TO THE FULLEST EXTENT PERMITTED BY LAW:
• The App is provided "as-is" without warranties of any kind
• We are not liable for indirect, incidental, special, or consequential damages
• Our total liability is limited to the amount paid for the App (if any)
• We are not responsible for lost game data due to device failure or data loss
• We are not liable for temporary service interruptions or maintenance'''),
            _buildSection('9. Disclaimer',
              '''
• The App is provided without warranties, express or implied
• We do not warrant that the App will be uninterrupted or error-free
• We do not guarantee specific game results or rankings
• Your use of the App is at your own risk'''),
            _buildSection('10. Termination',
              '''
We may terminate or suspend your account and access to the App:
• If you violate these Terms of Service
• If you engage in illegal activity
• If you abuse the service or other users
• For any reason at our sole discretion
• Upon your request

Upon termination, your right to use the App immediately ceases.'''),
            _buildSection('11. Modifications to Terms',
              '''
We may modify these Terms of Service at any time. Changes are effective immediately upon posting to the App. Your continued use of the App constitutes acceptance of modified terms. We will notify you of material changes.'''),
            _buildSection('12. Privacy',
              '''
Your use of the App is also governed by our Privacy Policy. Please review the Privacy Policy to understand our practices regarding your personal information.'''),
            _buildSection('13. Governing Law',
              '''
These Terms of Service are governed by and construed in accordance with applicable laws. Any disputes arising from these terms shall be resolved through binding arbitration, except where prohibited by law.'''),
            _buildSection('14. Severability',
              '''
If any provision of these Terms is found to be invalid or unenforceable, the remaining provisions shall remain in effect.'''),
            _buildSection('15. Contact Information',
              '''
For questions about these Terms of Service, contact us at:
Email: aregbeayomide@gmail.com

We will respond to your inquiry within 30 days.'''),
            _buildSection('16. Entire Agreement',
              '''
These Terms of Service, together with our Privacy Policy, constitute the entire agreement between you and Sudoku Legend regarding your use of the App.'''),
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