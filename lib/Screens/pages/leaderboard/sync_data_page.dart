import 'package:flutter/material.dart';

class SyncDataPage extends StatelessWidget {
  const SyncDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sign In",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 40),
        
              Image.asset(
                "assets/images/299097_sync_cloud_icon.png", 
                height: 180,
                fit: BoxFit.contain,
              ),
        
              const SizedBox(height: 30),
        
              // Sync status text
              Text(
                "Login to sync data...",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
        
              const SizedBox(height: 50),
        
              // Continue with Google
              _buildSocialButton(
                label: "Continue with Google",
                logoPath: "assets/icons/google_logo.png",
                backgroundColor: Colors.white,
                borderColor: Colors.grey.shade300,
                onTap: () {},
              ),
        
              const SizedBox(height: 16),
        
              // Continue with Facebook
              _buildSocialButton(
                label: "Continue with Facebook",
                logoPath: "assets/icons/facebook.png", 
                backgroundColor: Colors.white,
                borderColor: Colors.grey.shade300,
                onTap: () {},
              ),
        
              const SizedBox(height: 16),
        
              // Continue with Apple
              _buildSocialButton(
                label: "Continue with Apple",
                isIcon: true,
                iconLogo: Icons.apple,
                backgroundColor: Colors.white,
                borderColor: Colors.grey.shade300,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Color backgroundColor,
    String? logoPath,
    bool isIcon = false,
    IconData? iconLogo,
    Color? textColor,
    Color? borderColor,
    Color? logoColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
            isIcon ? Icon(iconLogo)
            : Image.asset(
              "$logoPath",
              width: 24,
              height: 24,
              color: logoColor,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.flutter_dash, size: 24);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}