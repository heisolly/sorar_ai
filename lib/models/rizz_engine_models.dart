class RizzScenarioSeeds {
  static const List<String> environments = [
    'Coffee shop (waiting area)',
    'Coffee shop (pickup counter)',
    'Gym (between sets)',
    'Gym (water fountain)',
    'Party (kitchen)',
    'Party (balcony)',
    'Campus (library entrance)',
    'Campus (hallway passing)',
    'Bar (ordering)',
    'Bar (standing nearby)',
    'Elevator (short ride)',
    'Elevator (long pause)',
    'Street crossing',
    'Shared workspace lobby',
  ];

  static const List<String> triggers = [
    'Brief eye contact',
    'Smile + look away',
    'Standing next to each other',
    'Shared inconvenience (line delay, noise)',
    'Accidental physical proximity',
    'Comment overheard',
    'Mutual glance at same object',
    'Reaction to same external event',
  ];

  static const List<String> constraints = [
    'Limited time window',
    'Others nearby',
    'One person distracted',
    'One person with headphones',
    'Both waiting on something',
    'Status ambiguity',
    'Work-adjacent risk',
  ];

  static const List<String> uncertainties = [
    'Reaction unclear',
    'Mixed signals',
    'Delayed response',
    'Polite but closed',
    'Friendly but non-investing',
    'Curious but guarded',
  ];

  static const Map<String, List<String>> stakes = {
    'Easy': ['Low embarrassment risk', 'Public, casual setting'],
    'Medium': ['Social friction possible', 'Some reputational risk'],
    'Hard': ['Awkwardness likely', 'Status imbalance', 'Clear exit required'],
  };
}

class RizzScenarioConfig {
  final String environment;
  final String trigger;
  final String constraint;
  final String uncertainty;
  final String stakesLevel;
  final String skillLevel; // 'Beginner', 'Intermediate', 'Advanced'

  RizzScenarioConfig({
    required this.environment,
    required this.trigger,
    required this.constraint,
    required this.uncertainty,
    required this.stakesLevel,
    required this.skillLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'environment': environment,
      'trigger': trigger,
      'constraint': constraint,
      'uncertainty': uncertainty,
      'stakesLevel': stakesLevel,
      'skillLevel': skillLevel,
    };
  }
}

class RizzBeat {
  final int beatNumber;
  final String question;
  final String? placeholder;
  final String? contextSummary; // From previous beat outcome
  final String? userAction; // What the user did (filled after user input)

  // Feedback from previous beat (if applicable)
  final String? feedbackTone;
  final String? feedbackRisk;
  final String? feedbackAnalysis;
  final bool isLastBeat;

  RizzBeat({
    required this.beatNumber,
    required this.question,
    this.placeholder,
    this.contextSummary,
    this.userAction,
    this.feedbackTone,
    this.feedbackRisk,
    this.feedbackAnalysis,
    this.isLastBeat = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'beatNumber': beatNumber,
      'question': question,
      'placeholder': placeholder,
      'contextSummary': contextSummary,
      'userAction': userAction,
      'feedbackTone': feedbackTone,
      'feedbackRisk': feedbackRisk,
      'feedbackAnalysis': feedbackAnalysis,
    };
  }
}

class RizzScenario {
  final String id;
  final RizzScenarioConfig config;
  final List<RizzBeat> beats;
  bool isCompleted;

  RizzScenario({
    required this.id,
    required this.config,
    this.beats = const [],
    this.isCompleted = false,
  });
}
