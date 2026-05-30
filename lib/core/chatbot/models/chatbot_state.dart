
/// Core state types for chatbot behavioral assessment
enum ChatbotStateType {
  stableExecution,    // targets mostly met, low instability
  lowExecution,       // counters/audio behind
  instability,        // high InstabilityScore
  triggered,          // recent catch (mental diet / dwelling)
  avoidance,          // low usage, no execution
  overfocus,          // one counter high, others neglected
}

/// Current assessment of user's state
class ChatbotState {
  final ChatbotStateType type;
  final double executionScore;      // 0-100
  final double instabilityScore;    // 0-100
  final double disciplineScore;     // 0-100
  final int catchCount;             // today
  final List<String> recentCatches; // types: TRIGGER_3D, MENTAL_DIET, DWELLING
  final DateTime assessedAt;
  
  ChatbotState({
    required this.type,
    required this.executionScore,
    required this.instabilityScore,
    required this.disciplineScore,
    required this.catchCount,
    required this.recentCatches,
    required this.assessedAt,
  });

  factory ChatbotState.fromDefaults() => ChatbotState(
    type: ChatbotStateType.stableExecution,
    executionScore: 75.0,
    instabilityScore: 20.0,
    disciplineScore: 65.0,
    catchCount: 0,
    recentCatches: [],
    assessedAt: DateTime.now(),
  );
}
