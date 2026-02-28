# Sorar AI - Complete App Description

## 📱 App Name

**Sorar AI** - Your AI-Powered Social Skills Coach

---

## 🎯 Core Purpose & Use Case

Sorar AI is a **premium social skills training application** that helps users master difficult conversations through AI-powered roleplay simulations. It's designed for people who want to improve their communication skills in real-world scenarios like dating, family conflicts, business negotiations, and more.

### Target Audience

- Young professionals looking to improve workplace communication
- People wanting to enhance their dating/flirting skills ("Rizz")
- Anyone struggling with conflict resolution
- Individuals preparing for difficult conversations (breakups, negotiations, confrontations)

### Key Value Proposition

Unlike traditional coaching apps, Sorar AI provides **realistic, judgment-free practice** through AI simulations that adapt to your responses, offering both immersive roleplay and intelligent coaching suggestions.

---

## 🎨 Design Identity

### Color Palette

#### Primary Colors

- **Primary Background**: `#FAE4D7` - Warm Peach (Main app background)
- **Surface**: `#FFFBF9` - Warm White (Cards, containers)
- **Secondary Surface**: `#F7EBE6` - Muted Warm (Subtle backgrounds)

#### Text Colors

- **Primary Text**: `#3E2C24` - Deep Warm Brown
- **Secondary Text**: `#6D5449` - Medium Brown
- **Muted Text**: `#9E8A82` - Light Brown
- **Disabled Text**: `#C9B8B0` - Very Light Brown

#### Accent Colors

- **Energy Accent**: `#6366F1` - Muted Indigo (Primary CTA, buttons)
- **Growth Green**: `#2DD4BF` - Muted Teal (Progress, achievements)
- **Secondary Accent**: `#D67D60` - Soft Terracotta (Highlights)
- **Primary CTA**: `#4A342E` - Rich Cocoa (Dark accents)

#### Scenario-Specific Colors

- **Rizz (Dating)**: `#FF8A80` - Soft Red
- **Family**: `#FFD54F` - Amber
- **Business**: `#4DD0E1` - Cyan
- **Conflict**: `#9575CD` - Deep Purple
- **Negotiation**: `#81C784` - Green

### Typography

- **Headlines**: **Outfit** (Google Fonts) - Bold, modern, attention-grabbing
- **Body Text**: **Manrope** (Google Fonts) - Clean, readable, professional
- **Buttons**: **Manrope Medium** - Clear, actionable

### Design Aesthetic

- **Warm & Calm**: Peach and brown tones create a comfortable, non-threatening environment
- **Premium & Mature**: Sophisticated color choices and typography convey professionalism
- **Subtle Texture**: Hand-drawn SVG elements and noise backgrounds add depth without distraction
- **Motion Design**: Smooth fade-ins, pressable scale effects, and ambient breathing animations enhance the premium feel

---

## 🚀 Core Features & Functions

### 1. **AI Roleplay Simulations** 🎭

The heart of the app - realistic conversation practice with AI.

#### Three AI Modes:

1. **Practice Mode** (AI plays THEM)
   - You are yourself
   - AI plays the other person (date, boss, friend, etc.)
   - Most common mode for skill building

2. **Assistant Mode** (AI plays ME)
   - AI plays YOU
   - You play the other person
   - Helps you see conversations from different perspectives

3. **Hybrid Mode** (Flexible)
   - Switch between playing yourself and letting AI take over
   - "AI Take Over" button generates suggested responses
   - Best for learning by example

#### Simulation Categories:

- **Rizz** 💕: Dating, flirting, romantic conversations
- **Family** 👨‍👩‍👧: Parent conversations, sibling conflicts, family dynamics
- **Business** 💼: Job interviews, salary negotiations, client meetings
- **Conflict** ⚔️: Confrontations, breakups, difficult conversations
- **Negotiation** 🤝: Bargaining, persuasion, deal-making

#### Conversation Features:

- **Natural AI Responses**: AI adapts tone, emoji usage, and personality to scenario
- **Voice Input**: Speak your responses using speech-to-text
- **Emoji Picker**: Express emotions naturally
- **WhatsApp-Style UI**: Familiar chat interface for comfort
- **AI Suggestions**: Tap ✨ for 3 coaching suggestions (Playful, Curious, Simple)
- **Realistic Reactions**: AI doesn't always agree - it challenges you like a real person

### 2. **Personalized Dashboard** 📊

Track your progress and get daily insights.

#### Key Metrics:

- **Social Power Level**: Gamified confidence tracking (Level 1-10)
- **Day Streak**: Consecutive days of practice
- **Daily Insights**: Personalized tips based on your profile and goals
- **Recommended Practice**: AI suggests scenarios based on your challenges

#### Dashboard Features:

- Time-based greetings (Good Morning/Afternoon/Evening)
- Interactive Empathy Avatar with eye-tracking
- Quick-start recommended simulations
- Progress visualization with charts

### 3. **Empathy Avatar** 👁️

A unique, reactive AI companion that appears throughout the app.

#### Behaviors:

- **Eye Tracking**: Follows your mouse/cursor position
- **Curious Animation**: Activates when you're typing
- **Emotional States**: Reflects conversation mood
- **Ambient Breathing**: Subtle pulsing animation for lifelike presence

### 4. **Progress Tracking** 📈

Comprehensive analytics to measure improvement.

#### Metrics Tracked:

- Sessions completed
- Confidence levels per scenario type
- Conversation quality scores
- Streak maintenance
- Goal achievement

#### Visualizations:

- Line charts for progress over time
- Confidence level breakdowns
- Category-specific performance

### 5. **Session History** 🕒

