import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/noise_background.dart';
import '../../widgets/motion/smooth_fade_in.dart';
import '../../widgets/motion/pressable_scale.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      "question": "What is Parot?",
      "answer":
          "Parot is your personal AI coach for mastering real-world conversations and challenges. From Rizz tests to professional roleplays, we help you level up your social game.",
    },
    {
      "question": "How do simulations work?",
      "answer":
          "Simulations are interactive roleplay scenarios where you chat with an AI character. You receive real-time feedback and a score based on your performance.",
    },
    {
      "question": "Is my data private?",
      "answer":
          "Yes! Your chats and progress are stored securely. We prioritize your privacy and do not share your personal conversations.",
    },
    {
      "question": "Can I customize the scenarios?",
      "answer":
          "Absolutely! Use the 'Custom Scenario' feature to define exactly who you want to talk to and what the situation is.",
    },
    {
      "question": "How is my Rizz Level calculated?",
      "answer":
          "Your Rizz Level is based on the average confidence score from your completed simulations. The more you play and improve, the higher your level!",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: PressableScale(
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Text(
          "FAQ",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: NoiseBackground(
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: _faqs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final faq = _faqs[index];
            return SmoothFadeIn(
              delay: Duration(milliseconds: index * 50),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      faq['question']!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    iconColor: AppColors.primaryCTA,
                    collapsedIconColor: AppColors.textSecondary,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['answer']!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
