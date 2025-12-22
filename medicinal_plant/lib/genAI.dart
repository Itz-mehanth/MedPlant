import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicinal_plant/home_page.dart';

import 'package:medicinal_plant/keys.dart';



class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage>
    with TickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocus = FocusNode();
  
  bool _isTyping = false;
  bool _hasError = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _addWelcomeMessage();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _addWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add({
          'text': 'Hello! I\'m your AI assistant specializing in medicinal plants. Ask me anything about plant properties, uses, identification, or any plant-related questions!',
          'isUser': false,
          'timestamp': DateTime.now(),
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
        });
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  /// Fetches all plant details from Firestore to build context for the AI.
  Future<String> _fetchPlantContext() async {
    try {
      final QuerySnapshot plantDocs =
          await FirebaseFirestore.instance.collection('plant_details').get();

      if (plantDocs.docs.isEmpty) {
        return "No plant information is available in the database.";
      }

      final contextBuffer = StringBuffer();
      for (var doc in plantDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final commonName = data['Common Name'] ?? 'N/A';
        final scientificName = data['Scientific Name'] ?? 'N/A';
        final description = data['Description'] ?? 'No description available.';
        contextBuffer.writeln(
            "Plant: $commonName (Scientific Name: $scientificName). Description: $description");
      }
      return contextBuffer.toString();
    } catch (e) {
      print("Error fetching plant context from Firestore: $e");
      return "Error fetching plant data.";
    }
  }

  /// Sends a query directly to the Gemini API with context from Firestore.
  Future<String> queryGeminiModel(String query) async {
    final plantContext = await _fetchPlantContext();

    final String prompt =
        "You are a helpful expert on medicinal plants. "
        "Based on the following information from the database, answer the user's query. "
        "If the query is not related to plants, politely decline to answer and guide them back to plant-related topics.\n\n"
        "Database Context:\n$plantContext\n\n"
        "User Query: $query\n\n"
        "Please provide a helpful, accurate, and concise response. Use bullet points or structured formatting when appropriate.";

    try {
      final response = await http.post(
        Uri.parse(
          
            'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=${Keys.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print("Error from Gemini API: ${response.body}");
        return "I'm experiencing technical difficulties right now. Please try again in a moment.";
      }
    } catch (e) {
      print("Error sending request to Gemini: $e");
      return "I'm having trouble connecting right now. Please check your internet connection and try again.";
    }
  }

  /// Handle user input and AI response
  void _sendMessage() async {
    if (_queryController.text.trim().isEmpty) return;

    final userMessage = _queryController.text.trim();
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    _queryController.clear();

    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
        'id': messageId,
      });
      _isTyping = true;
      _hasError = false;
    });

    _scrollToBottom();

    try {
      final aiResponse = await queryGeminiModel(userMessage);
      
      setState(() {
        _messages.add({
          'text': aiResponse,
          'isUser': false,
          'timestamp': DateTime.now(),
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
        });
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'text': 'Sorry, I encountered an error while processing your request. Please try again.',
          'isUser': false,
          'timestamp': DateTime.now(),
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'isError': true,
        });
        _isTyping = false;
        _hasError = true;
      });
    }

    _scrollToBottom();
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

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState(colorScheme) : _buildMessagesList(colorScheme),
          ),
          _buildTypingIndicator(colorScheme),
          _buildInputSection(colorScheme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: colorScheme.onSurface,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plant AI Assistant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'Online • Ready to help',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromARGB(255, 207, 207, 207),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => _showChatOptions(colorScheme),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.chat_rounded,
                    size: 60,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Start a conversation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ask me anything about medicinal plants,\ntheir properties, uses, or identification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSuggestionChip('What plants help with headaches?', colorScheme),
                    _buildSuggestionChip('Tell me about Aloe Vera', colorScheme),
                    _buildSuggestionChip('Identify a plant by description', colorScheme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        _queryController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(ColorScheme colorScheme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, colorScheme);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, ColorScheme colorScheme) {
    final isUser = message['isUser'] ?? false;
    final isError = message['isError'] ?? false;
    final timestamp = message['timestamp'] as DateTime?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(colorScheme, isUser),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser 
                  ? AppColors.primary
                  : isError 
                    ? colorScheme.errorContainer
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onLongPress: () => _copyMessage(message['text']),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          AnimatedText(
                            text: message['text'],
                            style: TextStyle(
                              color: isError 
                                ? colorScheme.onErrorContainer
                                : colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          )
                        else
                          Text(
                            message['text'],
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        if (timestamp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(timestamp),
                            style: TextStyle(
                              color: isUser 
                                ? colorScheme.onPrimary.withOpacity(0.7)
                                : colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(colorScheme, isUser),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        color: isUser ? colorScheme.onPrimary : AppColors.primary,
        size: 18,
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    if (!_isTyping) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildAvatar(colorScheme, false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(colorScheme, 0),
                const SizedBox(width: 4),
                _buildTypingDot(colorScheme, 1),
                const SizedBox(width: 4),
                _buildTypingDot(colorScheme, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(ColorScheme colorScheme, int index) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final animationValue = (_fadeController.value + index * 0.3) % 1.0;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.3 + animationValue * 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildInputSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _queryController,
                  focusNode: _textFieldFocus,
                  decoration: InputDecoration(
                    hintText: 'Ask me about medicinal plants...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _isTyping ? null : _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.send_rounded,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildOptionItem(
                colorScheme,
                Icons.delete_outline_rounded,
                'Clear Chat',
                'Remove all messages',
                () {
                  setState(() {
                    _messages.clear();
                    _addWelcomeMessage();
                  });
                  Navigator.pop(context);
                },
              ),
              _buildOptionItem(
                colorScheme,
                Icons.info_outline_rounded,
                'About AI Assistant',
                'Learn more about this feature',
                () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Plant AI Assistant',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This AI assistant is specialized in medicinal plants and can help you with:\n\n• Plant identification and properties\n• Medicinal uses and benefits\n• Scientific information\n• General plant care questions\n\nPowered by Google Gemini AI',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Got it',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Enhanced Animated Text Widget for AI response
class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const AnimatedText({super.key, required this.text, required this.style});

  @override
  _AnimatedTextState createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.text.length * 15), // Slightly faster
      vsync: this,
    );
    _charCount = IntTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _controller.duration = Duration(milliseconds: widget.text.length * 15);
      _charCount = IntTween(begin: 0, end: widget.text.length).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final visibleText = widget.text.substring(0, _charCount.value);
        return Text(visibleText, style: widget.style);
      },
    );
  }
}