import 'package:test_app/core/chatbot/models/detection_signals.dart';
import 'package:test_app/core/chatbot/models/chatbot_response.dart';

/// Converts detection signals into interpretation results
class InterpretationEngine {
  /// Interpret detection signals into actionable insights
  static InterpretationResult interpret(DetectionSignals signals) {
    // Check for override states first (highest priority)
    final overrideState = _determineOverride(signals);

    // Interpret manipulation intensity
    final manipulationIntensity = _assessManipulationIntensity(signals);

    // Get dominant catch pattern
    final dominantCatch = _identifyDominantCatchPattern(signals);

    // Detect state vs behavior mismatch (TODO: requires dailyQuiz data)
    const stateBehaviorMismatch = false; // placeholder
    const mismatchType = null;

    return InterpretationResult(
      override: overrideState,
      manipulationIntensity: manipulationIntensity,
      dominantCatchPattern: dominantCatch,
      stateBehaviorMismatch: stateBehaviorMismatch,
      mismatchType: mismatchType,
    );
  }

  /// Determine if override state should activate
  static OverrideState _determineOverride(DetectionSignals signals) {
    // Check HIGH_REACTIVITY first (higher priority within overrides)
    if (signals.shouldTriggerHighReactivity()) {
      return OverrideState.highReactivity;
    }

    // Check OUT_OF_SCOPE
    if (signals.shouldTriggerOutOfScope()) {
      return OverrideState.outOfScope;
    }

    return OverrideState.none;
  }

  /// Assess manipulation intensity (LOW, MEDIUM, HIGH)
  static String _assessManipulationIntensity(DetectionSignals signals) {
    int signalCount = 0;

    if (signals.counterManipulationSignal) signalCount++;
    if (signals.affirmationAvoidanceSignal) signalCount++;
    if (signals.lowConfidenceExecutionSignal) signalCount++;
    if (signals.triggerReactionSignal) signalCount++;

    if (signalCount >= 3) {
      return 'HIGH';
    } else if (signalCount >= 2) {
      return 'MEDIUM';
    } else {
      return 'LOW';
    }
  }

  /// Identify dominant catch pattern
  static String? _identifyDominantCatchPattern(DetectionSignals signals) {
    if (signals.catchTypeDistribution.isEmpty) {
      return null;
    }

    return signals.dominantCatchType;
  }
}
