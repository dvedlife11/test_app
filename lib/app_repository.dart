import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// --- CONSTANTS ---
const String dailyQuizCompletedDate = 'daily_quiz_completed_date';
const String dailyQuizCompletedDates = 'daily_quiz_completed_dates';
const String dailyQuizYesSubjects = 'daily_quiz_yes_subjects';

// --- PRIVATE HELPERS ---
String _todayKey() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _dailyQuizYesSubjectsForDateKey(String dateKey) =>
    'daily_quiz_yes_subjects_$dateKey';

Future<void> clearTodayDailyQuizResult() async {
  final prefs = await _sharedPrefs;
  final today = _todayKey();
  await prefs.remove(dailyQuizCompletedDate);
  await prefs.remove(dailyQuizYesSubjects);
  await prefs.remove(_dailyQuizYesSubjectsForDateKey(today));
  // Optionally, remove from dailyQuizCompletedDates
  final dates = prefs.getStringList(dailyQuizCompletedDates) ?? <String>[];
  if (dates.contains(today)) {
    dates.remove(today);
    await prefs.setStringList(dailyQuizCompletedDates, dates);
  }
}
// ...existing code...

Future<SharedPreferences> get _sharedPrefs => SharedPreferences.getInstance();

// ...existing code...

// ...existing code...

// ...existing code...

class AffirmationItem {
  final String affirmKey;
  final String text;

  const AffirmationItem({
    required this.affirmKey,
    required this.text,
  });
}

class CounterData {
  final int last24hCount;
  final int lifetimeCount;

  const CounterData({
    required this.last24hCount,
    required this.lifetimeCount,
  });
}

class OnboardingResultData {
  final String impactTitle;
  final String impactDescription;
  final int yesCount;

  const OnboardingResultData({
    required this.impactTitle,
    required this.impactDescription,
    required this.yesCount,
  });
}

class NotificationPreferencesData {
  final bool onboardingReminderEnabled;
  final bool dailyPracticeNotificationsEnabled;
  final bool dailyCountersEnabled;
  final bool appLockEnabled;
  final String? onboardingReminderUpdatedAt;
  final String? dailyPracticeNotificationsUpdatedAt;
  final String? dailyCountersUpdatedAt;
  final String? appLockUpdatedAt;

  const NotificationPreferencesData({
    required this.onboardingReminderEnabled,
    required this.dailyPracticeNotificationsEnabled,
    required this.dailyCountersEnabled,
    required this.appLockEnabled,
    required this.onboardingReminderUpdatedAt,
    required this.dailyPracticeNotificationsUpdatedAt,
    required this.dailyCountersUpdatedAt,
    required this.appLockUpdatedAt,
  });
}

class DailyQuizResultData {
  final bool completedToday;
  final List<String> yesSubjects;

  const DailyQuizResultData({
    required this.completedToday,
    required this.yesSubjects,
  });

  get noAnswersList => null;

  get yesAnswersList => null;
}

class DailyQuizDraftData {
  final int currentQuestion;
  final List<bool?> answers;

  const DailyQuizDraftData({
    required this.currentQuestion,
    required this.answers,
  });
}

class AppRepository {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sharedPrefs => SharedPreferences.getInstance();

  final StreamController<String> _umbrellaController =
      StreamController<String>.broadcast();

  String _currentUmbrella = 'umbrella_1';

