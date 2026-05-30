// audio_builder_widget.dart
//
// Thin public wrapper around AudioBuilderScreen so Setup can embed
// the recording + session-creation flow without importing the full
// AudioScreen shell.
//
// Usage in setup.dart:
//   import 'audio_builder_widget.dart';
//   ...
//   const AudioSessionBuilderWidget()

export 'audio.dart' show AudioBuilderScreen;

import 'package:flutter/material.dart';
import 'audio.dart';

/// Drop this anywhere in Setup to let the user record four affirmations
/// and render the 5-minute session WAV.
class AudioSessionBuilderWidget extends StatelessWidget {
  const AudioSessionBuilderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AudioBuilderScreen(embedded: true);
  }
}
