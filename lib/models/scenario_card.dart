class ScenarioCard {
  final String id;
  final String category;
  final String situation;
  final List<ResponseOption> options;
  final String difficulty;
  final String? customPrompt;

  ScenarioCard({
    required this.id,
    required this.category,
    required this.situation,
    required this.options,
    required this.difficulty,
    this.customPrompt,
  });

  factory ScenarioCard.fromJson(Map<String, dynamic> json) {
    return ScenarioCard(
      id: json['id'] as String,
      category: json['category'] as String,
      situation: json['situation'] as String,
      options: (json['options'] as List)
          .map((o) => ResponseOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      difficulty: json['difficulty'] as String,
      customPrompt: json['custom_prompt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'situation': situation,
      'options': options.map((o) => o.toJson()).toList(),
      'difficulty': difficulty,
      'custom_prompt': customPrompt,
    };
  }
}

class ResponseOption {
  final String id;
  final String text;
  final int score; // 0-100
  final String feedback;
  final ToneAnalysis toneAnalysis;

  ResponseOption({
    required this.id,
    required this.text,
    required this.score,
    required this.feedback,
    required this.toneAnalysis,
  });

  factory ResponseOption.fromJson(Map<String, dynamic> json) {
    return ResponseOption(
      id: json['id'] as String,
      text: json['text'] as String,
      score: json['score'] as int,
      feedback: json['feedback'] as String,
      toneAnalysis: ToneAnalysis.fromJson(
        json['tone_analysis'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'score': score,
      'feedback': feedback,
      'tone_analysis': toneAnalysis.toJson(),
    };
  }
}

class ToneAnalysis {
  final String tone; // e.g., "confident", "passive", "aggressive"
  final String aura; // e.g., "professional", "friendly", "awkward"
  final List<String> tips;

  ToneAnalysis({required this.tone, required this.aura, required this.tips});

  factory ToneAnalysis.fromJson(Map<String, dynamic> json) {
    return ToneAnalysis(
      tone: json['tone'] as String,
      aura: json['aura'] as String,
      tips: (json['tips'] as List).map((t) => t as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'tone': tone, 'aura': aura, 'tips': tips};
  }
}
