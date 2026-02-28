# Navigation Fix - Back to Dashboard

## Issue

Users couldn't access the navigation bar when in the simulation setup or coach screens because the back button only used `Navigator.pop()`.

## Solution

Updated both screens to navigate directly to the `DashboardScreen` when the back button is pressed, ensuring users can access the bottom navigation bar.

## Changes Made

### 1. SimulationSetupScreen

**File**: `lib/screens/simulation_setup_screen.dart`

**Changes**:

- Added import: `import 'dashboard_screen.dart';`
- Updated back button `onPressed`:

```dart
onPressed: () {
  // Navigate to dashboard to access nav bar
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const DashboardScreen()),
    (route) => false,
  );
}
```

### 2. CoachScreen

**File**: `lib/screens/coach_screen.dart`

**Changes**:

- Added import: `import 'dashboard_screen.dart';`
- Updated back button `onTap`:

```dart
onTap: () {
  // Navigate to dashboard to access nav bar
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const DashboardScreen()),
    (route) => false,
  );
}
```

## Navigation Behavior

### Before:

- Back button → Goes to previous screen (might not have nav bar)
- User could get "stuck" without access to navigation

### After:

- Back button → Always goes to Dashboard
- Dashboard has bottom navigation bar
- User can navigate to any section: Home, Chat, Cards, Progress, New Simulation

## Technical Details

**Navigation Method**: `Navigator.pushAndRemoveUntil()`

- Clears the entire navigation stack
- Pushes DashboardScreen as the new root
- Prevents back button from going to previous screens
- Ensures clean navigation state

**Benefits**:

1. ✅ Users always have access to navigation bar
2. ✅ Prevents navigation stack buildup
3. ✅ Clear, predictable navigation flow
4. ✅ Matches user expectations (back = home)

## User Flow

```
Simulation Setup Screen
    ↓ (tap back)
Dashboard (with nav bar)
    ↓ (can navigate to)
    - Home
    - AI Chat
    - Scenario Cards
    - Progress
    - New Simulation
```

```
Coach Screen (active chat)
    ↓ (tap back)
Dashboard (with nav bar)
    ↓ (can navigate to)
    - Home
    - AI Chat
    - Scenario Cards
    - Progress
    - New Simulation
```

## Testing Checklist

- [x] Back button appears in SimulationSetupScreen
- [x] Back button appears in CoachScreen
- [x] Tapping back goes to Dashboard
- [x] Dashboard shows navigation bar
- [x] All nav bar items are accessible
- [x] No navigation stack issues

---

**Status**: Navigation fixed ✅
**Impact**: Improved UX - users can always access main navigation