  // COUNTER KEYS
  static const String counter1Count = 'counter_1';
  static const String counter2Count = 'counter_2';
  static const String counter3Count = 'counter_3';
  static const String umbrellaCount = 'counter_umbrella';
  static const String onboardingImpactTitle = 'onboarding_impact_title';
  static const String onboardingImpactDescription =
      'onboarding_impact_description';
  static const String onboardingYesCount = 'onboarding_yes_count';
  static const String customDailyTarget = 'custom_daily_target';
  static const String onboardingReminderEnabled = 'onboarding_reminder_enabled';
  static const String dailyPracticeNotificationsEnabled =
      'daily_practice_notifications_enabled';
  static const String dailyCountersEnabled = 'daily_counters_enabled';
  static const String appLockEnabled = 'app_lock_enabled';
  static const String onboardingReminderUpdatedAt =
      'onboarding_reminder_updated_at';
  static const String dailyPracticeNotificationsUpdatedAt =
      'daily_practice_notifications_updated_at';
  static const String dailyCountersUpdatedAt = 'daily_counters_updated_at';
  static const String appLockUpdatedAt = 'app_lock_updated_at';
  static const String homeSelectedWidgets = 'home_selected_widgets';
  static const String dailyQuizCompletedDate = 'daily_quiz_completed_date';
  static const String dailyQuizYesSubjects = 'daily_quiz_yes_subjects';
  static const String dailyQuizCompletedDates = 'daily_quiz_completed_dates';
  static const String dailyQuizDraftDate = 'daily_quiz_draft_date';
  static const String dailyQuizDraftQuestion = 'daily_quiz_draft_question';
  static const String dailyQuizDraftAnswers = 'daily_quiz_draft_answers';
  static const String _audioSessionTrackUsagePrefix =
      'audio_session_track_usage_';
  static const String _audioSessionDailyPlaysPrefix =
      'audio_session_daily_plays_';
  static const String _audioSessionAppliedPlaysPrefix =
      'audio_session_applied_plays_';
  static const String _audioSessionAutoPendingTotalPrefix =
      'audio_session_auto_pending_total_';
  static const String audioSessionAutoAddToA1 = 'audio_session_auto_add_to_a1';
  static const String counter1Enabled = 'counter_1_enabled';

  Stream<String> watchSelectedUmbrella() async* {
    final initial = await getSelectedUmbrella();
    _currentUmbrella = initial;
    yield initial;
    yield* _umbrellaController.stream;
  }

  Future<void> ensureSeedData() async {
    // Database is created lazily, no need to seed for shared_prefs
  }

  Future<String> getSelectedUmbrella() async {
    final prefs = await _sharedPrefs;
    return prefs.getString('selected_umbrella') ?? 'umbrella_prompt';
  }

  Future<void> saveSelectedUmbrella(String umbrellaKey) async {
    final prefs = await _sharedPrefs;
    await prefs.setString('selected_umbrella', umbrellaKey);
    await prefs.setString(
      'affirmation_umbrella',
      _umbrellaLabelForSelection(umbrellaKey),
    );
    _currentUmbrella = umbrellaKey;
    _umbrellaController.add(umbrellaKey);

    final affirmKey = mapUmbrellaToAffirmation(umbrellaKey);
    final createdKey = _affirmationCreatedKey(affirmKey);
    if (!prefs.containsKey(createdKey)) {
      await prefs.setString(createdKey, DateTime.now().toIso8601String());
    }
  }

  String _umbrellaLabelForSelection(String umbrellaKey) {
    switch (umbrellaKey) {
      case 'umbrella_1':
        return 'I always get what I want';
      case 'umbrella_2':
        return 'Everything is wonderful';
      case 'umbrella_3':
        return 'I am in love with my life';
      case 'umbrella_none':
        return 'No umbrella affirmation for me';
      default:
        return 'Select umbrella affirmation';
    }
  }

  String mapUmbrellaToAffirmation(String umbrellaKey) {
    switch (umbrellaKey) {
      case 'umbrella_1':
        return 'affirmation_1';
      case 'umbrella_2':
        return 'affirmation_2';
      case 'umbrella_3':
        return 'affirmation_3';
      case 'umbrella_none':
      case 'umbrella_prompt':
        return 'affirmation_umbrella';
      default:
        return 'affirmation_umbrella';
    }
  }

  Future<String> getAffirmationText(String affirmKey) async {
    final prefs = await _sharedPrefs;
    return prefs.getString(affirmKey) ?? '';
  }

  Future<void> saveAffirmationText(
    String affirmKey,
    String text, {
    bool resetCounterBaseline = true,
  }) async {
    final prefs = await _sharedPrefs;
    await prefs.setString(affirmKey, text);

    if (resetCounterBaseline) {
      // Reset the affirmation start date whenever the affirmation is updated
      // in reset mode.
      final timestampKey = _affirmationCreatedKey(affirmKey);
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
    }
  }

  Future<void> saveAffirmationTextKeepCounter(
      String affirmKey, String text) async {
    await saveAffirmationText(
      affirmKey,
      text,
      resetCounterBaseline: false,
    );
  }

  String _counterEventsKey(String counterKey) => 'counter_events_$counterKey';
  String _affirmationCreatedKey(String affirmKey) =>
      'affirmation_created_$affirmKey';

