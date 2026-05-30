import 'package:test_app/core/chatbot/models/chatbot_response.dart';
import 'package:test_app/core/chatbot/models/detection_signals.dart';
import 'package:test_app/core/chatbot/models/chatbot_state.dart';

/// Handles override states (HIGH_REACTIVITY, OUT_OF_SCOPE)
class OverrideSystem {
  /// Apply override logic to base response mode
  static void applyOverride({
    required OverrideState override,
    required ChatbotState state,
    required DetectionSignals signals,
    required Function(ResponseMode, PressureLevel, BoostMessageType?, String?)
        onOverride,
  }) {
    switch (override) {
      case OverrideState.highReactivity:
        _applyHighReactivityOverride(state, signals, onOverride);
        break;

      case OverrideState.outOfScope:
        _applyOutOfScopeOverride(state, signals, onOverride);
        break;

      case OverrideState.none:
        break;
    }
  }

  /// HIGH_REACTIVITY override: de-escalate + refocus
  /// Triggered when user is reacting (not executing)
  static void _applyHighReactivityOverride(
    ChatbotState state,
    DetectionSignals signals,
    Function(ResponseMode, PressureLevel, BoostMessageType?, String?)
        onOverride,
  ) {
    // Mode: stabilize (lock behavior, reduce chaos)
    final mode = ResponseMode.stabilize;

    // Pressure: medium (firm but not harsh, de-escalating)
    final pressure = PressureLevel.medium;

    // Boost type: de-escalate
    final boostType = BoostMessageType.deEscalate;

    // Messages rotate through these themes:
    final messages = [
      "Pause. You're reacting. Pick one and continue.",
      "Nothing needs to change right now. Stay with what you chose.",
      "You're overcorrecting. Stop adjusting. Start doing.",
      "This is not the moment to rethink. It's the moment to execute.",
      "Calm down. Go back to the reps.",
    ];

    final message = messages[state.catchCount % messages.length];

    onOverride(mode, pressure, boostType, message);
  }

  /// OUT_OF_SCOPE override: simplify + restore execution
  /// Triggered when fragmented, chaotic, low execution
  static void _applyOutOfScopeOverride(
    ChatbotState state,
    DetectionSignals signals,
    Function(ResponseMode, PressureLevel, BoostMessageType?, String?)
        onOverride,
  ) {
    // Mode: push (force back to basics)
    final mode = ResponseMode.push;

    // Pressure: high (firm correction needed)
    final pressure = PressureLevel.high;

    // Boost type: simplify
    final boostType = BoostMessageType.simplify;

    // Messages for simplification:
    final messages = [
      "Too many changes. Go back to your umbrella and stay there today.",
      "You're scattered. One focus. Use the umbrella. That's it.",
      "Drop everything else today. Just run the umbrella.",
      "You lost direction. Simplify. One line. Repeat it.",
      "Stop switching. Use the umbrella and stabilize.",
    ];

    final message = messages[state.catchCount % messages.length];

    onOverride(mode, pressure, boostType, message);
  }

  /// Get override-specific pressure level
  static PressureLevel getPressureForOverride(OverrideState override,
      {required double executionScore}) {
    switch (override) {
      case OverrideState.highReactivity:
        return PressureLevel.medium; // de-escalate
      case OverrideState.outOfScope:
        return executionScore < 30 ? PressureLevel.high : PressureLevel.medium;
      case OverrideState.none:
        return PressureLevel.low;
    }
  }

  /// Check if override should block certain features
  static bool shouldBlockFeature(OverrideState override, String featureName) {
    switch (override) {
      case OverrideState.highReactivity:
        // Block: analysis, advice, long input
        return ['analysis', 'coaching', 'detailed_advice']
            .contains(featureName);

      case OverrideState.outOfScope:
        // Block: emotional dumps, multiple options
        return ['emotional_support', 'multiple_paths', 'detailed_analysis']
            .contains(featureName);

      case OverrideState.none:
        return false;
    }
  }
}
