import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'app_card_surface.dart';
import 'app_buttons.dart';

class AudioAffirmationCard extends StatefulWidget {
  final String label;
  final int index;
  final FlutterSoundRecorder? recorder;
  final bool isRecorderInitialized;
  final String? recordedFilePath;
  final VoidCallback? onKept;

  const AudioAffirmationCard({
    super.key,
    required this.label,
    required this.index,
    required this.recorder,
    required this.isRecorderInitialized,
    this.recordedFilePath,
    this.onKept,
  });

  @override
  State<AudioAffirmationCard> createState() => _AudioAffirmationCardState();
}

class _AudioAffirmationCardState extends State<AudioAffirmationCard> {
  bool isActive = false;
  bool hasRecording = false;
  bool isRecording = false;
  bool isPlaying = false;
  bool kept = false;
  String? filePath;

  Future<void> _startRecording() async {
    if (widget.recorder == null || !widget.isRecorderInitialized) return;
    final dir = await getApplicationDocumentsDirectory();
    filePath = '${dir.path}/affirmation_${widget.index}.aac';
    await widget.recorder!.startRecorder(toFile: filePath);
    setState(() {
      isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    if (widget.recorder == null || !widget.isRecorderInitialized) return;
    await widget.recorder!.stopRecorder();
    setState(() {
      isRecording = false;
      hasRecording = true;
    });
  }

  void _reset() {
    setState(() {
      isActive = false;
      hasRecording = false;
      isRecording = false;
      isPlaying = false;
      kept = false;
      filePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSelectionPillButton(
            label: widget.label,
            selected: isActive || kept,
            onTap: () {
              setState(() {
                isActive = true;
              });
            },
          ),
          if (isActive && !isRecording && !isPlaying)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!hasRecording)
                   AppSelectionPillButton (
                      label: 'Record',
                      selected: false,
                      onTap: _startRecording,
                    ),
                  if (hasRecording)
                    AppSelectionPillButton(
                      label: 'Listen',
                      selected: false,
                      onTap: () {
                        setState(() {
                          isPlaying = true;
                        });
                        // Add playback logic here
                      },
                    ),
                  if (hasRecording)
                    AppSelectionPillButton(
                      label: 'Retake',
                      selected: false,
                      onTap: _startRecording,
                    ),
                  AppSelectionPillButton(
                    label: 'Cancel',
                    selected: false,
                    onTap: _reset,
                  ),
                ],
              ),
            ),
          if (isActive && isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AppSelectionPillButton(
                    label: 'Stop',
                    selected: false,
                    onTap: _stopRecording,
                  ),
                  AppSelectionPillButton(
                    label: 'Cancel',
                    selected: false,
                    onTap: _reset,
                  ),
                ],
              ),
            ),
          if (isActive && isPlaying)
            AlertDialog(
              title: const Text('Playback'),
              content: const Text('Playing your recording...'),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      kept = true;
                      isPlaying = false;
                      isActive = false;
                    });
                    if (widget.onKept != null) widget.onKept!();
                  },
                  child: const Text('Keep it'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isRecording = true;
                      hasRecording = false;
                      isPlaying = false;
                    });
                    _startRecording();
                  },
                  child: const Text('Re-record'),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          if (kept)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(Icons.check_circle, color: Colors.green, size: 22),
            ),
        ],
      ),
    );
  }
}
