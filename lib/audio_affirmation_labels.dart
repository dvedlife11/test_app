import 'app_repository.dart';

class AudioAffirmationOption {
  final int slotIndex;
  final String label;

  const AudioAffirmationOption({
    required this.slotIndex,
    required this.label,
  });
}

/// Utility to fetch the display label for each affirmation slot (A1, A2, A3, umbrella)
/// If the user has a stored value, it returns that, otherwise returns the fallback.
class AudioAffirmationLabels {
  final AppRepository repository;
  final List<String> fallbackAffirmations;

  static const Map<String, String> umbrellaLabels = {
    'umbrella_1': 'I always get what I want',
    'umbrella_2': 'Everything is wonderful',
    'umbrella_3': 'I am in love with my life',
    'umbrella_none': 'No umbrella affirmation for me',
    'umbrella_prompt': 'Select umbrella affirmation',
  };

  AudioAffirmationLabels({
    required this.repository,
    required this.fallbackAffirmations,
  });

  /// Returns a Future list of display labels for the audio screen.
  Future<List<String>> getLabels() async {
    final a1 = await repository.getAffirmationText('affirmation_1');
    final a2 = await repository.getAffirmationText('affirmation_2');
    final a3 = await repository.getAffirmationText('affirmation_3');
    final umbrellaKey = await repository.getSelectedUmbrella();
    final umbrellaLabel = umbrellaLabels[umbrellaKey] ?? '';

    // Collect only non-empty affirmations and umbrella
    final List<String> saved = [];
    if (a1.isNotEmpty) saved.add(a1);
    if (a2.isNotEmpty) saved.add(a2);
    if (a3.isNotEmpty) saved.add(a3);
    if (umbrellaKey != 'umbrella_prompt' &&
        umbrellaKey != 'umbrella_none' &&
        umbrellaLabel.isNotEmpty) {
      saved.add(umbrellaLabel);
    }

    // If nothing is saved, show only the first fallback
    if (saved.isEmpty) {
      return [fallbackAffirmations[0]];
    }
    return saved;
  }

  /// Backward-compatible API used by newer audio builder code.
  Future<List<AudioAffirmationOption>> getOptions() async {
    final a1 = (await repository.getAffirmationText('affirmation_1')).trim();
    final a2 = (await repository.getAffirmationText('affirmation_2')).trim();
    final a3 = (await repository.getAffirmationText('affirmation_3')).trim();
    final umbrellaKey = await repository.getSelectedUmbrella();
    final umbrellaLabel = umbrellaLabels[umbrellaKey] ?? '';

    final options = <AudioAffirmationOption>[];
    if (a1.isNotEmpty) {
      options.add(AudioAffirmationOption(slotIndex: 0, label: a1));
    }
    if (a2.isNotEmpty) {
      options.add(AudioAffirmationOption(slotIndex: 1, label: a2));
    }
    if (a3.isNotEmpty) {
      options.add(AudioAffirmationOption(slotIndex: 2, label: a3));
    }
    if (umbrellaKey != 'umbrella_prompt' &&
        umbrellaKey != 'umbrella_none' &&
        umbrellaLabel.isNotEmpty) {
      options.add(AudioAffirmationOption(slotIndex: 3, label: umbrellaLabel));
    }

    if (options.isEmpty) {
      return [
        AudioAffirmationOption(slotIndex: 0, label: fallbackAffirmations[0]),
      ];
    }

    return options;
  }
}
