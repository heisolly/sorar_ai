class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? partnerName;
  final int? score;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.partnerName,
    this.score,
  });
}

class MessageAnalysis {
  final String message;
  final int score;
  final String feedback;
  final String tone;
  final DateTime timestamp;

  MessageAnalysis({
    required this.message,
    required this.score,
    required this.feedback,
    required this.tone,
    required this.timestamp,
  });
}
