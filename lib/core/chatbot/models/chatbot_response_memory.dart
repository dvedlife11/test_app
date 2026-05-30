
/// Memory of recent responses to avoid repetition
class ChatbotResponseMemory {
  final List<String> last3DaysSummary; // tone/direction delivered
  final int repeatedTriggerCounter;    // how many times same trigger addressed
  final String? lastAnchorUsed;        // last anchor message
  final String? lastDirectionGiven;    // last action given
  final List<String> anchorRotation;   // pool of anchors to rotate through

  ChatbotResponseMemory({
    required this.last3DaysSummary,
    required this.repeatedTriggerCounter,
    required this.lastAnchorUsed,
    required this.lastDirectionGiven,
    required this.anchorRotation,
  });

  factory ChatbotResponseMemory.initialize() => ChatbotResponseMemory(
    last3DaysSummary: [],
    repeatedTriggerCounter: 0,
    lastAnchorUsed: null,
    lastDirectionGiven: null,
    anchorRotation: [
      "it's not the end",
      "nothing broke",
      "you're still on track",
      "this doesn't change anything",
      "you didn't lose it",
      "reset and continue",
      "one moment doesn't define you",
      "you know how to recover",
    ],
  );

  /// Record direction we gave
  ChatbotResponseMemory recordDirection(String direction) {
    return ChatbotResponseMemory(
      last3DaysSummary: last3DaysSummary,
      repeatedTriggerCounter: repeatedTriggerCounter,
      lastAnchorUsed: lastAnchorUsed,
      lastDirectionGiven: direction,
      anchorRotation: anchorRotation,
    );
  }

  /// Record anchor used
  ChatbotResponseMemory recordAnchor(String anchor) {
    return ChatbotResponseMemory(
      last3DaysSummary: last3DaysSummary,
      repeatedTriggerCounter: repeatedTriggerCounter,
      lastAnchorUsed: anchor,
      lastDirectionGiven: lastDirectionGiven,
      anchorRotation: anchorRotation,
    );
  }

  /// Get next anchor (rotation-based)
  String getNextAnchor() {
    if (anchorRotation.isEmpty) {
      return "keep going";
    }

    // Find index of last used anchor
    final lastIndex = anchorRotation.indexOf(lastAnchorUsed ?? '');
    final nextIndex = (lastIndex + 1) % anchorRotation.length;

    return anchorRotation[nextIndex];
  }

  /// Check if we're repeating ourselves (escalate if so)
  bool isRepeatingDirection(String newDirection) {
    return newDirection == lastDirectionGiven && repeatedTriggerCounter > 0;
  }

  /// Increment counter for repeated scenarios
  ChatbotResponseMemory incrementRepeatedTrigger() {
    return ChatbotResponseMemory(
      last3DaysSummary: last3DaysSummary,
      repeatedTriggerCounter: repeatedTriggerCounter + 1,
      lastAnchorUsed: lastAnchorUsed,
      lastDirectionGiven: lastDirectionGiven,
      anchorRotation: anchorRotation,
    );
  }

  /// Reset counter (new scenario)
  ChatbotResponseMemory resetRepeatedTrigger() {
    return ChatbotResponseMemory(
      last3DaysSummary: last3DaysSummary,
      repeatedTriggerCounter: 0,
      lastAnchorUsed: lastAnchorUsed,
      lastDirectionGiven: lastDirectionGiven,
      anchorRotation: anchorRotation,
    );
  }
}
