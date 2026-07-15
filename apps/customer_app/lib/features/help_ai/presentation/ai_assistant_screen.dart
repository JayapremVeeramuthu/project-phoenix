import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
        text:
            'Hello! I am your Phoenix AI Assistant. How can I assist you with your home services today?',
        isUser: false),
  ];

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isListening = false;
  bool _isTyping = false;

  final List<String> _suggestions = [
    'Plumbing leak in bathroom',
    'AC compressor noise',
    'Power outlet not working',
    'Book AC service'
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Trigger simulated reply
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      String reply =
          'I have received your request. Let me look up options for you.';
      final lowerText = text.toLowerCase();
      if (lowerText.contains('ac') || lowerText.contains('air conditioner')) {
        reply =
            'I recommend our "AC Installation / Gas Refilling" packages. You can book directly in the booking wizard.';
      } else if (lowerText.contains('leak') ||
          lowerText.contains('pipe') ||
          lowerText.contains('plumbing')) {
        reply =
            'It sounds like a plumbing emergency. You can toggle the Emergency button on checkout for priority dispatch.';
      } else if (lowerText.contains('light') ||
          lowerText.contains('wiring') ||
          lowerText.contains('outlet') ||
          lowerText.contains('power')) {
        reply =
            'We have certified electrical technicians available. Our base rating is 4.8 stars in your area.';
      }

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(text: reply, isUser: false));
      });
      _scrollToBottom();
    });
  }

  void _simulateVoiceListening() async {
    setState(() {
      _isListening = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
    _sendMessage('I have a plumbing leak in my bathroom');
  }

  @override
  Widget build(BuildContext context) {
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phoenix AI Assistant'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(msg.isUser ? 12 : 0),
                          bottomRight: Radius.circular(msg.isUser ? 0 : 12),
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: msg.isUser ? Colors.white : Colors.black87,
                          fontSize: isSeniorMode ? 18 : 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text('AI is typing...',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
            // Suggestion chips
            if (!_isListening)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionChip(
                        label: Text(suggestion),
                        onPressed: () => _sendMessage(suggestion),
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            if (_isListening)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.orange),
                    SizedBox(width: 12),
                    Text(
                      'Listening to Voice Command...',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ),

            // Input panel
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.teal),
                    onPressed: _isListening ? null : _simulateVoiceListening,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(fontSize: isSeniorMode ? 18 : 15),
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.teal),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
