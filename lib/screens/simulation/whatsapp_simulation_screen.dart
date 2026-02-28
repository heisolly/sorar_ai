import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'dart:async';
import '../../models/simulation_scenario.dart';
import '../../models/simulation_models.dart';
import '../../services/ai_service.dart';
import '../../services/supabase_service.dart';
import '../../config/supabase_config.dart';
import '../../widgets/whatsapp_chat_bubble.dart';
import 'session_summary_screen.dart';

class WhatsAppSimulationScreen extends StatefulWidget {
  final String category;
  final String? scenarioId;
  final SimulationScenario? scenario;

  const WhatsAppSimulationScreen({
    super.key,
    required this.category,
    this.scenarioId,
    this.scenario,
  });

  @override
  State<WhatsAppSimulationScreen> createState() =>
      _WhatsAppSimulationScreenState();
}

class _WhatsAppSimulationScreenState extends State<WhatsAppSimulationScreen>
    with TickerProviderStateMixin {
  final AiService _aiService = AiService();
  final SupabaseService _supabase = SupabaseService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  SimulationScenario? _scenario;
  final List<ChatMessage> _messages = [];
  String? _sessionId;
  bool _isLoading = true;
  bool _isTyping = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _currentHint = '';
  bool _showHint = false;
  int _totalScore = 0;
  int _messageCount = 0;
  final List<MessageAnalysis> _analyses = [];

  // Animation controllers
  late AnimationController _hintController;
  late AnimationController _scoreController;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startSimulation();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _startSimulation() async {
    try {
      // Use provided scenario or generate new one
      SimulationScenario? scenario = widget.scenario;

      scenario ??= await _aiService.generateSimulationScenario(
        category: widget.category,
        linkedCardId: widget.scenarioId,
      );

      if (scenario != null && mounted) {
        // Create session in Supabase
        final session = await _supabase.createChatSession(
          scenarioId: widget.scenarioId ?? 'simulation_${widget.category}',
          additionalData: {
            'category': widget.category,
            'difficulty': scenario.difficulty,
            'partner_name': scenario.partnerName,
          },
        );

        setState(() {
          _scenario = scenario;
          _sessionId = session['id'];
          _isLoading = false;
          _messages.add(
            ChatMessage(
              text: scenario!.initialMessage,
              isMe: false,
              timestamp: DateTime.now(),
              partnerName: scenario.partnerName,
            ),
          );
        });

        // Speak the initial message
        await _tts.speak(scenario.initialMessage);
      } else {
        _handleError();
      }
    } catch (e) {
      debugPrint('Error starting simulation: $e');
      _handleError();
    }
  }

  void _handleError() {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start simulation. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _sendMessage({String? voiceText}) async {
    final text = voiceText ?? _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    final userMessage = ChatMessage(
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
      _showHint = false;
      _messageCount++;
    });

    _scrollToBottom();

    // Save user message
    if (_sessionId != null) {
      await _supabase.addChatMessage(
        sessionId: _sessionId!,
        sender: 'user',
        content: text,
      );
    }

    try {
      // Analyze user's message
      final analysis = await _aiService.analyzeUserMessage(
        message: text,
        context: _scenario?.context ?? '',
      );

      final score = analysis['score'] ?? 5;
      final feedback = analysis['feedback'] ?? '';
      final tone = analysis['tone'] ?? 'neutral';

      // Store analysis
      _analyses.add(
        MessageAnalysis(
          message: text,
          score: score,
          feedback: feedback,
          tone: tone,
          timestamp: DateTime.now(),
        ),
      );

      _totalScore += score as int;

      // Show hint based on score
      if (score < 7) {
        setState(() {
          _currentHint = feedback;
          _showHint = true;
        });
        _hintController.forward().then((_) {
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              _hintController.reverse();
              setState(() => _showHint = false);
            }
          });
        });
      }

      // Animate score
      _scoreController.forward().then((_) => _scoreController.reverse());

      // Get AI response
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
        final aiMessage = ChatMessage(
          text: reply,
          isMe: false,
          timestamp: DateTime.now(),
          partnerName: _scenario?.partnerName ?? 'Partner',
          score: score,
        );

        setState(() {
          _messages.add(aiMessage);
          _isTyping = false;
        });

        // Save AI message
        if (_sessionId != null) {
          await _supabase.addChatMessage(
            sessionId: _sessionId!,
            sender: 'ai',
            content: reply,
          );
        }

        _scrollToBottom();

        // Speak AI response
        await _tts.speak(reply);
      }
    } catch (e) {
      debugPrint('Error in message flow: $e');
      if (mounted) {
        setState(() => _isTyping = false);
      }
    }
  }

  void _startListening() async {
    if (!_speechEnabled) return;

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);

    // Send the voice message
    if (_controller.text.trim().isNotEmpty) {
      _sendMessage(voiceText: _controller.text.trim());
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

  void _endSession() async {
    // Calculate final score
    final avgScore = _messageCount > 0
        ? (_totalScore / _messageCount).round()
        : 0;

    // Update session in Supabase
    if (_sessionId != null) {
      await _supabase.updateChatSession(_sessionId!, {
        'status': 'completed',
        'score': avgScore,
      });
      await _supabase.incrementProgressMetric(MetricType.sessionsCompleted);
    }

    // Navigate to summary
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SessionSummaryScreen(
            scenario: _scenario!,
            messages: _messages,
            analyses: _analyses,
            totalScore: avgScore,
            messageCount: _messageCount,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _hintController.dispose();
    _scoreController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B141A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00A884)),
              const SizedBox(height: 20),
              Text(
                'Preparing simulation...',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Background pattern (WhatsApp style)
          Opacity(
            opacity: 0.05,
            child: Image.asset(
              'assets/whatsapp_bg.png',
              repeat: ImageRepeat.repeat,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.none,
              errorBuilder: (context, error, stackTrace) => Container(),
            ),
          ),

          Column(
            children: [
              // Hint banner
              if (_showHint) _buildHintBanner(),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    final message = _messages[index];
                    return WhatsAppChatBubble(
                      message: message,
                      showScore: message.score != null,
                    );
                  },
                ),
              ),

              // Input area
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1F2C34),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1F2C34),
              title: Text(
                'End Session?',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              content: Text(
                'Do you want to end this simulation and see your summary?',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.inter(color: const Color(0xFF00A884)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _endSession();
                  },
                  child: Text(
                    'End Session',
                    style: GoogleFonts.inter(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF00A884),
            radius: 20,
            child: Text(
              _scenario?.partnerName[0].toUpperCase() ?? 'P',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scenario?.partnerName ?? 'Partner',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isTyping ? 'typing...' : 'online',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _isTyping ? const Color(0xFF00A884) : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Score indicator
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getScoreColor(
              _messageCount > 0 ? (_totalScore / _messageCount).round() : 0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.2).animate(
              CurvedAnimation(
                parent: _scoreController,
                curve: Curves.elasticOut,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _messageCount > 0
                      ? '${(_totalScore / _messageCount).round()}/10'
                      : '0/10',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHintBanner() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _hintController, curve: Curves.easeOut),
          ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade700, Colors.orange.shade600],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentHint,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2C34),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value + index * 0.3) % 1.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFF1F2C34)),
      child: SafeArea(
        child: Row(
          children: [
            // Emoji button
            IconButton(
              icon: const Icon(
                Icons.emoji_emotions_outlined,
                color: Colors.grey,
              ),
              onPressed: () {
                // Could add emoji picker
              },
            ),

            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3942),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    hintStyle: GoogleFonts.inter(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Voice or send button
            _controller.text.isEmpty
                ? AvatarGlow(
                    animate: _isListening,
                    glowColor: const Color(0xFF00A884),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF00A884),
                      radius: 24,
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                        ),
                        onPressed: _isListening
                            ? _stopListening
                            : _startListening,
                      ),
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: const Color(0xFF00A884),
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }
}
