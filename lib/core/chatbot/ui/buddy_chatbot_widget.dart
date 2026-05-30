
import 'package:flutter/material.dart';
import 'package:test_app/core/chatbot/johnson_chatbot_engine.dart';
import 'package:test_app/core/chatbot/models/chatbot_message.dart';

/// BUDDY Chatbot UI Widget
/// Displays conversation and boost button
/// Protected against misuse (catch/daily/coaching boundaries)
class BuddyChatbotWidget extends StatefulWidget {
  final JohnsonChatbotEngine engine;
  final String mode; // 'catch', 'daily', 'coaching', 'chat'
  final VoidCallback? onClose;

  const BuddyChatbotWidget({
    Key? key,
    required this.engine,
    required this.mode,
    this.onClose,
  }) : super(key: key);

  @override
  State<BuddyChatbotWidget> createState() => _BuddyChatbotWidgetState();
}

class _BuddyChatbotWidgetState extends State<BuddyChatbotWidget> {
  late TextEditingController _inputController;
  late ScrollController _scrollController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _inputController.text.trim();
    if (message.isEmpty) return;

    // Clear input
    _inputController.clear();

    // Check mode protection
    if (!_isModeAllowed(message)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not available in this mode')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await widget.engine.processMessage(message);
      
      // Scroll to bottom
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _triggerBoost() async {
    // Trigger boost without message input
    final response = await widget.engine.processMessage('[BOOST]');
    
    if (response.boostMessage != null) {
      // Show boost message in dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('BOOST'),
          content: Text(response.boostMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }

  bool _isModeAllowed(String message) {
    switch (widget.mode) {
      case 'catch':
        // Can't do analysis in catch mode
        if (message.toLowerCase().contains('why') ||
            message.toLowerCase().contains('analysis')) {
          return false;
        }
        return true;

      case 'daily':
        // Can't do long emotional dumps in daily
        if (message.length > 500) {
          return false;
        }
        return true;

      case 'coaching':
        // Can't do real-time interruption in coaching
        return true;

      case 'chat':
        // Full access
        return true;

      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.engine.getConversation();

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BUDDY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  onPressed: widget.onClose,
                ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: conversation.messages.length,
            itemBuilder: (context, index) {
              final message = conversation.messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),

        // Input area
        Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              // Boost button
              if (widget.mode == 'chat')
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _triggerBoost,
                    icon: Icon(Icons.flash_on),
                    label: Text('BOOST'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),

              // Message input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Message BUDDY...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatbotMessage message) {
    return Align(
      alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: message.isFromUser
              ? Colors.blue.shade600
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isFromUser ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
