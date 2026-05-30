
import 'package:test_app/core/chatbot/models/detection_signals.dart';
import 'package:test_app/core/models/behavior_patterns.dart';
import 'package:test_app/core/models/daily_event_record.dart';
import 'package:test_app/core/models/daily_compiled_state.dart';

/// Extracts behavioral detection signals from core data
class BehavioralDetector {
  /// Analyze today's compiled state + patterns to extract detection signals
  static DetectionSignals detect({
    required DailyCompiledState todayState,
    required BehaviorPatterns patterns,
    required List<DailyEventRecord> recentEvents,
  }) {
    // Execution signals
    final counterManipulation = _detectCounterManipulation(recentEvents);
    final affirmationAvoidance = _detectAffirmationAvoidance(patterns);
    final lowConfidenceExecution = _detectLowConfidenceExecution(recentEvents);

    // Trigger/reaction signals
    final triggerReaction = _detectTriggerReaction(recentEvents);

    // Counter distribution
    final overfocus = _detectOverfocusPattern(todayState);
    final neglectedCounter = _detectNeglectedCounterPattern(todayState);

    // Catch analysis
    final catchCount = _countCatches(recentEvents);
    final catchTypeDistribution = _getCatchTypeDistribution(recentEvents);
    final dominantCatchType = _getDominantCatchType(catchTypeDistribution);

    // Fragmentation & pressure avoidance
    final fragmentation = _detectFragmentation(todayState, patterns);
    final pressureAvoidance = _detectPressureAvoidance(todayState);

    // High reactivity indicators
    final recentEdits = _countRecentAffirmationEdits(patterns);
    final recentCatches = catchCount > 0;
    final coachingVenting = _detectCoachingVenting(recentEvents);
    final lowExecution = _assessExecutionLevel(todayState) < 50.0;

    return DetectionSignals(
      counterManipulationSignal: counterManipulation,
      affirmationAvoidanceSignal: affirmationAvoidance,
      lowConfidenceExecutionSignal: lowConfidenceExecution,
      triggerReactionSignal: triggerReaction,
      overfocusPattern: overfocus,
      neglectedCounterPattern: neglectedCounter,
      catchCount: catchCount,
      catchTypeDistribution: catchTypeDistribution,
      dominantCatchType: dominantCatchType,
      fragmentationPattern: fragmentation,
      pressureAvoidancePattern: pressureAvoidance,
      recentAffirmationEdits: recentEdits,
      recentCatchActivity: recentCatches,
      possibleCoachingVenting: coachingVenting,
      lowExecutionLevel: lowExecution,
    );
  }

  /// Counter reset clusters indicate manipulation
  static bool _detectCounterManipulation(List<DailyEventRecord> events) {
    final resets = events
        .where((e) => e.eventType == 'counter_reset')
        .length;

    return resets > 2; // threshold: more than 2 resets in recent period
  }

  /// Many edits with low counter activity
  static bool _detectAffirmationAvoidance(BehaviorPatterns patterns) {
    return (patterns.editFrequency ?? 0) > 3 &&
        (patterns.executionConsistency ?? 0) < 0.5;
  }

  /// Low execution score despite edits
  static bool _detectLowConfidenceExecution(List<DailyEventRecord> events) {
    final completedActions = events
        .where((e) => e.eventType == 'affirmation_completed' || e.eventType == 'counter_increment')
        .length;

    return completedActions == 0;
  }

  /// Rapid modification after trigger event
  static bool _detectTriggerReaction(List<DailyEventRecord> events) {
    final triggerEvents = events.where((e) => e.eventType == 'trigger_detected');
    
    for (var trigger in triggerEvents) {
      final nextHourEvents = events
          .where((e) =>
              e.timestamp.isAfter(trigger.timestamp) &&
              e.timestamp.isBefore(trigger.timestamp.add(Duration(hours: 1))) &&
              (e.eventType == 'affirmation_edited' ||
                  e.eventType == 'counter_reset' ||
                  e.eventType == 'system_modified'))
          .length;

      if (nextHourEvents > 0) {
        return true;
      }
    }

    return false;
  }

  /// One counter significantly ahead of others
  static bool _detectOverfocusPattern(DailyCompiledState state) {
    // This would depend on your counter data structure
    // Simplified check
    return false; // TODO: implement with actual counter data
  }

  /// Counter repeatedly at zero
  static bool _detectNeglectedCounterPattern(DailyCompiledState state) {
    return false; // TODO: implement with actual counter data
  }

  /// Count catches from events
  static int _countCatches(List<DailyEventRecord> events) {
    return events
        .where((e) => e.eventType == 'catch_recorded')
        .length;
  }

  /// Classify catches by type
  static Map<String, int> _getCatchTypeDistribution(List<DailyEventRecord> events) {
    final distribution = <String, int>{};

    for (var event in events) {
      if (event.eventType == 'catch_recorded') {
        final catchType = event.metadata?['catchType'] as String? ?? 'unknown';
        distribution[catchType] = (distribution[catchType] ?? 0) + 1;
      }
    }

    return distribution;
  }

  /// Get dominant catch type
  static String? _getDominantCatchType(Map<String, int> distribution) {
    if (distribution.isEmpty) return null;
    var max = 0;
    String? dominant;
    distribution.forEach((type, count) {
      if (count > max) {
        max = count;
        dominant = type;
      }
    });
    return dominant;
  }

  /// High instability + no umbrella active
  static bool _detectFragmentation(DailyCompiledState state, BehaviorPatterns patterns) {
    final instabilityScore = (patterns.instabilityScore ?? 0.0);
    final umbrellaActive = state.systemState?['umbrellaActive'] as bool? ?? false;

    return instabilityScore > 60.0 && !umbrellaActive;
  }

  /// Multiple systems disabled
  static bool _detectPressureAvoidance(DailyCompiledState state) {
    final dailyTargetEnabled = state.systemState?['dailyTargetEnabled'] as bool? ?? true;
    final countersActive = state.systemState?['countersActive'] as bool? ?? true;
    final umbrellaActive = state.systemState?['umbrellaActive'] as bool? ?? true;

    final disabledCount = [!dailyTargetEnabled, !countersActive, !umbrellaActive]
        .where((d) => d)
        .length;

    return disabledCount >= 2;
  }

  /// Count affirmation edits in last 3 days
  static int _countRecentAffirmationEdits(BehaviorPatterns patterns) {
    return (patterns.editFrequency ?? 0).toInt();
  }

  /// Check for coaching venting patterns (long inputs in coaching mode)
  static bool _detectCoachingVenting(List<DailyEventRecord> events) {
    final coachingEvents = events
        .where((e) => e.eventType == 'coaching_interaction')
        .where((e) => (e.metadata?['inputLength'] as int? ?? 0) > 200) // long text
        .length;

    return coachingEvents > 0;
  }

  /// Assess overall execution level (0-100)
  static double _assessExecutionLevel(DailyCompiledState state) {
    // Calculate based on available core data
    // TODO: implement based on actual counter/execution data structure
    return 50.0; // placeholder
  }
}
