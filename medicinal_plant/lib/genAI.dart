import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

final String gemini_API_KEY = dotenv.env['GEMINI_API_KEY'] ?? 'NO_API_KEY';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  /// Fetches all plant details from Firestore to build context for the AI.
  Future<String> _fetchPlantContext() async {
    try {
      final QuerySnapshot plantDocs =
      await FirebaseFirestore.instance.collection('plant_details').get();

      if (plantDocs.docs.isEmpty) {
        return "No plant information is available in the database.";
      }

      // Format the documents into a string context.
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
        "If the query is not related to plants, politely decline to answer.\n\n"
        "Database Context:\n$plantContext\n\n"
        "User Query: $query";

    try {
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$gemini_API_KEY'),
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
        // Safely access the generated text.
        return responseData['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print("Error from Gemini API: ${response.body}");
        return "Error: Unable to fetch response. Code: ${response.statusCode}";
      }
    } catch (e) {
      print("Error sending request to Gemini: $e");
      return "Error: $e";
    }
  }

  /// Handle user input and AI response
  void _sendMessage() async {
    if (_queryController.text.trim().isEmpty) return;

    final userMessage = _queryController.text.trim();
    _queryController.clear();

    setState(() {
      _messages.add({'text': userMessage, 'isUser': true});
      _isTyping = true;
    });

    final aiResponse = await queryGeminiModel(userMessage);

    setState(() {
      _messages.add({'text': aiResponse, 'isUser': false});
      _isTyping = false;
    });
  }

  /// Build a single chat bubble
  Widget _buildChatBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'];
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const Row(
                mainAxisSize: MainAxisSize.min, // Important for layout
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/icons/google.png'),
                    radius: 12,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            if (isUser)
              const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'You',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/userIcon.jpg'),
                    radius: 12,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (!isUser)
              AnimatedText(
                text: message['text'],
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            if (isUser)
              Text(
                message['text'],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chatbot'),
        backgroundColor: const Color.fromARGB(255, 68, 255, 0),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Show latest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_messages.reversed.toList()[index]);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 8),
                  Text('Fetching results...'),
                ],
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated Text Widget for AI response
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
      duration: Duration(milliseconds: widget.text.length * 20),
      vsync: this,
    );
    _charCount = IntTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _controller.duration = Duration(milliseconds: widget.text.length * 20);
      _charCount = IntTween(begin: 0, end: widget.text.length).animate(
        CurvedAnimation(parent: _controller, curve: Curves.linear),
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