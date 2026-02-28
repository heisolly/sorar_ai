import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/rizz_engine_models.dart';
import 'ai_service.dart';

class RizzEngineService {
  final AiService _aiService = AiService();
  final _uuid = const Uuid();

  // Current active scenario state
  RizzScenario? _currentScenario;

  RizzScenario? get currentScenario => _currentScenario;

  /// SECTION 3: SCENARIO ASSEMBLY ALGORITHM
  /// 1. Pulls seeds based on rules.
  /// 2. Returns a configuration object.
  RizzScenarioConfig createScenarioConfig({
    String skillLevel = 'Beginner',
    String contextPreference = 'Public', // 'Public', 'Semi-private', 'Risky'
    String? customContext,
  }) {
    final random = Random();

    String environment;
    String trigger;

    if (customContext != null && customContext.trim().isNotEmpty) {
      environment = customContext;
      trigger = "User defined situation";
    } else {
      // 4.1 ENVIRONMENT SEEDS
      List<String> validEnvironments = RizzScenarioSeeds.environments;

      if (contextPreference == 'Public') {
        validEnvironments = RizzScenarioSeeds.environments
            .where(
              (e) =>
                  e.contains('Coffee') ||
                  e.contains('Gym') ||
                  e.contains('Campus') ||
                  e.contains('Street') ||
                  (e.contains('Elevator') && e.contains('short ride')),
            )
            .toList();
      } else if (contextPreference == 'Semi-private') {
        validEnvironments = RizzScenarioSeeds.environments
            .where(
              (e) =>
                  e.contains('Bar') ||
                  e.contains('Party') ||
                  e.contains('kitchen'),
            )
            .toList();
      } else if (contextPreference == 'Risky') {
        validEnvironments = RizzScenarioSeeds.environments
            .where(
              (e) =>
                  e.contains('balcony') ||
                  e.contains('standing nearby') ||
                  (e.contains('Elevator') && e.contains('long pause')) ||
                  e.contains('workspace'),
            )
            .toList();
      }

      // Fallback if filtering fails
      if (validEnvironments.isEmpty) {
        validEnvironments = RizzScenarioSeeds.environments;
      }

      environment = validEnvironments[random.nextInt(validEnvironments.length)];

      // 4.2 TRIGGER EVENT SEEDS
      trigger = RizzScenarioSeeds
          .triggers[random.nextInt(RizzScenarioSeeds.triggers.length)];
    }

    // 4.3 SOCIAL CONSTRAINT SEEDS
    final constraint = RizzScenarioSeeds
        .constraints[random.nextInt(RizzScenarioSeeds.constraints.length)];

    // 4.4 UNCERTAINTY FACTORS
    final uncertainty = RizzScenarioSeeds
        .uncertainties[random.nextInt(RizzScenarioSeeds.uncertainties.length)];

    // 4.5 STAKES LEVELS
    // Map skill level to stakes? Or just random?
    // Spec says: "Stakes Level" is part of Scenario.
    // Let's bias stakes based on skill level.
    String stakesKeys = 'Easy';
    if (skillLevel == 'Intermediate') {
      stakesKeys = random.nextBool() ? 'Medium' : 'Easy';
    } else if (skillLevel == 'Advanced') {
      stakesKeys = 'Hard'; // Or mix of Medium/Hard
      if (random.nextBool()) stakesKeys = 'Medium';
    }

    // We just store the level name for now as the 'seed'
    final stakesLevel = stakesKeys;

    return RizzScenarioConfig(
      environment: environment,
      trigger: trigger,
      constraint: constraint,
      uncertainty: uncertainty,
      stakesLevel: stakesLevel,
      skillLevel: skillLevel,
    );
  }

  /// Initialize a new scenario session
  Future<RizzScenario?> startScenario({
    required RizzScenarioConfig config,
  }) async {
    final id = _uuid.v4();
    final scenario = RizzScenario(id: id, config: config, beats: []);
    _currentScenario = scenario;

    // Generate Beat 1
    // Beat 1 is "Opening Window".
    // We use the 7.1 SCENARIO GENERATION PROMPT style but tailored for the first beat
    // Actually, 7.1 generates the *Scenario*. But we did that with seeds.
    // The AI task is to "Generate one realistic rizz scenario... each beat must contain exactly one question".
    // But we are doing dynamic beat generation (7.2).

    // So for Beat 1, we provide the seeds and ask for the "Opening Window" question.

    try {
      final beat = await _generateBeat(
        beatNumber: 1,
        prevOutcome: "Scenario Start",
        config: config,
      );
      if (beat != null) {
        scenario.beats.add(beat);
        return scenario;
      }
    } catch (e) {
      debugPrint("Error starting scenario: $e");
    }
    return null;
  }

