import 'package:uuid/uuid.dart';
import '../models/scenario_card.dart';
import 'ai_service.dart';

class ScenarioService {
  final _uuid = const Uuid();
  final _aiService = AiService();

  // Categories metadata
  final Map<String, Map<String, String>> _categories = {
    'awkward_moments': {
      'name': 'Awkward Moments',
      'icon': '😬',
      'color': '0xFFF43F5E',
    },
    'rizz': {'name': 'Rizz & Dating', 'icon': '😏', 'color': '0xFFEC4899'},
    'family': {'name': 'Family', 'icon': '👨‍👩‍👧‍👦', 'color': '0xFF8B5CF6'},
    'work': {'name': 'Work', 'icon': '💼', 'color': '0xFF3B82F6'},
    'strangers': {'name': 'Strangers', 'icon': '👥', 'color': '0xFF10B981'},
  };

  // Fetch AI generated cards
  Future<List<ScenarioCard>> fetchScenarioCards(String category) async {
    final aiCards = await _aiService.generateScenarioCards(
      category: category,
      count: 4,
    );

    // Inject "Coffee Shop" scenario for Rizz/Dating specific demo
    if (category == 'rizz' || category == 'strangers') {
      final coffeeCard = ScenarioCard(
        id: 'coffee_shop_demo',
        category: category,
        situation:
            "You’re waiting for your drink.\nSomeone catches your eye at the counter.\nThere’s a brief moment where it wouldn’t be weird to say something.",
        difficulty: 'Medium',
        options: [
          ResponseOption(
            id: 'opt_a',
            text:
                "“Hey — random, but you seem like you know your way around coffee. What do you usually get?”",
            score: 95,
            feedback:
                "Perfect. Low stakes, observational, gives them an easy way to answer.",
            toneAnalysis: ToneAnalysis(
              tone: "Warm, Curious",
              aura: "Socially Aware",
              tips: ["Open body language", " genuine curiosity"],
            ),
          ),
          ResponseOption(
            id: 'opt_b',
            text: "“Hey. Do you come here often?”",
            score: 60,
            feedback:
                "A bit cliché. It works, but it puts pressure on them to be interesting.",
            toneAnalysis: ToneAnalysis(
              tone: "Generic",
              aura: "Low Risk",
              tips: ["Try to be more specific next time"],
            ),
          ),
          ResponseOption(
            id: 'opt_c',
            text:
                "Smile, wait for eye contact, then: “This place always smells dangerously good.”",
            score: 90,
            feedback:
                "Strong. Uses environment and sensory detail. Confident silence first.",
            toneAnalysis: ToneAnalysis(
              tone: "Playful",
              aura: "Confident",
              tips: ["Eye contact is key", "Don't rush the delivery"],
            ),
          ),
        ],
      );
      return [coffeeCard, ...aiCards];
    }

    return aiCards;
  }

  // Generate a custom scenario card from user input using AI
  Future<ScenarioCard> generateCustomScenarioCard(String customPrompt) async {
    final cards = await _aiService.generateScenarioCards(
      category: 'custom',
      count: 1,
      customScenario: customPrompt,
    );
    if (cards.isNotEmpty) return cards.first;

    // Fallback if AI fails
    return ScenarioCard(
      id: _uuid.v4(),
      category: 'custom',
      situation: customPrompt,
      difficulty: 'Custom',
      customPrompt: customPrompt,
      options: [],
    );
  }

  // Get all available categories
  List<String> getCategories() {
    return _categories.keys.toList();
  }

  // Get category display name
  String getCategoryDisplayName(String category) {
    return _categories[category]?['name'] ?? category;
  }

  // Get category icon
  String getCategoryIcon(String category) {
    return _categories[category]?['icon'] ?? '📝';
  }

  // Get category color
  String getCategoryColor(String category) {
    return _categories[category]?['color'] ?? '0xFF6366F1';
  }
}
