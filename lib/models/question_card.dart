class QuestionCard {
  final String id;
  final String category;
  final String scenario;
  final List<String> options;
  final int bestOptionIndex; // For internal scoring or hint
  final String explanation; // Why one is better than others
  final String difficulty;

  QuestionCard({
    required this.id,
    required this.category,
    required this.scenario,
    required this.options,
    required this.bestOptionIndex,
    required this.explanation,
    required this.difficulty,
  });

  factory QuestionCard.fromMap(Map<String, dynamic> map) {
    return QuestionCard(
      id: map['id'] ?? '',
      category: map['category'] ?? 'General',
      scenario: map['scenario'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      bestOptionIndex: map['best_option_index'] ?? 0,
      explanation: map['explanation'] ?? '',
      difficulty: map['difficulty'] ?? 'Easy',
    );
  }
}
