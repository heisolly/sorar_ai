import 'package:flutter/material.dart';
import '../../widgets/simple_chat.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/ai_service.dart';

class ScenarioChatScreen extends StatefulWidget {
  final String scenarioContext;
  final String aiPersona;

  const ScenarioChatScreen({
    super.key,
    required this.scenarioContext,
    required this.aiPersona,
  });

  @override
  State<ScenarioChatScreen> createState() => _ScenarioChatScreenState();
}

class _ScenarioChatScreenState extends State<ScenarioChatScreen> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'current_user');
  final _aiUser = const types.User(id: 'ai_user', firstName: 'AI');

  @override
  void initState() {
    super.initState();
    _startScenario();
  }

  void _startScenario() async {
    await Future.delayed(const Duration(seconds: 1));
    final initialMsg = types.TextMessage(
      author: _aiUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: "Hey, can we talk for a sec?",
    );
    if (mounted) {
      setState(() {
        _messages.insert(0, initialMsg);
      });
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });

    final aiService = context.read<AiService>();

    // 1. Micro-Feedback
    try {
      final analysis = await aiService.analyzeUserMessage(
        message: message.text,
        context: widget.scenarioContext,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Score: ${analysis['score']}/10. ${analysis['feedback']}",
            ),
            backgroundColor: Colors.indigo,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error getting feedback: $e");
    }

    // 2. Reply
    try {
      final replyData = await aiService.generateReply(
        prompt: message.text,
        context: widget.scenarioContext,
        persona: widget.aiPersona,
      );

      if (mounted) {
        final aiMessage = types.TextMessage(
          author: _aiUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: replyData['reply'] ?? "...",
        );
        setState(() {
          _messages.insert(0, aiMessage);
        });
      }
    } catch (e) {
      debugPrint("Error getting reply: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.aiPersona),
            const Text(
              "online",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: SimpleChat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
      ),
    );
  }
}
