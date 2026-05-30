
/// Override states that can suppress normal logic
enum OverrideState {
  none,              // no override active
  highReactivity,    // de-escalate + refocus
  outOfScope,        // simplify + restore execution
}

/// The resolved interpretation from detection signals
class InterpretationResult {
  final OverrideState override;
  final String? manipulationIntensity; // LOW, MEDIUM, HIGH
  final String? dominantCatchPattern; // from detection
  final bool stateBehaviorMismatch;   // dailyQuiz vs actual behavior
  final String? mismatchType;         // underreporting, denial, lack_of_awareness
  
  InterpretationResult({
    required this.override,
    required this.manipulationIntensity,
    required this.dominantCatchPattern,
    required this.stateBehaviorMismatch,
    required this.mismatchType,
  });

  factory InterpretationResult.empty() => InterpretationResult(
    override: OverrideState.none,
    manipulationIntensity: null,
    dominantCatchPattern: null,
    stateBehaviorMismatch: false,
    mismatchType: null,
  );
}

/// Response modes (base mode before override)
enum ResponseMode {
  push,       // movement forward, expand ceiling
  stabilize,  // fragile improvement, lock behavior
  callOut,    // no execution, inconsistency
}

/// Pressure level determines harshness
enum PressureLevel {
  low,    // guide
  medium, // push
  high,   // call out hard
}

/// Boost message types
enum BoostMessageType {
  push,           // "Stop thinking. Do the reps."
  reassurance,    // "You're not off. Stay in it."
  callOutLight,   // "You already know what to do."
  momentum,       // "Keep going. Don't break the chain."
  identity,       // "You're not the version that quits now."
  deEscalate,     // used during HIGH_REACTIVITY
  simplify,       // used during OUT_OF_SCOPE
}

/// Final resolved response structure
class ChatbotResponse {
  final String groundTruth;           // execution / behavior reality
  final String movement;              // forward / stagnant / slipping
  final String direction;             // action to take next
  final ResponseMode mode;
  final PressureLevel pressure;
  final OverrideState activeOverride;
  final BoostMessageType? boostType;
  final String? boostMessage;
  final DateTime generatedAt;

  ChatbotResponse({
    required this.groundTruth,
    required this.movement,
    required this.direction,
    required this.mode,
    required this.pressure,
    required this.activeOverride,
    required this.boostType,
    required this.boostMessage,
    required this.generatedAt,
  });

  factory ChatbotResponse.empty() => ChatbotResponse(
    groundTruth: '',
    movement: '',
    direction: '',
    mode: ResponseMode.stabilize,
    pressure: PressureLevel.low,
    activeOverride: OverrideState.none,
    boostType: null,
    boostMessage: null,
    generatedAt: DateTime.now(),
  );
}