  String _affirmationKeyForCounter(String counterKey) {
    if (counterKey == 'counter_1') return 'affirmation_1';
    if (counterKey == 'counter_2') return 'affirmation_2';
    if (counterKey == 'counter_3') return 'affirmation_3';
    if (counterKey == 'counter_umbrella') return 'affirmation_umbrella';
    return 'affirmation_1';
  }

  Future<CounterData> getCounterData(String counterKey,
      {String? affirmationKeyOverride}) async {
    final prefs = await _sharedPrefs;
    final now = DateTime.now();

    // Calculate midnight of current day (start of "today")
    final todayStart = DateTime(now.year, now.month, now.day);

    final storedTimestamps =
        prefs.getStringList(_counterEventsKey(counterKey)) ?? [];

    // Count taps since midnight today
    final todayTaps = storedTimestamps.where((timestamp) {
      final date = DateTime.tryParse(timestamp);
      return date != null && !date.isBefore(todayStart);
    }).toList();

    // Count taps since affirmation was created
    final affirmKey =
        affirmationKeyOverride ?? _affirmationKeyForCounter(counterKey);
    final createdTimestamp = prefs.getString(_affirmationCreatedKey(affirmKey));
    final lifetimeOffset = prefs.getInt(_lifetimeOffsetKey(counterKey)) ?? 0;
    int lifetimeTaps = storedTimestamps.length + lifetimeOffset;

    if (createdTimestamp != null) {
      final createdDate = DateTime.tryParse(createdTimestamp);
      if (createdDate != null) {
        lifetimeTaps = storedTimestamps.where((timestamp) {
              final date = DateTime.tryParse(timestamp);
              return date != null && !date.isBefore(createdDate);
            }).length +
            lifetimeOffset;
      }
    }

    return CounterData(
      last24hCount: todayTaps.length,
      lifetimeCount: lifetimeTaps,
    );
  }

  Future<void> addCounterTap(String counterKey) async {
    final prefs = await _sharedPrefs;
    final now = DateTime.now();

    final storedTimestamps =
        prefs.getStringList(_counterEventsKey(counterKey)) ?? [];
    storedTimestamps.add(now.toIso8601String());
    await prefs.setStringList(_counterEventsKey(counterKey), storedTimestamps);
  }

  Future<void> addCounterTaps(String counterKey, int count) async {
    if (count <= 0) return;
    final prefs = await _sharedPrefs;
    final storedTimestamps =
        prefs.getStringList(_counterEventsKey(counterKey)) ?? [];
    final base = DateTime.now();

    for (var i = 0; i < count; i++) {
      storedTimestamps.add(
        base.add(Duration(milliseconds: i)).toIso8601String(),
      );
    }

    await prefs.setStringList(_counterEventsKey(counterKey), storedTimestamps);
  }

  String _audioTrackUsageKeyForIndex(int index) =>
      '$_audioSessionTrackUsagePrefix$index';

  Future<void> saveAudioSessionTrackUsage(Map<int, int> usage) async {
    final prefs = await _sharedPrefs;
    for (var i = 0; i < 4; i++) {
      await prefs.setInt(_audioTrackUsageKeyForIndex(i), usage[i] ?? 0);
    }
  }

  Future<int> getAudioSessionTrackUsageForIndex(int index) async {
    final prefs = await _sharedPrefs;
    return prefs.getInt(_audioTrackUsageKeyForIndex(index)) ?? 0;
  }

  String _audioDailyPlaysKeyForDate(String dateKey) =>
      '$_audioSessionDailyPlaysPrefix$dateKey';

  String _audioAppliedPlaysKeyForDate(String dateKey) =>
      '$_audioSessionAppliedPlaysPrefix$dateKey';

  String _audioAutoPendingTotalKeyForDate(String dateKey) =>
      '$_audioSessionAutoPendingTotalPrefix$dateKey';

  String _audioAppliedPlaysKeyForCounterDate(
      String counterKey, String dateKey) {
    if (counterKey == counter1Count) {
      return _audioAppliedPlaysKeyForDate(dateKey);
    }
    return '$_audioSessionAppliedPlaysPrefix${counterKey}_$dateKey';
  }

  String _audioAutoPendingTotalKeyForCounterDate(
      String counterKey, String dateKey) {
    if (counterKey == counter1Count) {
      return _audioAutoPendingTotalKeyForDate(dateKey);
    }
    return '$_audioSessionAutoPendingTotalPrefix${counterKey}_$dateKey';
  }

