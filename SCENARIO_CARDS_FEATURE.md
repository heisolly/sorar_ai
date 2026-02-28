# Scenario-Based Question Cards Feature

## Overview

The Scenario-Based Question Cards feature provides users with realistic social situations and multiple-choice responses. Users can practice their social skills, receive AI-powered feedback, and learn about tone and aura in different contexts.

## Features

### 1. **Category-Based Scenarios**

- **Awkward Moments** 😬 - Handle embarrassing situations with grace
- **Rizz & Dating** 😏 - Master the art of flirting and dating
- **Family** 👨‍👩‍👧‍👦 - Navigate family dynamics
- **Work** 💼 - Professional communication scenarios
- **Strangers** 👥 - Interact confidently with new people

### 2. **Interactive Question Cards**

Each scenario card includes:

- A realistic situation description
- 4 multiple-choice response options
- Difficulty level (Easy, Medium, Hard, Expert)
- Beautiful gradient design with category-specific colors

### 3. **AI-Powered Feedback System**

When a user selects a response, they receive:

- **Score** (0-100) indicating response quality
- **Detailed Feedback** explaining why the choice was good/bad
- **Tone Analysis** (e.g., confident, passive, aggressive)
- **Aura Assessment** (e.g., professional, friendly, awkward)
- **Pro Tips** - 3-4 actionable insights to improve

### 4. **Custom Scenario Input**

Users can create their own scenarios by:

1. Tapping the "+" button in the header
2. Describing their situation
3. Getting AI-generated response options and feedback

## File Structure

```
lib/
├── models/
│   └── scenario_card.dart          # Data models for scenarios
├── services/
│   └── scenario_service.dart       # Scenario generation logic
└── screens/
    └── cards/
        ├── scenario_cards_screen.dart        # Main grid view
        └── scenario_card_detail_screen.dart  # Detail view with feedback
```

## Navigation

The Scenario Cards feature is accessible from the **bottom navigation bar** (4th icon - style_rounded).

## User Flow

1. **Browse Scenarios**
   - User lands on the Scenario Cards screen
   - Sees category filters at the top
   - Views a grid of scenario cards

2. **Select Category**
   - Tap on a category filter (Awkward Moments, Rizz, Family, etc.)
   - Grid updates to show scenarios from that category

3. **Practice Scenario**
   - Tap on a scenario card
   - Read the situation
   - Select one of 4 response options

4. **Receive Feedback**
   - See score (0-100) with color-coded indicator
   - Read detailed feedback
   - View tone and aura analysis
   - Learn from pro tips

5. **Try Again or Move On**
   - "Try Again" - Reset and select a different response
   - "Try Another" - Return to scenario grid

## Custom Scenarios

Users can create custom scenarios:

1. Tap the "+" button (top right)
2. Enter their situation in the text field
3. Tap "Generate"
4. Receive AI-generated response options

## Design Highlights

### Color System

- **Awkward Moments**: Red (#F43F5E)
- **Rizz & Dating**: Pink (#EC4899)
- **Family**: Purple (#8B5CF6)
- **Work**: Blue (#3B82F6)
- **Strangers**: Green (#10B981)
- **Custom**: Orange (#F59E0B)

### Animations

- Fade-in effects on screen load
- Scale animations on card tap
- Slide animations for feedback sections
- Staggered list animations

### Score Colors

- **80-100**: Green (#10B981) - Excellent
- **60-79**: Orange (#F59E0B) - Good
- **0-59**: Red (#F43F5E) - Needs Improvement

## Future Enhancements

1. **AI Integration**
   - Connect to OpenAI/Gemini for dynamic scenario generation
   - Personalized scenarios based on user profile
   - Real-time response analysis

2. **Progress Tracking**
   - Save user responses to Supabase
   - Track improvement over time
   - Show statistics (average score, categories practiced, etc.)

3. **Multiplayer Mode**
   - Compare responses with friends
   - Leaderboards for each category
   - Challenge friends to scenarios

4. **Voice Response**
   - Record audio responses
   - Analyze tone, pitch, and delivery
   - Provide speech coaching

5. **Scenario Library**
   - User-submitted scenarios
   - Community voting on best responses
   - Trending scenarios

## Technical Notes

### Models

- `ScenarioCard`: Main scenario data structure
- `ResponseOption`: Individual response with score and feedback
- `ToneAnalysis`: Tone, aura, and tips data

### Service

- `ScenarioService`: Generates scenarios and responses
- Currently uses predefined templates
- Ready for AI integration (just replace `_generateResponseOptions` method)

### State Management

- Uses StatefulWidget for local state
- No complex state management needed yet
- Can integrate Riverpod/Provider if needed for global state

## Integration with Supabase

To save user progress (future enhancement):

```dart
// Save scenario attempt
await supabase.from('scenario_attempts').insert({
  'user_id': userId,
  'scenario_id': scenarioCard.id,
  'selected_option_id': selectedOption.id,
  'score': selectedOption.score,
  'category': scenarioCard.category,
  'created_at': DateTime.now().toIso8601String(),
});

// Update user stats
await supabase.rpc('increment_scenario_count', {
  'user_id': userId,
  'category': scenarioCard.category,
});
```

## Usage Example

```dart
// Generate a scenario
final scenarioService = ScenarioService();
final card = scenarioService.generateScenarioCard('awkward_moments');

// Navigate to detail screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ScenarioCardDetailScreen(
      scenarioCard: card,
    ),
  ),
);
```

## Accessibility

- High contrast colors for readability
- Large touch targets (minimum 44x44)
- Semantic labels for screen readers
- Clear visual feedback on interactions

## Performance

- Lazy loading of scenarios
- Efficient grid rendering
- Minimal rebuilds with proper state management
- Smooth animations (60fps)

---

**Created**: 2026-02-04  
**Version**: 1.0.0  
**Status**: ✅ Ready for Testing
