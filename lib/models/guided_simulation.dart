class GuidedSimulation {
  final String id;
  final String title;
  final String context;
  final List<SimulationBeat> beats;

  GuidedSimulation({
    required this.id,
    required this.title,
    required this.context,
    required this.beats,
  });
}

class SimulationBeat {
  final int beatNumber;
  final String title; // e.g. "Opening Move"
  final String question; // e.g. "What do you say to start the interaction?"
  final String? placeholder; // e.g. "Type what you'd actually say."

  SimulationBeat({
    required this.beatNumber,
    required this.title,
    required this.question,
    this.placeholder,
  });
}

// Mock Data
final mockGuidedSimulation = GuidedSimulation(
  id: 'coffee_shop',
  title: 'Coffee Shop Encounter',
  context:
      "You’ve noticed each other a few times.\nToday, there’s a natural opening.",
  beats: [
    SimulationBeat(
      beatNumber: 1,
      title: 'Opening Move',
      question: 'What do you say to start the interaction?',
      placeholder: 'Type what you\'d actually say.',
    ),
    SimulationBeat(
      beatNumber: 2,
      title: 'Reading the Reaction',
      question:
          'They look up and smile slightly, but don\'t speak immediately.',
    ),
    SimulationBeat(
      beatNumber: 3,
      title: 'Deepening or Exiting',
      question: 'They ask "Have we met before?"',
    ),
    SimulationBeat(
      beatNumber: 4,
      title: 'Handling Uncertainty',
      question: 'The barista calls out a wrong order, interrupting you.',
    ),
    SimulationBeat(
      beatNumber: 5,
      title: 'Closing or Pivoting',
      question: 'They grab their coffee and look at the door.',
    ),
  ],
);
