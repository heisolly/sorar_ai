import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/simulation_scenario.dart';
import '../../widgets/parot_mascot.dart';
import '../../services/ai_service.dart';
import '../../widgets/chat_bubble.dart';

class SimulationScreen extends StatefulWidget {
  final String category;
  final String? scenarioId; // If linked from previous

  const SimulationScreen({super.key, required this.category, this.scenarioId});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final AiService _aiService = AiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SimulationScenario? _scenario;
  final List<Msg> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  Future<void> _startSimulation() async {
    final scenario = await _aiService.generateSimulationScenario(
      category: widget.category,
      linkedCardId: widget.scenarioId,
    );

    if (mounted) {
      if (scenario != null) {
        setState(() {
          _scenario = scenario;
          _isLoading = false;
          _messages.add(Msg(text: scenario.initialMessage, isMe: false));
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start simulation. Try again.'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(Msg(text: text, isMe: true));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => m != _messages.last)
          .map(
            (m) => {'role': m.isMe ? 'user' : 'assistant', 'content': m.text},
          )
          .toList();

      final reply = await _aiService.getChatReply(
        userMessage: text,
        history: history,
        context: _scenario?.context ?? '',
        partnerName: _scenario?.partnerName ?? 'Partner',
      );

      if (mounted) {
        setState(() {
          _messages.add(Msg(text: reply, isMe: false));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        // Show error subtly
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B141A), // WhatsApp Dark Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C34),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ParotMascot(
              state: _isTyping ? ParotState.thinking : ParotState.idle,
              size: 40,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scenario?.partnerName ?? 'Partner',
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.white),
                ),
                Text(
                  _isTyping ? 'typing...' : 'online',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(message: msg.text, isMe: msg.isMe);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFF1F2C34),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.grey),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Message',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2A3942),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF00A884),
            radius: 24,
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ), // Simplified icon
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class Msg {
  final String text;
  final bool isMe;
  Msg({required this.text, required this.isMe});
}
