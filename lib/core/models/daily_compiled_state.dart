
/// Stub for DailyCompiledState (from core framework)
class DailyCompiledState {
  final Map<String, dynamic>? systemState;
  final int executionScore;
  final int instabilityScore;

  DailyCompiledState({
    this.systemState,
    this.executionScore = 50,
    this.instabilityScore = 30,
  });

  factory DailyCompiledState.empty() => DailyCompiledState(
    systemState: {
      'umbrellaActive': false,
      'dailyTargetEnabled': true,
      'countersActive': true,
    },
  );
}
