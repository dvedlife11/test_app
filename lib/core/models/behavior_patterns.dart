
/// Stub for BehaviorPatterns (from core framework)
class BehaviorPatterns {
  final double? editFrequency;
  final double? executionConsistency;
  final double? instabilityScore;

  BehaviorPatterns({
    this.editFrequency,
    this.executionConsistency,
    this.instabilityScore,
  });

  factory BehaviorPatterns.empty() => BehaviorPatterns();
}