  String _audioAutoAddKeyForCounter(String counterKey) {
    if (counterKey == counter1Count) return audioSessionAutoAddToA1;
    return 'audio_session_auto_add_$counterKey';
  }

  String _counterEnabledKeyForCounter(String counterKey) {
    if (counterKey == counter1Count) return counter1Enabled;
    return '${counterKey}_enabled';
  }

  Future<void> setAudioSessionAutoAddForCounter(
      String counterKey, bool enabled) async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(_audioAutoAddKeyForCounter(counterKey), enabled);
  }

  Future<bool> getAudioSessionAutoAddForCounter(String counterKey) async {
    final prefs = await _sharedPrefs;
    return prefs.getBool(_audioAutoAddKeyForCounter(counterKey)) ?? false;
  }

  Future<void> setAudioSessionAutoAddToA1(bool enabled) async {
    await setAudioSessionAutoAddForCounter(counter1Count, enabled);
  }

  Future<bool> getAudioSessionAutoAddToA1() async {
    return getAudioSessionAutoAddForCounter(counter1Count);
  }

  Future<void> setCounterEnabled(String counterKey, bool enabled) async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(_counterEnabledKeyForCounter(counterKey), enabled);
  }

  Future<bool> getCounterEnabled(String counterKey) async {
    final prefs = await _sharedPrefs;
    return prefs.getBool(_counterEnabledKeyForCounter(counterKey)) ?? true;
  }

  Future<void> setCounter1Enabled(bool enabled) async {
    await setCounterEnabled(counter1Count, enabled);
  }

  Future<bool> getCounter1Enabled() async {
    return getCounterEnabled(counter1Count);
  }

  Future<void> incrementAudioSessionCompletedPlay() async {
    final prefs = await _sharedPrefs;
    final key = _audioDailyPlaysKeyForDate(_todayKey());
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  Future<void> incrementAudioSessionAppliedPlaysToday({int by = 1}) async {
    await incrementAudioSessionAppliedPlaysTodayForCounter(counter1Count,
        by: by);
  }

  Future<void> incrementAudioSessionAppliedPlaysTodayForCounter(
      String counterKey,
      {int by = 1}) async {
    if (by <= 0) return;
    final prefs = await _sharedPrefs;
    final key = _audioAppliedPlaysKeyForCounterDate(counterKey, _todayKey());
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + by);
  }

  Future<int> getAudioSessionCompletedPlaysToday() async {
    final prefs = await _sharedPrefs;
    final key = _audioDailyPlaysKeyForDate(_todayKey());
    return prefs.getInt(key) ?? 0;
  }

  Future<int> getAudioSessionAppliedPlaysToday() async {
    return getAudioSessionAppliedPlaysTodayForCounter(counter1Count);
  }

  Future<int> getAudioSessionAppliedPlaysTodayForCounter(
      String counterKey) async {
    final prefs = await _sharedPrefs;
    final key = _audioAppliedPlaysKeyForCounterDate(counterKey, _todayKey());
    return prefs.getInt(key) ?? 0;
  }

  Future<int> getAudioSessionUnappliedPlaysToday() async {
    return getAudioSessionUnappliedPlaysTodayForCounter(counter1Count);
  }

  Future<int> getAudioSessionUnappliedPlaysTodayForCounter(
      String counterKey) async {
    final completed = await getAudioSessionCompletedPlaysToday();
    final applied =
        await getAudioSessionAppliedPlaysTodayForCounter(counterKey);
    final unapplied = completed - applied;
    return unapplied > 0 ? unapplied : 0;
  }

  Future<void> markAudioSessionPlaysAppliedToday({int? appliedCount}) async {
    await markAudioSessionPlaysAppliedTodayForCounter(counter1Count,
        appliedCount: appliedCount);
  }

  Future<void> markAudioSessionPlaysAppliedTodayForCounter(String counterKey,
      {int? appliedCount}) async {
    final prefs = await _sharedPrefs;
    final date = _todayKey();
    final completed = await getAudioSessionCompletedPlaysToday();
    final nextApplied = (appliedCount ?? completed).clamp(0, completed);
    final key = _audioAppliedPlaysKeyForCounterDate(counterKey, date);
    await prefs.setInt(key, nextApplied);
  }

  Future<void> addAudioSessionAutoPendingTotalToday(int amount) async {
    await addAudioSessionAutoPendingTotalTodayForCounter(counter1Count, amount);
  }

  Future<void> addAudioSessionAutoPendingTotalTodayForCounter(
      String counterKey, int amount) async {
    if (amount <= 0) return;
    final prefs = await _sharedPrefs;
    final key =
        _audioAutoPendingTotalKeyForCounterDate(counterKey, _todayKey());
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + amount);
  }

  Future<void> settleAudioSessionAutoDailyTotalsForCounter1() async {
    await settleAudioSessionAutoDailyTotalsForCounter(counter1Count);
  }

  Future<void> settleAudioSessionAutoDailyTotalsForCounter(
      String counterKey) async {
    final prefs = await _sharedPrefs;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final now = DateTime.now();

    final keyPrefix = counterKey == counter1Count
        ? _audioSessionAutoPendingTotalPrefix
        : '$_audioSessionAutoPendingTotalPrefix${counterKey}_';

    final keys = prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList();

    for (final key in keys) {
      final dateKey = key.substring(keyPrefix.length);
      final date = DateTime.tryParse(dateKey);
      if (date == null) continue;

      final dateStart = DateTime(date.year, date.month, date.day);
      final isPastDay = dateStart.isBefore(todayStart);
      final isToday = dateStart.isAtSameMomentAs(todayStart);
      final canSettleToday =
          isToday && (now.hour > 23 || (now.hour == 23 && now.minute >= 59));
      if (!isPastDay && !canSettleToday) continue;

      final pending = prefs.getInt(key) ?? 0;
      if (pending <= 0) {
        await prefs.remove(key);
        continue;
      }

      await addCounterTaps(counterKey, pending);
      await prefs.remove(key);
    }
  }

  String _lifetimeOffsetKey(String counterKey) =>
      '${counterKey}_lifetime_offset';

  Future<void> resetCounterToday(String counterKey) async {
    final prefs = await _sharedPrefs;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final storedTimestamps =
        prefs.getStringList(_counterEventsKey(counterKey)) ?? [];

    // Count today's taps that will be removed
    final todayTapsCount = storedTimestamps.where((timestamp) {
      final date = DateTime.tryParse(timestamp);
      return date != null && !date.isBefore(todayStart);
    }).length;

    // Preserve lifetime count by storing an offset
    final existingOffset = prefs.getInt(_lifetimeOffsetKey(counterKey)) ?? 0;
    await prefs.setInt(
        _lifetimeOffsetKey(counterKey), existingOffset + todayTapsCount);

    final remainingTimestamps = storedTimestamps.where((timestamp) {
      final date = DateTime.tryParse(timestamp);
      return date == null || date.isBefore(todayStart);
    }).toList();

    await prefs.setStringList(
        _counterEventsKey(counterKey), remainingTimestamps);
  }

  Future<void> resetCounterLifetime(String counterKey,
      {String? affirmationKeyOverride}) async {
    final prefs = await _sharedPrefs;
    await prefs.remove(_counterEventsKey(counterKey));
    await prefs.remove(_lifetimeOffsetKey(counterKey));

    final affirmKey =
        affirmationKeyOverride ?? _affirmationKeyForCounter(counterKey);
    await prefs.setString(
      _affirmationCreatedKey(affirmKey),
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> resetCounter(String counterKey) async {
    final prefs = await _sharedPrefs;
    await prefs.remove(_counterEventsKey(counterKey));
  }

  Future<void> saveOnboardingResult({
    required String impactTitle,
    required String impactDescription,
    required int yesCount,
  }) async {
    final prefs = await _sharedPrefs;
    await prefs.setString(onboardingImpactTitle, impactTitle);
    await prefs.setString(onboardingImpactDescription, impactDescription);
    await prefs.setInt(onboardingYesCount, yesCount);
  }

  Future<OnboardingResultData?> getOnboardingResult() async {
    final prefs = await _sharedPrefs;
    final title = prefs.getString(onboardingImpactTitle);
    final description = prefs.getString(onboardingImpactDescription);

    if (title == null || description == null) {
      return null;
    }

    return OnboardingResultData(
      impactTitle: title,
      impactDescription: description,
      yesCount: prefs.getInt(onboardingYesCount) ?? 0,
    );
  }

  Future<int?> getCustomDailyTarget() async {
    final prefs = await _sharedPrefs;
    return prefs.getInt(customDailyTarget);
  }

  String _counterDailyTargetKey(String counterKey) =>
      'custom_daily_target_$counterKey';

  Future<int?> getCounterDailyTarget(String counterKey) async {
    final prefs = await _sharedPrefs;
    return prefs.getInt(_counterDailyTargetKey(counterKey));
  }

  Future<void> saveCustomDailyTarget(int value) async {
    final prefs = await _sharedPrefs;
    await prefs.setInt(customDailyTarget, value);
  }

  Future<void> saveCounterDailyTarget(String counterKey, int value) async {
    final prefs = await _sharedPrefs;
    await prefs.setInt(_counterDailyTargetKey(counterKey), value);
  }

  Future<void> clearCustomDailyTarget() async {
    final prefs = await _sharedPrefs;
    await prefs.remove(customDailyTarget);
  }

  Future<void> clearCounterDailyTarget(String counterKey) async {
    final prefs = await _sharedPrefs;
    await prefs.remove(_counterDailyTargetKey(counterKey));
  }

  Future<NotificationPreferencesData> getNotificationPreferences() async {
    final prefs = await _sharedPrefs;
    return NotificationPreferencesData(
      onboardingReminderEnabled:
          prefs.getBool(onboardingReminderEnabled) ?? false,
      dailyPracticeNotificationsEnabled:
          prefs.getBool(dailyPracticeNotificationsEnabled) ?? false,
      dailyCountersEnabled: prefs.getBool(dailyCountersEnabled) ?? true,
      appLockEnabled: prefs.getBool(appLockEnabled) ?? true,
      onboardingReminderUpdatedAt: prefs.getString(onboardingReminderUpdatedAt),
      dailyPracticeNotificationsUpdatedAt:
          prefs.getString(dailyPracticeNotificationsUpdatedAt),
      dailyCountersUpdatedAt: prefs.getString(dailyCountersUpdatedAt),
      appLockUpdatedAt: prefs.getString(appLockUpdatedAt),
    );
  }

  Future<void> saveOnboardingReminderEnabled(bool enabled) async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(onboardingReminderEnabled, enabled);
    await prefs.setString(
      onboardingReminderUpdatedAt,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> saveDailyPracticeNotificationsEnabled(bool enabled) async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(dailyPracticeNotificationsEnabled, enabled);
    await prefs.setString(
      dailyPracticeNotificationsUpdatedAt,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> saveDailyCountersEnabled(bool enabled) async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(dailyCountersEnabled, enabled);
    await prefs.setString(
      dailyCountersUpdatedAt,
      DateTime.now().toIso8601String(),
    );
  }

  Future<bool> getAppLockEnabled() async {
    final prefs = await _sharedPrefs;
    return prefs.getBool(appLockEnabled) ?? true;
  }

  Future<void> saveAppLockEnabled(bool enabled) async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(appLockEnabled, enabled);
    await prefs.setString(
      appLockUpdatedAt,
      DateTime.now().toIso8601String(),
    );
  }

  Future<List<String>> getHomeSelectedWidgets() async {
    final prefs = await _sharedPrefs;
    return prefs.getStringList(homeSelectedWidgets) ??
        <String>[
          'counter_1',
          'counter_2',
          'counter_3',
          'counter_umbrella',
          'affirmation_1',
          'affirmation_2',
          'affirmation_3',
          'affirmation_umbrella',
        ];
  }

  Future<void> saveHomeSelectedWidgets(List<String> widgetIds) async {
    final prefs = await _sharedPrefs;
    await prefs.setStringList(homeSelectedWidgets, widgetIds);
  }

  String _todayKey() {
    final now = DateTime.now();
    return _dateKey(now);
  }

  String _dateKey(DateTime date) {
    final now = DateTime(date.year, date.month, date.day);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  String _dailyQuizYesSubjectsForDateKey(String dateKey) =>
      'daily_quiz_yes_subjects_$dateKey';

  String _dailyQuizDraftAnswersForDateKey(String dateKey) =>
      'daily_quiz_draft_answers_$dateKey';

  Future<void> saveDailyQuizResult(List<String> yesSubjects) async {
    final prefs = await _sharedPrefs;
    final today = _todayKey();

    await prefs.setString(dailyQuizCompletedDate, today);
    await prefs.setStringList(dailyQuizYesSubjects, yesSubjects);
    await prefs.setStringList(
        _dailyQuizYesSubjectsForDateKey(today), yesSubjects);

    final dates = prefs.getStringList(dailyQuizCompletedDates) ?? <String>[];
    if (!dates.contains(today)) {
      dates.add(today);
      await prefs.setStringList(dailyQuizCompletedDates, dates);
    }
  }

  Future<DailyQuizResultData?> getTodayDailyQuizResult() async {
    return getDailyQuizResultForDate(DateTime.now());
  }

  Future<void> saveDailyQuizDraft({
    required int currentQuestion,
    required List<bool?> answers,
  }) async {
    final prefs = await _sharedPrefs;
    final today = _todayKey();
    final encodedAnswers = answers
        .map((a) => a == true
            ? '1'
            : a == false
                ? '0'
                : 'x')
        .toList();

    await prefs.setString(dailyQuizDraftDate, today);
    await prefs.setInt(dailyQuizDraftQuestion, currentQuestion);
    await prefs.setStringList(
      _dailyQuizDraftAnswersForDateKey(today),
      encodedAnswers,
    );
  }

  Future<DailyQuizDraftData?> getTodayDailyQuizDraft() async {
    final prefs = await _sharedPrefs;
    final today = _todayKey();
    final draftDate = prefs.getString(dailyQuizDraftDate);

    if (draftDate != today) return null;

    final currentQuestion = prefs.getInt(dailyQuizDraftQuestion);
    final encodedAnswers =
        prefs.getStringList(_dailyQuizDraftAnswersForDateKey(today));

    if (currentQuestion == null || encodedAnswers == null) {
      return null;
    }

    final answers = encodedAnswers
        .map<bool?>((v) => v == '1'
            ? true
            : v == '0'
                ? false
                : null)
        .toList();

    return DailyQuizDraftData(
      currentQuestion: currentQuestion,
      answers: answers,
    );
  }

  Future<void> clearTodayDailyQuizDraft() async {
    final prefs = await _sharedPrefs;
    final today = _todayKey();
    await prefs.remove(dailyQuizDraftDate);
    await prefs.remove(dailyQuizDraftQuestion);
    await prefs.remove(_dailyQuizDraftAnswersForDateKey(today));
  }

  Future<DailyQuizResultData?> getDailyQuizResultForDate(DateTime date) async {
    final prefs = await _sharedPrefs;
    final dateKey = _dateKey(date);
    final completedDate = prefs.getString(dailyQuizCompletedDate);

    if (completedDate == dateKey) {
      return DailyQuizResultData(
        completedToday: true,
        yesSubjects: prefs.getStringList(dailyQuizYesSubjects) ?? <String>[],
      );
    }

    final storedForDate =
        prefs.getStringList(_dailyQuizYesSubjectsForDateKey(dateKey));
    if (storedForDate != null) {
      return DailyQuizResultData(
        completedToday: true,
        yesSubjects: storedForDate,
      );
    }

    return null;
  }

  Future<int> getCounterCountForDate(String counterKey, DateTime date) async {
    final prefs = await _sharedPrefs;
    final dayStart = DateTime(date.year, date.month, date.day);
    final nextDayStart = dayStart.add(const Duration(days: 1));

    final storedTimestamps =
        prefs.getStringList(_counterEventsKey(counterKey)) ?? [];

    return storedTimestamps.where((timestamp) {
      final parsed = DateTime.tryParse(timestamp);
      return parsed != null &&
          !parsed.isBefore(dayStart) &&
          parsed.isBefore(nextDayStart);
    }).length;
  }

  void dispose() {
    _umbrellaController.close();
  }

  Future<void> clearTodayDailyQuizResult() async {
    final prefs = await _sharedPrefs;
    final today = _todayKey();
    await prefs.remove(dailyQuizCompletedDate);
    await prefs.remove(dailyQuizYesSubjects);
    await prefs.remove(_dailyQuizYesSubjectsForDateKey(today));
    await clearTodayDailyQuizDraft();

    final dates = prefs.getStringList(dailyQuizCompletedDates) ?? <String>[];
    if (dates.contains(today)) {
      dates.remove(today);
      await prefs.setStringList(dailyQuizCompletedDates, dates);
    }
  }
}
