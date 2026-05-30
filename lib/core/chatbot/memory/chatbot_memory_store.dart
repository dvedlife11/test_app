import 'package:test_app/core/chatbot/models/chatbot_response_memory.dart';
import 'package:test_app/core/chatbot/models/chatbot_message.dart';
import 'package:test_app/core/models/crm_card.dart';

/// Handles persistence and CRM integration for chatbot
/// Syncs conversation history and behavioral signals to core CRM
class ChatbotMemoryStore {
  final List<ChatbotMessage> conversationHistory;
  final ChatbotResponseMemory responseMemory;
  final DateTime sessionStart;

  ChatbotMemoryStore({
    required this.conversationHistory,
    required this.responseMemory,
    required this.sessionStart,
  });

  factory ChatbotMemoryStore.initialize() => ChatbotMemoryStore(
        conversationHistory: [],
        responseMemory: ChatbotResponseMemory.initialize(),
        sessionStart: DateTime.now(),
      );

  /// Save conversation message to persistent storage
  Future<void> saveMessage(ChatbotMessage message) async {
    // TODO: Implement actual persistent storage (SharedPreferences / local database)
    // For now, just add to in-memory list
    conversationHistory.add(message);
  }

  /// Retrieve conversation history
  Future<List<ChatbotMessage>> getConversationHistory() async {
    // TODO: Load from persistent storage
    return conversationHistory;
  }

  /// Sync chatbot signals to core CRM
  /// Transforms detected behavioral signals into CRM update
  Future<void> syncToCRM({
    required String userID,
    required Map<String, dynamic> detectionSignals,
    required String responseDirection,
  }) async {
    // Build CRM card update
    final crmUpdate = {
      'timestamp': DateTime.now().toIso8601String(),
      'source': 'chatbot_interaction',
      'signals': detectionSignals,
      'direction_given': responseDirection,
      'session_start': sessionStart.toIso8601String(),
      'message_count': conversationHistory.length,
    };

    // TODO: Integrate with actual CRM store
    // Example:
    // await crmStore.updateUserProfile(userID, crmUpdate);
  }

  /// Check for repeated patterns (memory enforcement)
  bool isRepeatingDirection(String newDirection) {
    return responseMemory.isRepeatingDirection(newDirection);
  }

  /// Get rotation anchor (prevent repeated anchors)
  String getNextAnchor() {
    return responseMemory.getNextAnchor();
  }

  /// Clear session data (after session ends)
  void clearSession() {
    // Optionally save to archive before clearing
    // Then clear current session
  }

  /// Export session for analytics
  Future<Map<String, dynamic>> exportSessionAnalytics() async {
    final messageTypes = <String, int>{};

    for (var msg in conversationHistory) {
      final type = msg.messageType ?? 'unknown';
      messageTypes[type] = (messageTypes[type] ?? 0) + 1;
    }

    return {
      'session_start': sessionStart,
      'session_end': DateTime.now(),
      'total_messages': conversationHistory.length,
      'message_types': messageTypes,
      'last_direction': responseMemory.lastDirectionGiven,
      'response_memory': {
        'repeated_trigger_counter': responseMemory.repeatedTriggerCounter,
        'last_anchor': responseMemory.lastAnchorUsed,
      },
    };
  }
}

/// Future CRM sync manager
/// Handles bidirectional sync between chatbot memory and core CRM
class ChatbotCRMSync {
  final String userID;

  ChatbotCRMSync({required this.userID});

  /// Push chatbot signals to CRM
  /// Called after each chatbot interaction
  Future<void> pushSignalsToCRM({
    required Map<String, dynamic> signals,
    required String responseMode,
    required String pressureLevel,
  }) async {
    // TODO: Implement CRM push
    // await _crm.updateBehaviorProfile(userID, {
    //   'last_chatbot_signal': signals,
    //   'last_response_mode': responseMode,
    //   'last_pressure_level': pressureLevel,
    //   'timestamp': DateTime.now(),
    // });
  }

  /// Pull updated user profile from CRM
  /// Called at session start or before response generation
  Future<Map<String, dynamic>> pullProfileFromCRM() async {
    // TODO: Implement CRM pull
    // return await _crm.getUserProfile(userID);
    return {};
  }

  /// Sync override state to CRM
  /// Track when HIGH_REACTIVITY or OUT_OF_SCOPE override triggered
  Future<void> syncOverrideState(String overrideType) async {
    // TODO: Update CRM with override event
    // This helps track when user enters crisis modes
  }
}
