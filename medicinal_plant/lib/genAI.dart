import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

String ngrokUrl = 'no available';

class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;


  @override
  void initState() {
    super.initState();
    _fetchNgrokUrl();
  }

  Future<void> _fetchNgrokUrl() async {
    try {
      // Access FirebaseRemoteConfig instance
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

      // Activate the fetched config
      await remoteConfig.fetchAndActivate();

      // Retrieve the ngrok URL from the remote config
      String ngrokUrl = remoteConfig.getString('ngrok_url');
      print(ngrokUrl + " is the server");

      setState(() {
        ngrokUrl = ngrokUrl;
      });
    } catch (e) {
      print("Error fetching remote config: $e");
      setState(() {
        ngrokUrl = "Error fetching URL";
      });
    }
  }

  /// Function to send a query to the backend
  Future<String> queryBackendModel(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$ngrokUrl/get_plant_info'), // Update with your backend URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['answer'];
      } else {
        return "Error: Unable to fetch response. Code: ${response.statusCode}";
      }
    } catch (e) {
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

    final aiResponse = await queryBackendModel(userMessage);

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
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/icons/google.png'),
                    radius: 12,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            if (isUser)
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'You',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_messages[index]);
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

  AnimatedText({required this.text, required this.style});

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
