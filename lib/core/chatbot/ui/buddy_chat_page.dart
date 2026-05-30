
import 'package:flutter/material.dart';
import 'package:test_app/core/chatbot/johnson_chatbot_engine.dart';
import 'package:test_app/core/chatbot/models/chatbot_state.dart';
import 'package:test_app/core/chatbot/ui/buddy_chatbot_widget.dart';

/// Full-screen chatbot page
class BuddyChatPage extends StatefulWidget {
  final String? initialMessage;

  const BuddyChatPage({
    Key? key,
    this.initialMessage,
  }) : super(key: key);

  @override
  State<BuddyChatPage> createState() => _BuddyChatPageState();
}

class _BuddyChatPageState extends State<BuddyChatPage> {
  late JohnsonChatbotEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = JohnsonChatbotEngine();

    // TODO: Update with real state from core
    // For now, use defaults
    _engine.updateState(ChatbotState.fromDefaults());

    // If initial message provided, send it
    if (widget.initialMessage != null) {
      Future.delayed(Duration(milliseconds: 500), () {
        _engine.processMessage(widget.initialMessage!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BUDDY Chat'),
        elevation: 0,
      ),
      body: BuddyChatbotWidget(
        engine: _engine,
        mode: 'chat',
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

/// Mini chatbot widget for embedding in other pages
class BuddyMiniChat extends StatefulWidget {
  final double height;
  final bool showBoost;

  const BuddyMiniChat({
    Key? key,
    this.height = 300,
    this.showBoost = true,
  }) : super(key: key);

  @override
  State<BuddyMiniChat> createState() => _BuddyMiniChatState();
}

class _BuddyMiniChatState extends State<BuddyMiniChat> {
  late JohnsonChatbotEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = JohnsonChatbotEngine();
    _engine.updateState(ChatbotState.fromDefaults());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BuddyChatbotWidget(
          engine: _engine,
          mode: 'chat',
        ),
      ),
    );
  }
}
