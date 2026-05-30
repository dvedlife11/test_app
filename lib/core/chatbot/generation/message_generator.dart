import 'package:test_app/core/chatbot/models/chatbot_state.dart';
import 'package:test_app/core/chatbot/models/chatbot_response.dart';

/// Generates messages based on state, mode, and pressure
class MessageGenerator {
  /// Generate base response ground truth (execution / behavior reality)
  static String generateGroundTruth(ChatbotState state, ResponseMode mode) {
    final executionStatus = state.executionScore > 70 ? "on track" : "behind";
    final pressureStatus = state.instabilityScore > 50 ? "unstable" : "stable";

    return "You're $executionStatus. Your behavior is $pressureStatus.";
  }

  /// Generate movement assessment (forward / stagnant / slipping)
  static String generateMovement(ChatbotState state) {
    if (state.executionScore > 80 && state.instabilityScore < 30) {
      return "forward";
    } else if (state.executionScore < 50 || state.instabilityScore > 70) {
      return "slipping";
    } else {
      return "stagnant";
    }
  }

  /// Generate direction (action to take)
  static String generateDirection(
    ChatbotState state,
    ResponseMode mode,
    String movement,
  ) {
    switch (mode) {
      case ResponseMode.push:
        if (movement == "slipping") {
          return "Stop analyzing. Do 3 reps right now.";
        }
        return "Expand: add 1 more counter or 1 more rep per session.";

      case ResponseMode.stabilize:
        return "Lock this in: same affirmations, same routine, no changes.";

      case ResponseMode.callOut:
        if (state.catchCount > 0) {
          return "You know what to do. No excuse.";
        }
        return "Reset and execute. No modifications.";
    }
  }

  /// Map state to initial boost message type (before override)
  static BoostMessageType stateToBoostType(ChatbotStateType state) {
    switch (state) {
      case ChatbotStateType.stableExecution:
        return BoostMessageType.momentum;

      case ChatbotStateType.lowExecution:
        return BoostMessageType.push;

      case ChatbotStateType.instability:
        return BoostMessageType.callOutLight;

      case ChatbotStateType.triggered:
        return BoostMessageType.reassurance;

      case ChatbotStateType.avoidance:
        return BoostMessageType.callOutLight;

      case ChatbotStateType.overfocus:
        return BoostMessageType.push;
    }
  }

  /// Generate boost message from type
  static String generateBoostMessage(
    BoostMessageType type,
    ChatbotState state,
  ) {
    switch (type) {
      case BoostMessageType.push:
        return "Stop thinking. Do the reps.";

      case BoostMessageType.reassurance:
        return "You're not off. Stay in it.";

      case BoostMessageType.callOutLight:
        return "You already know what to do.";

      case BoostMessageType.momentum:
        return "Keep going. Don't break the chain.";

      case BoostMessageType.identity:
        return "You're not the version that quits now.";

      case BoostMessageType.deEscalate:
        return "Pause. You're reacting. Pick one and continue.";

      case BoostMessageType.simplify:
        return "Drop everything else. Just the umbrella today.";
    }
  }

  /// Map pressure level to response tone
  static String pressureLevelToTone(PressureLevel pressure) {
    switch (pressure) {
      case PressureLevel.low:
        return "guide";
      case PressureLevel.medium:
        return "push";
      case PressureLevel.high:
        return "call_out";
    }
  }

  /// Determine pressure level from state
  static PressureLevel assessPressureLevel(
    ChatbotState state,
    String movement,
  ) {
    // High pressure if slipping or many catch events
    if (movement == "slipping" || state.catchCount > 2) {
      return PressureLevel.high;
    }

    // Medium pressure if stagnant
    if (movement == "stagnant" || state.executionScore < 60) {
      return PressureLevel.medium;
    }

    // Low pressure if stable forward
    return PressureLevel.low;
  }

  /// Generate response mode based on state
  static ResponseMode determineMode(ChatbotState state, String movement) {
    if (movement == "forward" && state.instabilityScore < 40) {
      return ResponseMode.push; // expand ceiling
    } else if (movement == "slipping") {
      return ResponseMode.callOut; // correction needed
    } else {
      return ResponseMode.stabilize; // hold steady
    }
  }
}
