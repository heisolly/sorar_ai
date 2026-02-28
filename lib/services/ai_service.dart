import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/scenario_card.dart';
import '../models/simulation_scenario.dart';

class AiService {
  // Key now loaded from .env
  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // Using a model supported by OpenRouter
  static const String _model = 'gpt-4o-mini';

  static final AiService _instance = AiService._internal();

  factory AiService() {
    return _instance;
  }

  AiService._internal() {
    debugPrint('AiService initialized with OpenRouter (Model: $_model)');
  }

  Future<String?> _postRequest({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    bool jsonMode = false,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      final body = {
        'model': _model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': 1000, // Limit tokens to avoid quota errors
        if (jsonMode) 'response_format': {'type': 'json_object'},
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['choices'] != null &&
            data['choices'].isNotEmpty &&
            data['choices'][0]['message'] != null) {
          return data['choices'][0]['message']['content'];
        }
      }

      debugPrint('AI Service Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('AI Service Exception: $e');
      return null;
    }
  }

  /// Generic method to make requests from other services
  Future<String?> makeRequest({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    bool jsonMode = false,
  }) {
    return _postRequest(
      messages: messages,
      temperature: temperature,
      jsonMode: jsonMode,
    );
  }

  /// Feature 1: Generates "Scenario Cards" for interactive training.
  Future<List<ScenarioCard>> generateScenarioCards({
    required String category,
    int count = 3,
    String? customScenario,
  }) async {
    try {
      final prompt =
          '''
      Generate $count realistic social scenarios for the category: "$category".
      ${customScenario != null ? 'Focus on this specific situation: "$customScenario"' : ''}
      
      For each scenario, provide a detailed JSON object matching this structure:
      {
        "id": "unique_string",
        "category": "$category",
        "situation": "Description of the situation",
        "difficulty": "Easy/Medium/Hard",
        "options": [
          {
            "id": "opt_1",
            "text": "The response text",
            "score": 85 (0-100),
            "feedback": "Why this is good/bad",
            "tone_analysis": {
              "tone": "confident/passive/etc",
              "aura": "charismatic/awkward/etc",
              "tips": ["tip1", "tip2"]
            }
          }
        ]
      }

      Return ONLY a JSON array of these objects under a key "cards" if possible, or just the array.
      IMPORTANT: Return valid JSON.
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true, // Try to force JSON
      );

      if (response == null) return [];

      String jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Sometimes models return { "cards": [...] } or just [...]
      // We need to handle both if we used json_object mode which forces an object usually.

      List<dynamic> jsonList = [];
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map && decoded.containsKey('cards')) {
          jsonList = decoded['cards'];
        } else if (decoded is Map && decoded.containsKey('scenarios')) {
          jsonList = decoded['scenarios']; // fallback
        }
      } catch (e) {
        debugPrint("JSON Parse Error: $e");
      }

      return jsonList.map((map) => ScenarioCard.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error generating cards: $e');
      return [];
    }
  }

  /// Feature: AI Coach Chat
  /// Feature: AI Coach Chat
  Future<String> getCoachReply({
    required String message,
    required List<Map<String, String>> history,
    String? simulationType,
    String? userContext,
    String?
    roleMode, // 'assistant' (AI plays Me), 'practice' (AI plays Them), 'hybrid'
  }) async {
    try {
      // PROMPT ADJUSTMENT BASED ON ROLE MODE

      String roleDescription = "";
      if (roleMode == 'assistant') {
        // AI is playing the USER (Me). Human is playing "Them".
        roleDescription = '''
YOU ARE ROLEPLAYING AS THE USER (Me) in this scenario.
The INPUT message you receive is from THE OTHER PERSON (Them).
Your goal is to respond as I (the user) should respond.
''';
      } else {
        // AI is playing the CHARACTER (Them). Human is playing "Me".
        roleDescription = '''
YOU ARE ROLEPLAYING AS THE CHARACTER (Them) in this scenario.
The INPUT message you receive is from THE USER (Me).
Your goal is to respond as the character would.
''';
      }

      // STRICT ROLEPLAY PROMPT - NATURAL & HUMAN
      final systemPrompt =
          '''
      $roleDescription
      
      CONTEXT:
      Simulation Type: ${simulationType ?? 'General Interaction'}
      Scenario: ${userContext ?? 'Not specified'}

      CRITICAL RULES:
      1. You are NOT a coach, assistant, or AI.
      2. NEVER explain, teach, or give feedback. Only respond as your role.
      3. React REALISTICALLY to the input.
         - If they're awkward → be confused, uninterested, or politely distant
         - If they're smooth → be engaged, curious, or playful
         - If they're boring → give short, dry responses
      
      TONE & STYLE:
      4. Keep messages SHORT (5-15 words typically). Real people don't write essays in texts.
      5. Use lowercase naturally (not forced). Mix in proper capitalization sometimes.
      6. EMOJI USAGE (CRITICAL):
         - Use emojis in only 20-30% of messages
         - NEVER use emojis in the first 2-3 messages
         - Only use 1 emoji max per message
         - Only use emojis when the mood is clearly playful/flirty/excited
         - Mirror the user's emoji usage (if they use none, you use none)
      7. Vary your energy:
         - Sometimes enthusiastic: "oh nice!"
         - Sometimes neutral: "cool"
         - Sometimes dry: "yeah"
      8. Don't be overly eager or helpful. Real people have their own lives.
      
      SPECIFIC PERSONA ADJUSTMENTS:
      ${_getPersonaInstructions(simulationType)}
      
      Remember: You're a PERSON texting, not a chatbot. Be real, be natural, be human.
      ''';

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ...history,
        {'role': 'user', 'content': message},
      ];

      final response = await _postRequest(messages: messages);
      return response ?? "...";
    } catch (e) {
      debugPrint('Coach Chat Error: $e');
      return "...";
    }
  }

  String _getPersonaInstructions(String? simulationType) {
    if (simulationType == null) return '';

    final type = simulationType.toLowerCase();

    if (type.contains('rizz') || type.contains('dating')) {
      return '''
      - You are someone the user is trying to attract/flirt with
      - Start neutral, not immediately flirty
      - Show interest ONLY if they're being smooth
      - Be slightly challenging, not easy
      - Real dates don't fall for every line
      ''';
    } else if (type.contains('conflict')) {
      return '''
      - You are frustrated/annoyed about something
      - Don't immediately calm down - that's unrealistic
      - Respond to their tone and approach
      - If they escalate, you escalate. If they de-escalate well, soften.
      ''';
    } else if (type.contains('negotiation')) {
      return '''
      - You have your own interests and constraints
      - Don't give in easily
      - Respond positively to good reasoning
      - Be skeptical of weak arguments
      ''';
    }

    return '';
  }

  /// Feature: Get smart coaching suggestions (Outside the chat)
  /// Feature: Get smart coaching suggestions (Outside the chat)
  Future<List<Map<String, String>>> getCoachingSuggestions({
    required String lastUserMessage,
    required String lastAiMessage,
    required List<Map<String, String>> history,
    String? simulationType,
    String? userContext,
    String? currentDraft,
  }) async {
    try {
      // Build conversation context
      String conversationContext = '';
      if (history.isNotEmpty) {
        conversationContext = history
            .take(6)
            .map((m) {
              final role = m['role'] == 'user' ? 'User' : 'Partner';
              return '$role: ${m['content']}';
            })
            .join('\n');
      }

      final bool hasDraft =
          currentDraft != null && currentDraft.trim().isNotEmpty;

      String prompt;
      if (hasDraft) {
        prompt =
            '''
You are an elite communication coach.
Simulation: "$simulationType" ${userContext != null ? '- "$userContext"' : ''}

Recent conversation:
$conversationContext

User's CURRENT DRAFT: "$currentDraft"

The user wants to send this, but needs a better version.
Generate 3 enhanced versions of their draft:
1. Polished - Clean, professional, or smooth (fixes grammar/tone).
2. Confident - More assertive, higher status, direct.
3. Empathetic - Softer, more understanding, or playful (depending on context).

IMPORTANT: Return ONLY valid JSON in this exact format:
{
  "suggestions": [
    {"label": "Polished", "text": "enhanced version here"},
    {"label": "Confident", "text": "enhanced version here"},
    {"label": "Empathetic", "text": "enhanced version here"}
  ]
}
''';
      } else {
        prompt =
            '''
You are a world-class communication coach.
Simulation: "$simulationType" ${userContext != null ? '- "$userContext"' : ''}

Recent conversation:
$conversationContext

Partner's last message: "$lastAiMessage"

Generate 3 distinct reply options for the user:
1. Playful - Witty, flirty, high energy
2. Curious - Thoughtful, engaging question  
3. Simple - Safe, neutral, friendly

IMPORTANT: Return ONLY valid JSON in this exact format (must be an object, not an array):
{
  "suggestions": [
    {"label": "Playful", "text": "actual reply here"},
    {"label": "Curious", "text": "actual reply here"},
    {"label": "Simple", "text": "actual reply here"}
  ]
}
''';
      }

      final jsonResponse = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );

      if (jsonResponse == null) {
        debugPrint('Suggestion Error: No response from API');
        return [];
      }

      debugPrint('Suggestion Raw Response: $jsonResponse');

      // Clean up response (remove markdown code blocks if present)
      String cleaned = jsonResponse
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Try to parse JSON
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is Map && decoded.containsKey('suggestions')) {
          final list = decoded['suggestions'] as List;
          return list.map((e) => Map<String, String>.from(e as Map)).toList();
        } else if (decoded is List) {
          // Fallback if it returns array directly
          return decoded
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        }
      } catch (parseError) {
        debugPrint('JSON Parse Error: $parseError');
        debugPrint('Attempted to parse: $cleaned');
      }

      return [];
    } catch (e) {
      debugPrint('Suggestion Error: $e');
      return [];
    }
  }

  /// Feature 2: Generates a simulation scenario to start a chat.
  Future<SimulationScenario?> generateSimulationScenario({
    required String category,
    String? linkedCardId,
  }) async {
    try {
      final prompt =
          '''
      Create a roleplay chat scenario for category: "$category".
      ${linkedCardId != null ? 'Based on the previous training card ID: $linkedCardId' : ''}

      Return a JSON object with:
      - id: unique string
      - title: Short title (e.g., "Argue with Boss")
      - partner_name: Name of the other person (e.g., "Mr. Smith")
      - context: Hidden context for the AI roleplay (e.g., "Mr. Smith is stressed and short-tempered").
      - initial_message: The first message sent by the partner.
      - difficulty: Easy/Medium/Hard.
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );

      if (response == null) return null;

      final jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final map = jsonDecode(jsonString);
      return SimulationScenario.fromMap(map);
    } catch (e) {
      debugPrint('Error generating simulation: $e');
      return null;
    }
  }

  /// Feature 2 (Chat): Generates the partner's reply in the simulation.
  Future<String> getChatReply({
    required String userMessage,
    required List<Map<String, String>> history,
    required String context,
    required String partnerName,
  }) async {
    try {
      final systemPrompt =
          '''
      You are roleplaying as "$partnerName".
      Context: $context.
      Goal: Be realistic. If the user replies poorly, react negatively. If well, react positively.
      Keep replies concise, like a real chat (WhatsApp/Text).
      Do NOT break character.
      ''';

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ...history,
        {'role': 'user', 'content': userMessage},
      ];

      final response = await _postRequest(messages: messages);
      return response ?? "...";
    } catch (e) {
      debugPrint('Simulation Reply Error: $e');
      return "...";
    }
  }

  /// Feature 3: Screen Reading / Real-world Assistance
  Future<Map<String, dynamic>> analyzeRealWorldDraft({
    required String draft,
    required String conversationContext, // Last few messages
  }) async {
    try {
      final prompt =
          '''
      Analyze this draft reply for a real conversation.
      Context: "$conversationContext"
      User Draft: "$draft"

      Return JSON:
      - score: 1-10 (integer)
      - feedback: Brief critique.
      - suggestion: A polished version of the draft.
      - aura_tip: A tip for delivery (tone, timing).
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );

      if (response == null) return {};

      final jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Analysis Error: $e');
      return {};
    }
  }

  /// Feature 4: Analyze User Message (for Coach & Scenario)
  Future<Map<String, dynamic>> analyzeUserMessage({
    required String message,
    required String context,
  }) async {
    try {
      final prompt =
          '''
      Analyze this message sent in this context: "$context".
      Message: "$message"
      
      Return ONLY a JSON object with:
      - score (1-10 integer)
      - tone (1-2 word description)
      - feedback (short 1 sentence tip)
      - better_options (list of 2 short strings)
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );

      if (response == null) return {};

      final jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Analysis Error: $e');
      return {'score': 5, 'feedback': 'Could not analyze.'};
    }
  }

  /// Feature 5: Generate Reply (for Coach & Scenario)
  Future<Map<String, dynamic>> generateReply({
    required String prompt,
    required String context,
    required String persona,
  }) async {
    try {
      final systemInstruction =
          '''
      You are roleplaying as: $persona.
      Context: $context.
      
      Your goal is to be realistic, challenging, and human-like. 
      Do NOT break character. 
      Keep replies concise (WhatsApp style).
      
      User just said: "$prompt"
      
      Reply as the character.
      Return JSON: { "reply": "your text here" }
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': systemInstruction},
        ],
        jsonMode: true,
      );

      if (response == null) return {'reply': '...'};

      final jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return {'reply': response};
      }
    } catch (e) {
      debugPrint('Reply Error: $e');
      return {'reply': '...'};
    }
  }

  /// Feature: General AI Chat
  Future<String> sendGeneralMessage({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final systemPrompt = '''
      You are an elite Communication Coach for the Parot app.
      Your goal: Help the user sound more confident, charismatic, and emotionally intelligent.

      Rules:
      1. Be concise. Do not write essays.
      2. If the user shares a situation, analyze it briefly and give 1 actionable tip.
      3. Tone: Warm, professional, but direct. Like a trainer.
      4. Always end with a short question to keep them practicing.
      ''';

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ...history,
        {'role': 'user', 'content': message},
      ];

      final response = await _postRequest(messages: messages);
      return response ?? "I'm having trouble understanding that properly.";
    } catch (e) {
      debugPrint('General Chat Error: $e');
      return "Sorry, I encountered an error. Please try again.";
    }
  }

  /// Feature: Guided Simulation - Enhance Reply
  Future<String> enhanceSimulationReply({
    required String originalText,
    required String context,
  }) async {
    try {
      final prompt =
          '''
      Refine this user response for the following social scenario context: "$context".
      
      User's draft: "$originalText"
      
      Task: Rewrite it to be more charismatic, confident, or effective, but KEEP the same intent.
      Return ONLY the rewritten text. No quotes.
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
      );

      return response?.trim().replaceAll('"', '') ?? originalText;
    } catch (e) {
      return originalText;
    }
  }

  /// Feature: Guided Simulation - Get Suggestions
  Future<List<Map<String, String>>> getSimulationSuggestions({
    required String context,
  }) async {
    try {
      final prompt =
          '''
      Context: "$context"
      
      Provide 3 different styles of response for this moment.
      1. Playful/Witty
      2. Direct/Confident
      3. Laid back/Neutral
      
      Return JSON:
      {
        "suggestions": [
          {"label": "Playful", "text": "example"},
          {"label": "Direct", "text": "example"},
          {"label": "Chill", "text": "example"}
        ]
      }
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );

      if (response == null) return [];

      String jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Parse JSON safely
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is Map && decoded.containsKey('suggestions')) {
          final list = decoded['suggestions'] as List;
          return list.map((e) => Map<String, String>.from(e as Map)).toList();
        }
      } catch (e) {
        debugPrint('JSON Parse Error for suggestions: $e');
      }
      return [];
    } catch (e) {
      debugPrint('Suggestion Error: $e');
      return [];
    }
  }

  /// Feature: Guided Simulation - Generate Next Beat
  Future<Map<String, dynamic>> generateNextBeat({
    required int currentBeatNumber,
    required int totalBeats,
    required String context,
    required List<Map<String, String>> history, // full convo history
    required String userLastResponse,
  }) async {
    try {
      // Basic formatting of history for prompt
      String historyText = '';
      if (history.isNotEmpty) {
        historyText = history
            .map((m) => "${m['role']}: ${m['content']}")
            .join("\\n");
      }

      final prompt =
          '''
      Acting as the roleplay partner in a "Guided Simulation" (Beat $currentBeatNumber).
      Scenario Context: "$context"
      
      Conversation History:
      $historyText
      
      User just said: "$userLastResponse"
      
      Task:
      1. REACT to the user (did they mess up? were they smooth?).
      2. Analyze their tone/risk briefly.
      3. Set the scene for the NEXT moment (Beat ${currentBeatNumber + 1}).
      
      Return JSON:
      {
        "feedback": {
          "risk": "Low/Med/High", // How risky was their last move?
          "tone": "Warm/Cold/Awkward/Confident", // Tone descriptor
          "confidence_score": 1, // Change from previous (e.g. +1, -1, 0)
          "analysis": "Short 1 sentence on why."
        },
        "next_beat": {
          "title": "Short Title (e.g. 'The Reaction')",
          "question": "Description of what *I* (partner) do next, and question for user.",
          "placeholder": "Type what you'd say..."
        }
      }
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );

      if (response == null) throw Exception("No API response");

      String jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error generating next beat: $e");
      // Fallback
      return {
        "feedback": {
          "risk": "Low",
          "tone": "Neutral",
          "confidence_score": 0,
          "analysis": "Good effort.",
        },
        "next_beat": {
          "title": "Continuing...",
          "question": "The conversation continues. What do you say?",
          "placeholder": "Type here...",
        },
      };
    }
  }

  /// Feature: Roast Me / Pickup Line Challenge
  Future<Map<String, dynamic>> getPickupLineFeedback({
    required String pickupLine,
    required List<Map<String, String>> history, // Previous attempts
  }) async {
    try {
      final prompt =
          '''
      Game: "Roast Me With Your Best Pickup Line".
      You are the target of a pickup line. You are hard to impress, playful, witty, and brutally honest.
      
      User's Pickup Line: "$pickupLine"
      
      Previous Context (if any):
      ${history.map((m) => "${m['role']}: ${m['content']}").join("\n")}
      
      Your Role:
      1. React emotionally (Impressed / Unimpressed / Cringed / Shocked / Laughing).
      2. Rate the line on Charm, Originality, Confidence (1-5 stars).
      3. Give a text response:
         - feel the line. Is it cheesy? Is it actually smooth? specific?
         - If good: Tease them, smile, maybe even blush a little, or challenge them to prove it.
         - If bad: Roast them hard, laugh at them, or give a dry "nice try".
         - If they are repeating themselves or using a very old cliché, call them out for it.
         - If their game is improving across the context, acknowledge it. If it's getting worse, tell them.
      4. Escalation: A short sentence challenging them for the next turn.
      5. Suggestion: If the line was weak, suggest a much better, cooler way to say it ("better_line").
      6. Rizz Rating: A fun title like "W Rizz", "Negative Rizz", "Mid Rizz", "Rizz God", etc.

      Return JSON ONLY:
      {
        "reaction": "Impressed/Unimpressed/Cringed/Shocked",
        "emoji": "😏/😐/😬/😳",
        "rizz_rating": "Title here",
        "response": "Your spoken reply...",
        "feedback": "Short critique of why it worked or failed.",
        "better_line": "A cooler suggestion if applicable",
        "scores": {
          "charm": 3,
          "originality": 2,
          "confidence": 4
        }
      }
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );

      if (response == null) return {};

      final jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Pickup Line Feedback Error: $e');
      return {};
    }
  }

  /// Feature: Scenario Roleplay - AI plays as USER (Auto-pilot)
  Future<String> getUserProxyReply({
    required List<Map<String, String>> history,
    required String scenarioContext,
    String? tone, // "Confident", "Shy", "Flirty", etc.
  }) async {
    try {
      final prompt =
          '''
      You are roleplaying as the USER in this scenario.
      Scenario: "$scenarioContext"
      Your Tone: ${tone ?? "Natural, adaptive"}
      
      Conversation History:
      ${history.map((m) => "${(m['role'] ?? '').toUpperCase()}: ${m['content']}").join("\n")}
      
      Task: Write the next message for the USER.
      - Keep it realistic (text message style).
      - Match the requested tone.
      - Don't be too long.
      - Do NOT use quotes.
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
      );

      // Strip any "USER:", "User:", "ME:", or "Me:" prefixes the AI might add
      String reply = response?.replaceAll('"', '').trim() ?? "";
      reply = reply.replaceFirst(
        RegExp(r'^(USER|User|ME|Me|THEM|Them):\s*'),
        '',
      );

      return reply.trim();
    } catch (e) {
      debugPrint('User Proxy Error: $e');
      return "";
    }
  }

  /// Feature: Scenario Roleplay - End of Chat Breakdown
  Future<Map<String, dynamic>> getScenarioBreakdown({
    required List<Map<String, String>> history,
    required String scenarioContext,
  }) async {
    try {
      final prompt =
          '''
      Analyze this roleplay conversation.
      Scenario: "$scenarioContext"
      
      History:
      ${history.map((m) => "${m['role']}: ${m['content']}").join("\n")}
      
      Provide a breakdown in JSON:
      {
        "what_worked": ["point 1", "point 2"],
        "what_didnt": ["point 1", "point 2"],
        "next_time_tips": ["tip 1", "tip 2"],
        "overall_score": 85
      }
      ''';

      final response = await _postRequest(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );

      if (response == null) return {};
      final jsonString = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Breakdown Error: $e');
      return {};
    }
  }
}
