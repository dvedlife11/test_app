import 'package:test_app/core/chatbot/models/chatbot_state.dart';
import 'package:test_app/core/chatbot/models/chatbot_response.dart';
import 'package:test_app/core/chatbot/models/detection_signals.dart';
import 'package:test_app/core/chatbot/models/chatbot_message.dart';
import 'package:test_app/core/chatbot/models/chatbot_response_memory.dart';
import 'package:test_app/core/chatbot/detection/behavioral_detector.dart';
import 'package:test_app/core/chatbot/interpretation/interpretation_engine.dart';
import 'package:test_app/core/chatbot/override/override_system.dart';
import 'package:test_app/core/chatbot/generation/message_generator.dart';
import 'package:test_app/core/chatbot/openai/openai_integration.dart';

/// Main Johnson chatbot orchestrator
/// Coordinates: Detection → Interpretation → Override → Modulation → Resolution
class JohnsonChatbotEngine {
  final OpenAIIntegration openAI;
  late ChatbotState currentState;
  late ChatbotConversation conversation;
  late ChatbotResponseMemory responseMemory;

  JohnsonChatbotEngine({
    OpenAIIntegration? openAI,
  }) : openAI = openAI ?? OpenAIIntegration() {
    currentState = ChatbotState.fromDefaults();
    conversation = ChatbotConversation.empty();
    responseMemory = ChatbotResponseMemory.initialize();
  }

  /// Process user message and generate response
  /// Follows Johnson Master execution order:
  /// 1. EXECUTION LAYER (current state)
  /// 2. DETECTION (signals)
  /// 3. INTERPRETATION (structure signals)
  /// 4. OVERRIDE (HIGH_REACTIVITY / OUT_OF_SCOPE)
  /// 5. OUTPUT MODULATION (mode + pressure)
  /// 6. FINAL VALIDATION
  Future<ChatbotResponse> processMessage(
    String userMessage, {
    // TODO: Wire these from actual core data
    DetectionSignals? signals,
    ChatbotState? stateOverride,
  }) async {
    // Add user message to conversation
    final userMsg = ChatbotMessage.user(content: userMessage);
    conversation = conversation.addMessage(userMsg);

    // STEP 1: EXECUTION LAYER CHECK
    final executionStatus = _checkExecutionLayer(currentState);
    if (!executionStatus) {
      // Off track - no discussion
      final offTrackResponse = ChatbotResponse.empty();
      return offTrackResponse;
    }

    // STEP 2: DETECTION
    final detectionSignals = signals ?? DetectionSignals.empty();

    // STEP 3: INTERPRETATION
    final interpretation = InterpretationEngine.interpret(detectionSignals);

    // STEP 4: OVERRIDE AUTHORITY
    ResponseMode baseMode = MessageGenerator.determineMode(
      currentState,
      MessageGenerator.generateMovement(currentState),
    );

    ResponseMode finalMode = baseMode;
    PressureLevel finalPressure = MessageGenerator.assessPressureLevel(
      currentState,
      MessageGenerator.generateMovement(currentState),
    );

    if (interpretation.override != OverrideState.none) {
      OverrideSystem.applyOverride(
        override: interpretation.override,
        state: currentState,
        signals: detectionSignals,
        onOverride: (mode, pressure, boostType, message) {
          finalMode = mode;
          finalPressure = pressure;
        },
      );
    }

    // STEP 5: OUTPUT MODULATION
    final groundTruth =
        MessageGenerator.generateGroundTruth(currentState, finalMode);
    final movement = MessageGenerator.generateMovement(currentState);
    final direction =
        MessageGenerator.generateDirection(currentState, finalMode, movement);

    // Determine boost message
    BoostMessageType? boostType;
    String? boostMessage;

    if (interpretation.override != OverrideState.none) {
      // Override determines boost
      boostType = interpretation.override == OverrideState.highReactivity
          ? BoostMessageType.deEscalate
          : BoostMessageType.simplify;

      boostMessage =
          MessageGenerator.generateBoostMessage(boostType, currentState);
    } else {
      // Normal boost based on state
      boostType = MessageGenerator.stateToBoostType(currentState.type);
      boostMessage =
          MessageGenerator.generateBoostMessage(boostType, currentState);
    }

    // STEP 6: FINAL VALIDATION
    _validateResponse(
      finalMode,
      finalPressure,
      interpretation.override,
    );

    // Build response
    final response = ChatbotResponse(
      groundTruth: groundTruth,
      movement: movement,
      direction: direction,
      mode: finalMode,
      pressure: finalPressure,
      activeOverride: interpretation.override,
      boostType: boostType,
      boostMessage: boostMessage,
      generatedAt: DateTime.now(),
    );

    // Add system response to conversation
    final systemMsg = ChatbotMessage.system(
      content: direction, // Primary response text
      messageType: 'assistant_response',
      metadata: {
        'groundTruth': groundTruth,
        'movement': movement,
        'mode': finalMode.name,
        'pressure': finalPressure.name,
        'override': interpretation.override.name,
      },
    );
    conversation = conversation.addMessage(systemMsg);

    // Update memory
    responseMemory = responseMemory.recordDirection(direction);

    return response;
  }

  /// Check execution layer (minimum standard met)
  bool _checkExecutionLayer(ChatbotState state) {
    // Based on Johnson: minimum_standard_met
    return state.executionScore > 0 ||
        state.disciplineScore > 20 ||
        state.catchCount >= 0; // at least attempted to track

    // If false → off track, no discussion
  }

  /// Validate response for contradictions
  void _validateResponse(
    ResponseMode mode,
    PressureLevel pressure,
    OverrideState override,
  ) {
    // RULE: pressure cannot contradict mode
    if (pressure == PressureLevel.high && mode == ResponseMode.stabilize) {
      throw Exception(
          'Response validation failed: high pressure contradicts stabilize mode');
    }

    // RULE: override correctly applied
    if (override == OverrideState.highReactivity &&
        mode != ResponseMode.stabilize) {
      throw Exception(
          'Response validation failed: HIGH_REACTIVITY override must use stabilize mode');
    }

    if (override == OverrideState.outOfScope && mode != ResponseMode.push) {
      throw Exception(
          'Response validation failed: OUT_OF_SCOPE override must use push mode');
    }
  }

  /// Update current state (call when core data changes)
  void updateState(ChatbotState newState) {
    currentState = newState;
  }

  /// Get conversation history
  ChatbotConversation getConversation() => conversation;

  /// Get response memory
  ChatbotResponseMemory getResponseMemory() => responseMemory;

  /// Clear conversation (reset chat)
  void clearConversation() {
    conversation = ChatbotConversation.empty();
  }
}
