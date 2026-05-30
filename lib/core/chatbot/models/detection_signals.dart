/// Detection signals extracted from user behavior
class DetectionSignals {
  // Execution signals
  final bool counterManipulationSignal;
  final bool affirmationAvoidanceSignal;
  final bool lowConfidenceExecutionSignal;

  // Trigger/reaction signals
  final bool triggerReactionSignal;

  // Counter distribution
  final bool overfocusPattern;
  final bool neglectedCounterPattern;

  // Catch signals
  final int catchCount;
  final Map<String, int>
      catchTypeDistribution; // TRIGGER_3D, MENTAL_DIET, DWELLING
  final String? dominantCatchType;

  // System state
  final bool fragmentationPattern;
  final bool pressureAvoidancePattern;

  // High reactivity indicators
  final int recentAffirmationEdits;
  final bool recentCatchActivity;
  final bool possibleCoachingVenting;
  final bool lowExecutionLevel;

  DetectionSignals({
    required this.counterManipulationSignal,
    required this.affirmationAvoidanceSignal,
    required this.lowConfidenceExecutionSignal,
    required this.triggerReactionSignal,
    required this.overfocusPattern,
    required this.neglectedCounterPattern,
    required this.catchCount,
    required this.catchTypeDistribution,
    required this.dominantCatchType,
    required this.fragmentationPattern,
    required this.pressureAvoidancePattern,
    required this.recentAffirmationEdits,
    required this.recentCatchActivity,
    required this.possibleCoachingVenting,
    required this.lowExecutionLevel,
  });

  factory DetectionSignals.empty() => DetectionSignals(
        counterManipulationSignal: false,
        affirmationAvoidanceSignal: false,
        lowConfidenceExecutionSignal: false,
        triggerReactionSignal: false,
        overfocusPattern: false,
        neglectedCounterPattern: false,
        catchCount: 0,
        catchTypeDistribution: {},
        dominantCatchType: null,
        fragmentationPattern: false,
        pressureAvoidancePattern: false,
        recentAffirmationEdits: 0,
        recentCatchActivity: false,
        possibleCoachingVenting: false,
        lowExecutionLevel: false,
      );

  /// Check if HIGH_REACTIVITY override should trigger
  bool shouldTriggerHighReactivity() {
    final signalCount = [
      recentAffirmationEdits > 2,
      recentCatchActivity,
      possibleCoachingVenting,
      lowExecutionLevel,
    ].where((s) => s).length;

    return signalCount >= 2;
  }

  /// Check if OUT_OF_SCOPE override should trigger
  bool shouldTriggerOutOfScope() {
    final signalCount = [
      fragmentationPattern,
      pressureAvoidancePattern,
      lowExecutionLevel,
      catchCount > 2,
      catchTypeDistribution.length > 1, // mixed catch types
    ].where((s) => s).length;

    return signalCount >= 3;
  }
}