Review and learn from past conversations.

#### Features:

- Browse all previous simulations
- Filter by scenario type
- Resume incomplete sessions
- Delete unwanted conversations
- View timestamps and metadata

### 6. **Onboarding & Personalization** 🎯

Tailored experience from day one.

#### Onboarding Flow:

1. Welcome screen with brand introduction
2. Goal selection (What do you want to improve?)
3. Challenge identification (What holds you back?)
4. Communication style assessment
5. Confidence level baseline

#### Personalization:

- Custom recommendations based on profile
- Adaptive AI responses matching your style
- Goal-focused daily insights

### 7. **Coaching Insights** 💡

Real-time and post-session feedback.

#### During Conversation:

- Tap ✨ for 3 AI-suggested responses
- Color-coded labels (Playful/Curious/Simple)
- Edit suggestions before sending

#### Post-Session:

- Session summary with key moments
- Improvement suggestions
- Confidence score breakdown

---

## 🛠️ Technical Architecture

### Platform

- **Framework**: Flutter (Cross-platform: iOS, Android, Windows, macOS, Linux)
- **Language**: Dart
- **SDK Version**: ^3.10.8

### Backend & Services

- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth + Google Sign-In
- **AI Service**: Custom AI integration (OpenAI/Gemini compatible)
- **Real-time**: Supabase Realtime for live updates

### Key Dependencies

- `supabase_flutter` - Backend integration
- `google_fonts` - Typography (Outfit, Manrope)
- `flutter_chat_ui` - Chat interface components
- `speech_to_text` - Voice input
- `flutter_tts` - Text-to-speech (future feature)
- `lottie` - Animations for Empathy Avatar
- `fl_chart` - Progress charts
- `provider` - State management
- `flutter_animate` - Motion design
- `shared_preferences` - Local storage

### Database Schema

#### Tables:

1. **users** - User profiles and preferences
2. **chat_sessions** - Simulation sessions
3. **chat_messages** - Individual messages
4. **progress_metrics** - User progress tracking
5. **scenarios** - Pre-built scenario templates

---

## 🎬 User Journey

### First-Time User

1. **Splash Screen** → Brand introduction
2. **Authentication** → Google Sign-In or email
3. **Onboarding** → 5-step personalization
4. **Dashboard** → Personalized welcome with recommended practice
5. **First Simulation** → Guided setup with examples
6. **Practice** → Realistic AI conversation
7. **Summary** → Feedback and progress update

### Returning User

1. **Dashboard** → See streak, progress, daily insight
2. **Quick Start** → Tap recommended simulation
3. **Practice** → Continue improving
4. **Review History** → Learn from past sessions

---

## 🌟 Unique Selling Points

1. **Realistic AI Behavior**: Unlike chatbots, Sorar AI doesn't always agree - it challenges you
2. **No Judgment Zone**: Practice difficult conversations without fear
3. **Adaptive Learning**: AI adjusts to your skill level and goals
4. **Premium Design**: Warm, calming aesthetic reduces anxiety
5. **Gamification**: Levels, streaks, and achievements keep you motivated
6. **Multi-Modal Input**: Type, speak, or use suggestions
7. **Scenario Variety**: From dating to business - all in one app

---

## 🎯 Future Roadmap

### Planned Features

- Voice-to-voice conversations (AI speaks back)
- Video avatar for more immersive practice
- Multiplayer mode (practice with friends)
- Custom scenario builder
- Export conversation transcripts
- Integration with calendar for practice reminders
- Community leaderboards
- Premium subscription with advanced AI models

---

## 📊 Success Metrics

### User Engagement

- Daily active users
- Average session length
- Streak retention rate
- Scenarios completed per user

### Learning Outcomes

- Confidence level improvements
- User-reported real-world success stories
- Session quality scores over time

---

## 🎨 Brand Voice & Messaging

### Tone

- **Supportive**: "We're here to help you grow"
- **Non-judgmental**: "Practice without pressure"
- **Empowering**: "Master any conversation"
- **Playful**: "Level up your social game"

### Taglines

- "Your AI-Powered Social Skills Coach"
- "Practice Difficult Conversations, Risk-Free"
- "Master Any Conversation with AI"
- "Build Confidence Through Realistic Practice"

---

## 📱 Platform-Specific Features

### Mobile (iOS/Android)

- Push notifications for streak reminders
- Haptic feedback for interactions
- Swipe gestures for navigation
- Native share functionality

### Desktop (Windows/macOS/Linux)

- Keyboard shortcuts
- Multi-window support
- Larger screen optimizations
- Mouse hover effects (e.g., avatar eye tracking)

---

## 🔐 Privacy & Security

- End-to-end encryption for conversations
- No conversation data shared with third parties
- Optional anonymous mode
- GDPR compliant
- User data deletion on request

---

## 💎 Premium Features (Future)

### Free Tier

- 5 simulations per day
- Basic AI responses
- Standard scenarios
- Progress tracking

### Premium Tier

- Unlimited simulations
- Advanced AI (GPT-4, Gemini Pro)
- Custom scenario builder
- Voice-to-voice mode
- Priority support
- Detailed analytics
- Export transcripts

---

## 🎓 Educational Philosophy

Sorar AI is built on the principle that **social skills are learnable through practice**. By providing:

- **Safe Environment**: No real-world consequences
- **Immediate Feedback**: Learn what works in real-time
- **Repetition**: Practice until it feels natural
- **Variety**: Exposure to different scenarios and personalities
- **Reflection**: Review and learn from past conversations

Users can build genuine confidence that translates to real-world success.

---

**Status**: Active Development  
**Version**: 0.1.0  
**Last Updated**: February 2026
