# Empathy Avatar States - Design Reference

## Overview

The Empathy Avatar dynamically changes its appearance based on a value from 0-100, representing user performance/feedback in the Roast Me game.

## Avatar States

### 1. **Negative State** (0-20%)

- **Background**: Soft Coral/Red (#FFDA4AF)
- **Face Expression**:
  - Eyes: Tilted sharply downward toward center (angry/upset brow effect)
  - Mouth: Deep downward curve (inverted U / frown)
- **Emotion**: Upset, disappointed, or negative reaction
- **Triggered when**: User gets low scores (poor pickup line performance)

### 2. **Neutral/Concerned State** (40-60%)

- **Background**: Soft Amber/Yellow (#FDE047)
- **Face Expression**:
  - Eyes: Tilted slightly inward (top corners closer together - concerned look)
  - Mouth: Flat horizontal line or slight frown
- **Emotion**: Neutral, uncertain, or mildly concerned
- **Triggered when**: User gets average scores

### 3. **Positive State** (80-100%)

- **Background**: Lime Green (#C6F432)
- **Face Expression**:
  - Eyes: Level, horizontally aligned (relaxed)
  - Mouth: Deep upward curve (U-shape smile)
- **Emotion**: Happy, impressed, positive reaction
- **Triggered when**: User gets high scores (great pickup line)

### 4. **Transition States**

- **20-40%**: Smooth color transition from Red → Yellow, eyes transition from angry tilt → concerned tilt
- **60-80%**: Smooth color transition from Yellow → Green, eyes transition from concerned → level, mouth from flat → smile

## Implementation in Roast Me Game

### Score Mapping

The game receives AI scores for:

- **Charm** (1-5)
- **Originality/Wit** (1-5)
- **Confidence/Bold** (1-5)

These are averaged and mapped to the avatar mood:

```dart
// Average score: 1-5
// Avatar mood: 0-100
_avatarMood = ((avgScore - 1) / 4 * 100).clamp(0.0, 100.0)
```

**Examples**:

- Score of 1 (lowest) → Mood = 0% (Red, angry)
- Score of 3 (average) → Mood = 50% (Yellow, neutral)
- Score of 5 (excellent) → Mood = 100% (Green, happy)

## Interactive Features

1. **Blinking**: The avatar blinks randomly every 2-6 seconds to feel alive
2. **Elasticity**: When the slider is released (game score updates), the avatar performs a "bounce" animation (squash & stretch)
3. **Contextual Scaling**: When the text input is focused, the avatar scales down to 120px to avoid crowding
4. **Smooth Morphing**: All transitions (color, eye rotation, mouth curve) use smooth animations

## Usage Location

- **Roast Me Screen** (`lib/screens/cards/roast_me_screen.dart`): Main implementation - avatar reacts to pickup line quality
- **Avatar Coach Screen** (`lib/screens/coach/avatar_coach_screen.dart`): For testing/demo purposes (will be removed)

## Design Principles

- Minimalist flat design
- High contrast (dark ink features on vibrant backgrounds)
- Expressive through simple geometric shapes
- Real-time emotional feedback
- Playful and engaging
