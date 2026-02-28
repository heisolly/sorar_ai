class SimulationScenario {
  final String id;
  final String title;
  final String initialMessage;
  final String partnerName;
  final String context;
  final String difficulty;

  SimulationScenario({
    required this.id,
    required this.title,
    required this.initialMessage,
    required this.partnerName,
    required this.difficulty,
    required this.context,
  });

  factory SimulationScenario.fromMap(Map<String, dynamic> map) {
    return SimulationScenario(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Simulation',
      initialMessage: map['initial_message'] ?? '...',
      partnerName: map['partner_name'] ?? 'Other',
      difficulty: map['difficulty'] ?? 'Easy',
      context: map['context'] ?? '',
    );
  }
}
