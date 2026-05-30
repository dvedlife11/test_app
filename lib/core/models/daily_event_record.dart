
/// Stub for DailyEventRecord (from core framework)
class DailyEventRecord {
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  DailyEventRecord({
    required this.eventType,
    required this.timestamp,
    this.metadata,
  });

  factory DailyEventRecord.empty() => DailyEventRecord(
    eventType: 'unknown',
    timestamp: DateTime.now(),
  );
}
