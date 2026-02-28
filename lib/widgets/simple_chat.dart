import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SimpleChat extends StatefulWidget {
  final List<types.Message> messages;
  final Function(types.PartialText) onSendPressed;
  final types.User user;
  final bool isTyping;
  final String? hintText;
  final Widget? inputHeader;
  final TextEditingController? controller;
  final VoidCallback? onVoicePressed;
  final bool isListening;
  final Widget? leadingInputWidget;
  final VoidCallback? onSuggestionRequested;
  final VoidCallback? onEmojiPressed;
  final bool assistantMode;
  final bool reverseAlignment; // Keeping for compatibility, but deprecated

  const SimpleChat({
    super.key,
    required this.messages,
    required this.onSendPressed,
    required this.user,
    this.isTyping = false,
    this.hintText,
    this.inputHeader,
    this.controller,
    this.onVoicePressed,
    this.isListening = false,
    this.leadingInputWidget,
    this.onSuggestionRequested,
    this.onEmojiPressed,
    this.assistantMode = false,
    this.reverseAlignment = false,
  });

  @override
  State<SimpleChat> createState() => _SimpleChatState();
}

class _SimpleChatState extends State<SimpleChat> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.trim().isNotEmpty;
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    }
  }

  @override
  void didUpdateWidget(covariant SimpleChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      _controller.removeListener(_onTextChanged);
      _controller = widget.controller!;
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleSend() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSendPressed(types.PartialText(text: _controller.text.trim()));
      _controller.clear();
    }
  }

  void _handleNewline() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, '\n');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + 1),
      );
    } else {
      _controller.text += '\n';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            // WhatsApp-style background with our warm color tint
            decoration: BoxDecoration(
              color: const Color(0xFFFAE4D7), // Our warm peach background
              image: DecorationImage(
                image: AssetImage('assets/chatbg.jpg'),
                fit: BoxFit.cover,
                opacity: 0.4,
                colorFilter: ColorFilter.mode(
                  const Color(0xFFFAE4D7).withValues(alpha: 0.6),
                  BlendMode.overlay,
                ),
              ),
            ),
            child: widget.messages.isEmpty
                ? Center(
                    child: Text(
                      "No messages yet.",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF667781),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    reverse: true,
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
        ),
        if (widget.isTyping)
          Container(
            color: const Color(0xFFFAE4D7), // Match our warm background
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF667781),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "typing...",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF667781),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageBubble(types.Message message) {
    bool isMe = message.author.id == widget.user.id;

    // Assistant Mode Logic: User(Right/Green), AI(Left/White).
    final bool useGreen = widget.assistantMode ? !isMe : isMe;

    // Standard Alignment unless reverseAlignment legacy flag is set (and assistantMode is OFF)
    if (widget.reverseAlignment && !widget.assistantMode) {
      isMe = !isMe;
    }
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;

    final text = (message is types.TextMessage) ? message.text : "";
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      message.createdAt ?? 0,
    );
    final timeStr = DateFormat('h:mm a').format(timestamp);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: useGreen
              ? const Color(0xFFD9FDD3) // WhatsApp green for user
              : Colors.white, // White for AI
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: (alignment == Alignment.centerRight)
                ? const Radius.circular(8)
                : Radius.zero,
            bottomRight: (alignment == Alignment.centerRight)
                ? Radius.zero
                : const Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                color: const Color(0xFF111B21),
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                height: 1.35,
                textStyle: const TextStyle(
                  fontFamilyFallback: [
                    'Apple Color Emoji',
                    'Segoe UI Emoji',
                    'Segoe UI Symbol',
                    'Noto Color Emoji',
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF667781),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                // Show ticks if useGreen (Me bubble)
                if (useGreen) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all,
                    size: 16,
                    color: Color(0xFF53BDEB), // WhatsApp blue ticks
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: const Color(0xFFF0F2F5), // WhatsApp input area background
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.inputHeader != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: widget.inputHeader!,
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Main Pill Container (White)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Emoji button
                        IconButton(
                          icon: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: Color(0xFF8696A0),
                            size: 26,
                          ),
                          onPressed: widget.onEmojiPressed,
                          padding: const EdgeInsets.all(8),
                        ),
                        // Text input - takes maximum available space
                        Expanded(
                          child: CallbackShortcuts(
                            bindings: {
                              const SingleActivator(LogicalKeyboardKey.enter):
                                  _handleSend,
                              const SingleActivator(
                                LogicalKeyboardKey.enter,
                                control: true,
                              ): _handleNewline,
                            },
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: "Message",
                                hintStyle: TextStyle(
                                  color: Color(0xFF8696A0),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF111B21),
                                height: 1.4,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 6,
                            ),
                          ),
                        ),
                        // AI Suggestions button (sparkles)
                        if (widget.onSuggestionRequested != null)
                          IconButton(
                            icon: Icon(
                              Icons.auto_awesome,
                              color: const Color(0xFF8696A0),
                              size: 22,
                            ),
                            onPressed: widget.onSuggestionRequested,
                            padding: const EdgeInsets.all(8),
                            tooltip: 'Get AI Suggestions',
                          ),
                        // Attachment icon
                        IconButton(
                          icon: const Icon(
                            Icons.attach_file,
                            color: Color(0xFF8696A0),
                            size: 24,
                          ),
                          onPressed: () {},
                          padding: const EdgeInsets.all(8),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Floating Mic/Send Button
                GestureDetector(
                  onTap: () {
                    if (_controller.text.trim().isNotEmpty) {
                      _handleSend();
                    } else if (widget.onVoicePressed != null) {
                      widget.onVoicePressed!();
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884), // WhatsApp green
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _hasText
                          ? Icons.send
                          : (widget.isListening ? Icons.stop : Icons.mic),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
