# Implementation Plan - Theme & Font Refinement

This plan details the changes made to align the application with the "Warm base + Indigo accent" theme and "Outfit + Manrope" typography.

## User Objectives

- **Aesthetic:** Premium, confident, modern, not childish.
- **Color Palette:** Warm base + Indigo accent.
- **Typography:** Outfit (Headlines) + Manrope (Body/Buttons).

## Changes Implemented

### 1. Theme Configuration (`lib/theme/app_theme.dart`)

- Updated `AppColors.energyAccent` to `Color(0xFF6366F1)` (Muted Indigo).
- Updated `lightTheme` primary color scheme to use `AppColors.energyAccent`.
- Updated Text Styles:
  - `displayLarge`, `displayMedium`, `displaySmall`, `headlineMedium`, `titleLarge` -> `GoogleFonts.outfit`.
  - `bodyLarge`, `bodyMedium`, `labelLarge` -> `GoogleFonts.manrope`.
- Updated Button Themes (`ElevatedButton`, `OutlinedButton`, `TextButton`) to use `AppColors.energyAccent` for backgrounds/foregrounds.

### 2. Screen-Specific Updates

#### Authentication & Onboarding

- **`AuthScreen`, `SignUpScreen`, `SignInScreen`, `WelcomeOnboardingScreen`**:
  - Updated Headlines to `Outfit`.
  - Updated Body/Labels to `Manrope`.
  - Updated Primary Actions/Links to `AppColors.energyAccent`.

#### Dashboard & Navigation

- **`DashboardScreen`**: Updated Navigation Bar fonts and active colors.
- **`HomeScreen`**: Updated content fonts and "Start Practice" button.
- **`SettingsScreen`**: Updated titles and settings items fonts.
- **`NotificationsScreen`**: Updated fonts and unread indicators.
- **`EditProfileScreen`**: Updated fonts and action buttons.
- **`MySimulationsScreen`**: Updated fonts and loading indicators.

#### Simulation & Coaching

- **`SimulationSetupScreen`**:
  - Refactored to remove hardcoded `spaceGrotesk`/`inter` fonts in favor of `Outfit`/`Manrope`.
  - Replaced hardcoded `_primaryDark` usages with `AppColors.textPrimary` and `AppColors.energyAccent` where appropriate.
  - Updated `_bgPeach` usage to `AppColors.primaryBackground`.
- **`ScenarioCardsScreen`**:
  - Updated "Guided Simulations" header and card fonts to `Outfit`/`Manrope`.
- **`GuidedSimulationScreen`**: Updated fonts and button colors.
- **`CoachScreen`**: Updated AppBar and Chat UI fonts and colors.

#### Personalization

- **`PersonalizationFlow`**: Updated step headers and selection options to match the new theme.

### 3. Clean-up

- Removed unused imports (e.g., `supabase_flutter` in `MySimulationsScreen`, `supabase_service` in `AvatarSelectionSheet`).
- Fixed compilation errors in `SimulationSetupScreen` related to invalid field definitions.

## Verification Checklist

- [x] All Headlines use `Outfit`.
- [x] All Body text uses `Manrope`.
- [x] Primary Actions use `AppColors.energyAccent` (Indigo).
- [x] Surfaces use `AppColors.primaryBackground` (Peach/Warm) where appropriate.
- [x] No lingering usages of `spaceGrotesk` or `inter` in updated files.
- [x] Compilation errors resolved.

## Next Steps

- Run the application to visually verify the changes.
- Check specific UI elements like the "Reactive Avatar" integration in `GuidedSimulationScreen` (partially addressed).
- Ensure consistent padding and spacing with the new fonts (as font metrics may differ).
