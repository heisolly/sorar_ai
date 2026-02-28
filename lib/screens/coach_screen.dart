import 'package:flutter/material.dart';
import 'dart:math'; // For random image generation
import '../../widgets/simple_chat.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;

import '../services/supabase_service.dart';
import '../config/supabase_config.dart';
import '../services/ai_service.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'simulation_setup_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/noise_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CoachScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? simulationType;
  final String? roleMode; // 'assistant', 'practice', 'hybrid'
  final String? initialScenario;
  final bool userStarts;
  final String? sessionId;

  const CoachScreen({
    super.key,
    this.onBack,
    this.simulationType,
    this.roleMode = 'practice',
    this.initialScenario,
    this.userStarts = false,
    this.sessionId,
  });

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final List<types.Message> _messages = [];
  // Instance user (Myself: Me)
  final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');
  // AI Partner User (Dynamic)
  late types.User _ai;
  late String _coachImageUrl;

  final _supabase = SupabaseService();
  final _aiService = AiService();
  String? _sessionId;
  bool _isLoading = true;

  // Voice & Input
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _isTyping = false;
  bool _showEmojiPicker = false;

  // Auto-pilot state
  bool _isGeneratingDraft = false;

  @override
  void initState() {
    super.initState();

    // Generate AI Persona Image based on scenario context
    _generatePartnerIdentity(); // Sets _coachImageUrl and creates _ai user

    _initializeSession();
    _initSpeech();
  }

  void _generatePartnerIdentity() {
    final contextLower = (widget.initialScenario ?? "").toLowerCase();
    final typeLower = (widget.simulationType ?? "").toLowerCase();

    // Keyword detection
    final bool isFemale =
        contextLower.contains('girl') ||
        contextLower.contains('woman') ||
        contextLower.contains('she') ||
        contextLower.contains('her') ||
        contextLower.contains('gf') ||
        contextLower.contains('girlfriend') ||
        contextLower.contains(
          'crush',
        ) || // Usually implies female in context of "gym crush" examples
        typeLower.contains(
          'rizz',
        ); // Default to female for Rizz category unless specified otherwise

    final bool isMale =
        contextLower.contains('boy') ||
        contextLower.contains('man') ||
        contextLower.contains('he') ||
        contextLower.contains('him') ||
        contextLower.contains('bf') ||
        contextLower.contains('boyfriend');

    // Determine gender (Male takes precedence if explicitly mentioned, otherwise Female if mentioned, else mixed random)
    String gender = 'women';
    if (isMale && !isFemale) {
      gender = 'men';
    } else if (isFemale) {
      gender = 'women';
    } else {
      // Randomly pick if neutral
      gender = Random().nextBool() ? 'women' : 'men';
    }

    // Generate random seed for consistent avatar
    final randomSeed = Random().nextInt(9999);
    // Use DiceBear Avatars API (CORS-friendly)
    // Using avataaars style with gender-appropriate options
    final style = gender == 'men' ? 'male' : 'female';
    _coachImageUrl =
        'https://api.dicebear.com/7.x/avataaars/svg?seed=$randomSeed&gender=$style';

    // Create AI User
    _ai = types.User(
      id: 'parot-coach-ai',
      firstName: 'Partner', // Generic name, could be randomized too
      imageUrl: _coachImageUrl,
    );
  }

  // ... (Keep _initSpeech and _toggleVoiceInput same as before, omitted for brevity if unchanged, but strictly I must allow reusing or I can replace the whole block if easier. I'll stick to replacing relevant parts carefully or the whole file if structure changes too much. Given the complexity, I will replace the state class methods.)

  // Helper to check modes
  bool get _isAssistantMode => widget.roleMode == 'assistant';
  bool get _isHybridMode => widget.roleMode == 'hybrid';

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (e) => debugPrint('Speech error: $e'),
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (!_speechEnabled) {
      _initSpeech();
      if (!_speechEnabled) return;
    }

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) return;
      }

      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _textController.text = result.recognizedWords;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        localeId: "en_US",
      );
    }
  }

  Future<void> _initializeSession() async {
    try {
      if (widget.sessionId != null) {
        await _loadSession(widget.sessionId!);
        return;
      }

      if (widget.simulationType != null) {
        await _createNewSession();
        return;
      }

      final sessions = await _supabase.getChatSessions(limit: 1);
      if (sessions.isNotEmpty) {
        await _loadSession(sessions.first['id']);
      } else {
        await _createNewSession();
      }
    } catch (e) {
      debugPrint('Error initializing session: $e');
      if (mounted) setState(() => _isLoading = false);
      _startSimulationIfNeeded();
    }
  }

  Future<void> _createNewSession() async {
    try {
      final session = await _supabase.createChatSession(
        scenarioId: null,
        additionalData: {
          'metadata': {
            'role_mode': widget.roleMode,
            'scenario_type': widget.simulationType ?? 'roleplay',
            'user_context': widget.initialScenario ?? '',
          },
        },
      );

      if (mounted) {
        setState(() {
          _sessionId = session['id'];
          _messages.clear();
          _isLoading = false;
        });
      }

      _startSimulationIfNeeded();
    } catch (e) {
      debugPrint('Error creating session: $e');
    }
  }

  Future<void> _loadSession(String sessionId) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      _sessionId = sessionId;
      final history = await _supabase.getChatMessages(_sessionId!);

      final loadedMessages = history.map((m) {
        final isUser = m['sender'] == 'user';
        final text = m['content'] as String? ?? "";
        return types.TextMessage(
          author: isUser ? _user : _ai,
          createdAt: DateTime.parse(m['created_at']).millisecondsSinceEpoch,
          id: m['id'] ?? const Uuid().v4(),
          text: text,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(loadedMessages.reversed);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startSimulationIfNeeded() async {
    if (_messages.isNotEmpty) return;

    // Case 1: User Starts
    if (widget.userStarts) {
      // If AI is playing ME (Assistant Mode), and User plays THEM (Target).
      // Since User Starts, the Human (Them) types first.
      // So effectively we just wait for input. No auto-pilot needed.
      return;
    }

    // Case 2: AI (Partner) Starts
    setState(() => _isTyping = true); // Partner typing

    try {
      final reply = await _aiService.getCoachReply(
        message:
            "(System: Start the conversation now. You are the character. Say the first line.)",
        history: [],
        simulationType: widget.simulationType,
        userContext: widget.initialScenario,
        roleMode: widget.roleMode,
      );

      if (!mounted) return;

      final message = types.TextMessage(
        author: _ai,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: reply,
      );

      setState(() {
        _messages.insert(0, message);
        _isTyping = false;
      });

      if (_sessionId != null) {
        _saveMessageToSupabase(message, MessageSender.ai);
      }
    } catch (e) {
      debugPrint("Error starting simulation: $e");
      setState(() => _isTyping = false);
    }
  }

  // Generate a draft for the user (Assistant/Hybrid Mode)
  Future<void> _triggerAutoPilot() async {
    if (_isGeneratingDraft) return;
    setState(() => _isGeneratingDraft = true);

    try {
      final history = _getHistoryForAI();
      final draft = await _aiService.getUserProxyReply(
        history: history,
        scenarioContext: widget.initialScenario ?? "",
      );

      if (mounted) {
        setState(() {
          _textController.text = draft;
          _isGeneratingDraft = false;
        });
      }
    } catch (e) {
      debugPrint("Auto Pilot Error: $e");
      setState(() => _isGeneratingDraft = false);
    }
  }

  // Handle "Take Over" button click (Hybrid Mode)
  void _handleTakeOver() {
    _triggerAutoPilot();
  }

  void _handleSendPressed(types.PartialText message) {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
    }

    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });

    if (_sessionId != null) {
      _saveMessageToSupabase(textMessage, MessageSender.user);
    }

    _getAIResponse(message.text);
  }

  Future<void> _getAIResponse(String userMessage) async {
    // 1. Prepare history context
    // _getHistoryForAI is unused here because we construct historyForContext manually
    // to handle the skipping logic correctly.

    final historyForContext = _messages
        .skip(1)
        .map((m) {
          return {
            'role': m.author.id == _user.id ? 'user' : 'assistant',
            'content': (m as types.TextMessage).text,
          };
        })
        .toList()
        .reversed
        .toList();

    try {
      setState(() => _isTyping = true);
      final reply = await _aiService.getCoachReply(
        message: userMessage,
        history: historyForContext,
        simulationType: widget.simulationType,
        userContext: widget.initialScenario,
        roleMode: widget.roleMode,
      );

      if (!mounted) return;

      final message = types.TextMessage(
        author: _ai,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: reply,
      );

      setState(() {
        _messages.insert(0, message);
        _isTyping = false;
      });

      if (_sessionId != null) {
        _saveMessageToSupabase(message, MessageSender.ai);
      }

      // No need to trigger auto-pilot here for Assistant Mode.
      // If AI (Me) just replied, now User (Them) needs to reply manually.
    } catch (e) {
      debugPrint("Error getting AI reply: $e");
      setState(() => _isTyping = false);
    }
  }

  List<Map<String, String>> _getHistoryForAI() {
    return _messages.reversed
        .whereType<types.TextMessage>()
        .map(
          (m) => {
            'role': m.author.id == _user.id ? 'user' : 'assistant',
            'content': m.text,
          },
        )
        .toList();
  }

  Future<void> _saveMessageToSupabase(
    types.TextMessage message,
    MessageSender sender,
  ) async {
    try {
      await _supabase.addChatMessage(
        sessionId: _sessionId!,
        sender: sender.value,
        content: message.text,
      );
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _speechToText.cancel(); // Stop listening
    if (_sessionId != null) {
      _completeSession();
    }
    super.dispose();
  }

  Future<void> _completeSession() async {
    try {
      await _supabase.updateChatSession(_sessionId!, {
        'status': 'completed',
        'score': 85,
      });
      await _supabase.incrementProgressMetric(MetricType.sessionsCompleted);
    } catch (e) {
      debugPrint('Error completing session: $e');
    }
  }

  // ... (build methods next)

  @override
  Widget build(BuildContext context) {
    // WhatsApp style doesn't use ghost cards, so we removed logic.

    return Scaffold(
      backgroundColor: const Color(
        0xFFFAE4D7,
      ), // Our warm peach background to match chat
      appBar: AppBar(
        backgroundColor: Colors.white, // Clean premium look
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leadingWidth: 70,
        leading: InkWell(
          onTap: () {
            // Navigate back to Simulation Setup
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SimulationSetupScreen(),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
              const SizedBox(width: 4),
              Hero(
                tag: 'coach_avatar',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDFE5E7),
                  backgroundImage: NetworkImage(_coachImageUrl),
                ),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Coach Parot",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  "online",
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    color: AppColors.energyAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.videocam_outlined,
              color: AppColors.textPrimary,
              size: 26,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.call_outlined,
              color: AppColors.textPrimary,
              size: 24,
            ),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textPrimary, size: 24),
            onSelected: (value) {
              if (value == 'history') {
                _showHistorySheet();
              } else if (value == 'delete') {
                _confirmDeleteCurrentSession();
              } else if (value == 'new_chat') {
                _createNewSession();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'history',
                child: Text('History'),
              ),
              const PopupMenuItem<String>(
                value: 'new_chat',
                child: Text('New Chat'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete Chat', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: NoiseBackground(
        child: Container(
          decoration: BoxDecoration(
            // We use a subtle gradient or solid color instead of image validation for now to ensure consistency,
            // or we can keep the image but overlay it more strongly with the peach color.
            // Let's keep the image if it exists but use the theme background as fallback.
            color: AppColors.primaryBackground,
            // Optional: Add a subtle gradient "lighting" effect
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryBackground,
                Color.lerp(AppColors.primaryBackground, Colors.white, 0.2)!,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          SimpleChat(
                            messages: _messages,
                            onSendPressed: _handleSendPressed,
                            user: _user,
                            hintText: "Message...",
                            controller: _textController,
                            onVoicePressed: _toggleVoiceInput,
                            isListening: _isListening,
                            isTyping: _isTyping,
                            onSuggestionRequested: _handleSuggestionRequest,
                            onEmojiPressed: _toggleEmojiPicker,
                            assistantMode: _isAssistantMode,
                            reverseAlignment: false,
                            inputHeader: _isHybridMode
                                ? Center(
                                    child: ActionChip(
                                      avatar: Icon(
                                        _isGeneratingDraft
                                            ? Icons.hourglass_empty
                                            : Icons.auto_mode,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        _isGeneratingDraft
                                            ? "AI Taking Over..."
                                            : "AI Take Over",
                                        style: GoogleFonts.manrope(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: AppColors
                                          .energyAccent, // Use Indigo accent
                                      onPressed: _isGeneratingDraft
                                          ? null
                                          : _handleTakeOver,
                                    ),
                                  ).animate().fadeIn().slideY(begin: -0.5)
                                : null,
                          ),
                          // Emoji Picker Container
                          if (_showEmojiPicker)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                height: 250,
                                child: emoji.EmojiPicker(
                                  onEmojiSelected: (category, emojiItem) {
                                    _textController.text += emojiItem.emoji;
                                    _textController.selection =
                                        TextSelection.fromPosition(
                                          TextPosition(
                                            offset: _textController.text.length,
                                          ),
                                        );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCurrentSession() async {
    if (_sessionId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete This Chat"),
        content: const Text(
          "Are you sure you want to delete this conversation? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.deleteChatSession(_sessionId!);
      if (mounted) {
        // Start a fresh session
        await _createNewSession();
      }
    }
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Chat History",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111B21),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _createNewSession();
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("New Chat"),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF00A884),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _supabase.getChatSessions(limit: 20),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text("Error: ${snapshot.error}"),
                            );
                          }
                          final sessions = snapshot.data ?? [];
                          if (sessions.isEmpty) {
                            return Center(
                              child: Text(
                                "No history yet",
                                style: GoogleFonts.inter(color: Colors.grey),
                              ),
                            );
                          }
                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: sessions.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              final date = DateTime.parse(
                                session['created_at'],
                              );
                              final isCurrent = session['id'] == _sessionId;

                              // Get title from metadata
                              String title = "Session ${index + 1}";
                              final metadata = session['metadata'];
                              if (metadata != null && metadata is Map) {
                                if (metadata['scenario_type'] != null) {
                                  title = (metadata['scenario_type'] as String)
                                      .toUpperCase()
                                      .replaceAll('_', ' ');
                                } else if (metadata['scenario_slug'] != null) {
                                  title = (metadata['scenario_slug'] as String)
                                      .toUpperCase()
                                      .replaceAll('_', ' ');
                                }
                              }

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE7FFDB),
                                  child: Icon(
                                    Icons.chat,
                                    color: const Color(0xFF128C7E),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  title,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: isCurrent
                                        ? const Color(0xFF128C7E)
                                        : const Color(0xFF111B21),
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat(
                                    'MMM d, yyyy • h:mm a',
                                  ).format(date),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isCurrent)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF128C7E),
                                          size: 20,
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () async {
                                        // Capture navigator before async gap
                                        final navigator = Navigator.of(context);
                                        // Confirm Delete
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              "Delete Conversation",
                                            ),
                                            content: const Text(
                                              "Are you sure you want to delete this conversation? This cannot be undone.",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _supabase.deleteChatSession(
                                            session['id'],
                                          );

                                          // If we deleted the current session, reset UI
                                          if (isCurrent && mounted) {
                                            // Close sheet using captured navigator
                                            navigator.pop();
                                            await _createNewSession();
                                          } else {
                                            // Just refresh list
                                            setState(() {});
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (!isCurrent) {
                                    _loadSession(session['id']);
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleSuggestionRequest() async {
    // 1. Get context
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start the conversation first!")),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A884)),
      ),
    );

    try {
      // Find last AI message
      String lastAi = "";
      String lastUser = "";
      // Messages are reversed in the list (0 is newest)
      for (var m in _messages) {
        if (m.author.id == _ai.id && lastAi.isEmpty) {
          lastAi = (m as types.TextMessage).text;
        }
        if (m.author.id == _user.id && lastUser.isEmpty) {
          lastUser = (m as types.TextMessage).text;
        }
      }

      final history = _messages.reversed
          .take(10) // Take last 10 messages for context
          .whereType<types.TextMessage>()
          .map(
            (m) => {
              'role': m.author.id == _user.id ? 'user' : 'assistant',
              'content': m.text,
            },
          )
          .toList();

      final suggestions = await _aiService.getCoachingSuggestions(
        lastUserMessage: lastUser,
        lastAiMessage: lastAi,
        history: history,
        simulationType: widget.simulationType,
        userContext: widget.initialScenario,
        currentDraft: _textController.text,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (suggestions.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't generate suggestions. Try again!"),
            backgroundColor: Color(0xFF111B21),
          ),
        );
        return;
      }

      if (!mounted) return;

      // Show Suggestions Sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A884).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF00A884),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Suggested Replies",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: const Color(0xFF111B21),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Tap to use, or edit before sending",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF667781),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Suggestion cards
                ...suggestions.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _textController.text = s['text'] ?? "";
                            _textController
                                .selection = TextSelection.fromPosition(
                              TextPosition(offset: _textController.text.length),
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _getLabelColor(s['label'] ?? ''),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s['label'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Suggestion text
                              Text(
                                s['text'] ?? "",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF111B21),
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Suggestion error: $e");
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getLabelColor(String label) {
    switch (label.toLowerCase()) {
      case 'playful':
        return const Color(0xFFE91E63); // Pink
      case 'curious':
        return const Color(0xFF2196F3); // Blue
      case 'simple':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF8696A0); // Grey
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      // Hide keyboard when showing emoji picker
      if (_showEmojiPicker) {
        FocusScope.of(context).unfocus();
      }
    });
  }
}
