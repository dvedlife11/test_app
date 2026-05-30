
/// Single message in chatbot conversation
class ChatbotMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final String? messageType; // 'boost', 'conversational', 'coaching_redirect'
  final Map<String, dynamic>? metadata; // for tracking signal sources

  ChatbotMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.messageType,
    this.metadata,
  });

  factory ChatbotMessage.user({
    required String content,
    String? id,
  }) => ChatbotMessage(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    content: content,
    isFromUser: true,
    timestamp: DateTime.now(),
    messageType: 'user_input',
  );

  factory ChatbotMessage.system({
    required String content,
    String? messageType,
    Map<String, dynamic>? metadata,
    String? id,
  }) => ChatbotMessage(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    content: content,
    isFromUser: false,
    timestamp: DateTime.now(),
    messageType: messageType,
    metadata: metadata,
  );
}

/// Conversation history tracker
class ChatbotConversation {
  final List<ChatbotMessage> messages;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;

  ChatbotConversation({
    required this.messages,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messageCount,
  });

  factory ChatbotConversation.empty() => ChatbotConversation(
    messages: [],
    createdAt: DateTime.now(),
    lastMessageAt: DateTime.now(),
    messageCount: 0,
  );

  ChatbotConversation addMessage(ChatbotMessage message) {
    return ChatbotConversation(
      messages: [...messages, message],
      createdAt: createdAt,
      lastMessageAt: message.timestamp,
      messageCount: messages.length + 1,
    );
  }

  /// Get last 10 messages for context
  List<ChatbotMessage> getRecentContext() {
    final start = (messages.length - 10).clamp(0, messages.length);
    return messages.sublist(start);
  }
}

/// Boost usage tracking
class BoostUsageMetrics {
  final int totalBoostsUsed;
  final List<DateTime> boostTimestamps;
  final Map<String, int> boostTypeUsage; // boost type -> count
  final DateTime? lastBoostAt;
  final int boostsToday;
  final bool showingBoostDependency;

  BoostUsageMetrics({
    required this.totalBoostsUsed,
    required this.boostTimestamps,
    required this.boostTypeUsage,
    required this.lastBoostAt,
    required this.boostsToday,
    required this.showingBoostDependency,
  });

  factory BoostUsageMetrics.empty() => BoostUsageMetrics(
    totalBoostsUsed: 0,
    boostTimestamps: [],
    boostTypeUsage: {},
    lastBoostAt: null,
    boostsToday: 0,
    showingBoostDependency: false,
  );

  /// Update with new boost usage
  BoostUsageMetrics recordBoost(String boostType) {
    final now = DateTime.now();
    final todayBoosts = boostTimestamps
        .where((t) => t.day == now.day && t.month == now.month && t.year == now.year)
        .length;

    final newUsage = Map<String, int>.from(boostTypeUsage);
    newUsage[boostType] = (newUsage[boostType] ?? 0) + 1;

    return BoostUsageMetrics(
      totalBoostsUsed: totalBoostsUsed + 1,
      boostTimestamps: [...boostTimestamps, now],
      boostTypeUsage: newUsage,
      lastBoostAt: now,
      boostsToday: todayBoosts + 1,
      showingBoostDependency: (todayBoosts + 1) > 5, // flag if too frequent
    );
  }
}