  /// Generate the next beat based on user input
  Future<RizzScenario?> submitUserResponse(String userAction) async {
    if (_currentScenario == null || _currentScenario!.isCompleted) return null;

    final currentBeatIndex = _currentScenario!.beats.length - 1;
    final int nextBeatNum =
        currentBeatIndex + 2; // Lists are 0-indexed, so length + 1 is next beat

    // Update current beat with user action (not strictly stored in beat model unless we modify it,
    // but useful for history)
    // We should probably store user action in a parallel list or update the model.
    // I'll update RizzBeat model to include 'userAction' in the previous step (done).

    // We can't update the *immutable* beat easily, but we can reconstruct or simple add to a history log.
    // For now, let's assume valid flow.

    try {
      // Generate Next Beat (7.2 BEAT QUESTION PROMPT)
      final beat = await _generateBeat(
        beatNumber: nextBeatNum,
        prevOutcome: userAction,
        config: _currentScenario!.config,
      );

      if (beat != null) {
        if (beat.isLastBeat) {
          _currentScenario!.isCompleted = true;
        }
        _currentScenario!.beats.add(beat);
      } else {
        // End of scenario or error?
        _currentScenario!.isCompleted = true;
      }

      return _currentScenario;
    } catch (e) {
      debugPrint("Error submitting response: $e");
      return _currentScenario;
    }
  }

  /// Core AI Call for Beat Generation
  Future<RizzBeat?> _generateBeat({
    required int beatNumber,
    required String prevOutcome,
    required RizzScenarioConfig config,
  }) async {
    // SECTION 7.2 BEAT QUESTION PROMPT
    // Plus "SECTION 6: QUESTION GENERATION RULES"

    final systemPrompt = '''
You generate one beat in a social interaction.
You do not resolve uncertainty.
You do not suggest outcomes.

FORBIDDEN PHRASES:
- What should you say?
- How do you flirt?
- Impress
- Attractive
- Pickup
- Confidence

REQUIRED STRUCTURE:
- Reference last observable action (from previous outcome)
- Imply time pressure
- No advice language

QUESTION TEMPLATE:
[Observable event].
[Immediate context].
What do you do now?

If the user's last action successfully resolves the scenario (e.g. gets contact info, sets date) OR fails significantly (rejection, weird vibe), set "is_last_beat": true in the JSON and provide a closing remark as the question.
''';

    final userPrompt =
        '''
INPUT:
Previous beat outcome / User Action: "$prevOutcome"
Environment: "${config.environment}"
Constraint: "${config.constraint}"
Trigger: "${config.trigger}"
Uncertainty Factor: "${config.uncertainty}"
Stakes: "${config.stakesLevel}"
Current Beat: $beatNumber

TASK:
Generate Beat $beatNumber.
Return JSON:
{
  "question": "The narrative + question text (or closing remark if last beat)",
  "is_last_beat": boolean,
  "feedback_on_prev": {
      "tone": "Warm/Neutral/Cold",
      "risk": "Low/Med/High",
      "effect": "Short analysis of user's last move (if any)"
  }
}
''';

    try {
      final response = await _aiService.makeRequest(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        jsonMode: true,
      );

      if (response == null) return null;

      final jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final data = jsonDecode(jsonString);

      return RizzBeat(
        beatNumber: beatNumber,
        question: data['question'] ?? "Error generating question.",
        isLastBeat: data['is_last_beat'] ?? false,
        placeholder: "Type your action...",
        feedbackTone: data['feedback_on_prev']?['tone'],
        feedbackRisk: data['feedback_on_prev']?['risk'],
        feedbackAnalysis: data['feedback_on_prev']?['effect'],
      );
    } catch (e) {
      debugPrint("Beat Gen Error: $e");
      return null;
    }
  }

  /// 7.3 AI SUGGESTIONS PROMPT
  Future<List<Map<String, String>>> getSuggestions(String context) async {
    final systemPrompt = '''
You provide optional response styles.
You do not say which is best.
You label by tone only.
''';
    final taskPrompt =
        '''
Context: "$context"

TASK:
Generate 3 responses:
- Warm & curious
- Calm & direct
- Observational & light

Return JSON: { "suggestions": [ {"label": "...", "text": "..."} ] }
''';

    try {
      final response = await _aiService.makeRequest(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': taskPrompt},
        ],
        jsonMode: true,
      );

      if (response == null) return [];

      final jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final data = jsonDecode(jsonString);
      if (data['suggestions'] != null) {
        return (data['suggestions'] as List)
            .map((e) => Map<String, String>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint("Suggestion Error: $e");
    }
    return [];
  }

  /// 7.4 AI ENHANCE PROMPT
  Future<String> enhanceResponse(String userResponse) async {
    final systemPrompt = '''
You enhance the user's reply.
You preserve intent and tone.
You do not add dominance or humor unless present.
''';

    final taskPrompt =
        '''
INPUT:
User response: "$userResponse"

TASK:
Rewrite the response to be clearer, smoother, and more natural.
Return JSON: { "enhanced": "..." }
''';

    try {
      final response = await _aiService.makeRequest(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': taskPrompt},
        ],
        jsonMode: true,
      );

      if (response != null) {
        final jsonString = response
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final data = jsonDecode(jsonString);
        return data['enhanced'] ?? userResponse;
      }
    } catch (e) {
      debugPrint("Enhance Error: $e");
    }
    return userResponse;
  }
}
