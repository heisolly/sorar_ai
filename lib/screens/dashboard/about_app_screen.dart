import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Added import

import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/noise_background.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  final String _version = "1.0.0";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About App",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: NoiseBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // App Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCTA.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset('assets/logo.png', width: 60, height: 60),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Parot",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Version $_version",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Parot is your intelligent companion for navigating social complexities. Whether you're practicing for a date, a job interview, or just want to improve your conversational skills, we're here to help.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Legal Links
              _buildLegalLink(
                context,
                "Terms of Service",
                "https://example.com/terms",
              ), // Updated call
              const Divider(height: 1),
              _buildLegalLink(
                context,
                "Privacy Policy",
                "https://example.com/privacy",
              ), // Updated call
              const Divider(height: 1),
              _buildLegalLink(
                context,
                "Licenses",
                "https://example.com/licenses",
              ), // Updated call
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Added _launchUrl method
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  // Modified _buildLegalLink method
  Widget _buildLegalLink(BuildContext context, String title, String url) {
    return InkWell(
      onTap: () => _launchUrl(context, url), // Updated onTap
      borderRadius: BorderRadius.circular(8), // Added borderRadius
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
