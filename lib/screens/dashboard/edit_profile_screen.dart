import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/noise_background.dart';
import '../../widgets/motion/smooth_fade_in.dart';
import '../../widgets/motion/pressable_scale.dart';
import 'avatar_selection_sheet.dart'; // Import the new sheet

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final UserProfileService _profileService = UserProfileService();
  bool _isLoading = true;

  // Controllers
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _locationController = TextEditingController();

  String _gender = 'Male';
  String? _avatarUrl; // New: Store avatar URL

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);

      final user = _supabase.auth.currentUser;
      final profile = await _profileService.getUserProfile();

      if (mounted) {
        setState(() {
          // Pre-fill with existing data or defaults/auth data
          _fullNameController.text =
              profile?['name'] ?? user?.userMetadata?['full_name'] ?? '';
          _dobController.text = profile?['dob'] ?? '';
          _gender = profile?['gender'] ?? 'Male';
          _mobileController.text = profile?['phone'] ?? user?.phone ?? '';
          _emailController.text = profile?['email'] ?? user?.email ?? '';
          _occupationController.text = profile?['occupation'] ?? '';
          _locationController.text = profile?['location'] ?? '';
          _avatarUrl = profile?['avatar_url']; // Load avatar URL

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'name': _fullNameController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _gender,
        'phone': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'location': _locationController.text.trim(),
        'avatar_url': _avatarUrl, // Save avatar URL
      };

      await _profileService.updateFullUserProfile(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _showAvatarSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AvatarSelectionSheet(
        onAvatarSelected: (url) {
          setState(() {
            _avatarUrl = url;
          });
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryCTA,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('d MMMM y').format(picked);
      });
    }
  }

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
          "My Profile",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: NoiseBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.energyAccent,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- Avatar ---
                      SmoothFadeIn(
                        child: GestureDetector(
                          // Make avatar tappable
                          onTap: _showAvatarSelection,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.energyAccent,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: _avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                      : null,
                                  child: _avatarUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.border,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.energyAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SmoothFadeIn(
                        delay: const Duration(milliseconds: 200),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Basic Detail ---
                              _buildSectionTitle("Basic Detail"),
                              const SizedBox(height: 16),
                              _buildTextField("Full name", _fullNameController),
                              const SizedBox(height: 16),
                              _buildTextField(
                                "Date of birth",
                                _dobController,
                                icon: Icons.keyboard_arrow_down,
                                readOnly: true,
                                onTap: () => _selectDate(context),
                              ),
                              const SizedBox(height: 16),

                              Text(
                                "Gender",
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _buildGenderOption("Male")),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildGenderOption("Female")),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // --- Contact Detail ---
                              _buildSectionTitle("Contact Detail"),
                              const SizedBox(height: 16),
                              _buildTextField(
                                "Mobile number",
                                _mobileController,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                "Email",
                                _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 24),

                              // --- Personal Detail ---
                              _buildSectionTitle("Personal Detail"),
                              const SizedBox(height: 16),
                              _buildTextField(
                                "Occupation",
                                _occupationController,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField("Location", _locationController),

                              const SizedBox(height: 40),

                              // --- Save Button ---
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: PressableScale(
                                  onPressed: _saveProfile,
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors
                                          .energyAccent, // Action color
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      "Save",
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: AbsorbPointer(
              absorbing: onTap != null,
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                keyboardType: keyboardType,
                style: GoogleFonts.manrope(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  suffixIcon: icon != null
                      ? Icon(icon, color: AppColors.textSecondary)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.energyAccent
                : AppColors.border.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.energyAccent
                      : AppColors.textDisabled,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.energyAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
