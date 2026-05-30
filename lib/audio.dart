import 'package:flutter/material.dart';
import 'app_card_surface.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'navigation_grid.dart';
import 'app_buttons.dart';
import 'app_repository.dart';
import 'audio_affirmation_labels.dart';
import 'app_bottom_popup.dart';
import 'design_system.dart';

// Audio page color constants (fallbacks for missing _audio* values)
const Color _audioCard = Color(0xFF1A1A1A);
const Color _audioBorder = Color(0x1FFFFFFF);
const Color _audioTextPrimary = Colors.white;
const Color _audioTextSecondary = Color(0xFF9C9C9C);
const Color _audioBody = Color(0xFFB5B5B5);
const Color _audioNavCard = Color(0xFF141414);

class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AudioBuilderScreen(),
    );
  }
}

class AudioBuilderScreen extends StatefulWidget {
  final bool embedded;

  const AudioBuilderScreen({super.key, this.embedded = false});

  @override
  State<AudioBuilderScreen> createState() => _AudioBuilderScreenState();
}

class _AudioBuilderScreenState extends State<AudioBuilderScreen> {
  static const String _rainAssetPath =
      'assets/data/5 Minute Timer with Rain Sounds  Timers.mp3';
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  FlutterSoundPlayer? _rainPlayer;
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  bool _isRainPlayerInitialized = false;
  String? _rainAssetFilePath;
  Map<int, String> _recordedFilePaths = {};
  final Map<int, DateTime> _recordingStartedAt = <int, DateTime>{};
  final Map<int, Duration> _recordedDurations = <int, Duration>{};
  String? _lastSessionPlanPath;
  String? _lastRenderedSessionPath;
  String? _selectedRenderedSessionPath;
  String? _sessionBackgroundSound;
  DateTime? _sessionCreatedAt;
  DateTime? _currentRenderedFileAt;
  List<_RenderedSessionItem> _renderedSessions = <_RenderedSessionItem>[];
  List<_SessionSegment> _sessionPlan = <_SessionSegment>[];
  Duration _sessionCurrent = Duration.zero;
  static const Duration _sessionTotal = Duration(minutes: 5);
  bool _isSessionPlaying = false;
  DateTime? _sessionStartedAt;
  Timer? _sessionProgressTimer;
  int _sessionPlaybackToken = 0;
  int? _playingIndex;
  bool get _isWeb => kIsWeb;

  // Add persistent state for each affirmation
  List<Map<String, dynamic>> _affirmationStates = [];
  final AppRepository _repository = AppRepository();
  static const List<String> _fallbackAffirmations = [
    'Affirmation 1',
    'Affirmation 2',
    'Affirmation 3',
    'Umbrella affirmation',
  ];
  late final AudioAffirmationLabels _labelsUtil = AudioAffirmationLabels(
    repository: _repository,
    fallbackAffirmations: _fallbackAffirmations,
  );

  @override
  void initState() {
    super.initState();
    if (!_isWeb) {
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();
      _rainPlayer = FlutterSoundPlayer();
      _initRecorder();
      _initPlayer();
      _initRainPlayer();
    }
    // Initialize state for each affirmation (always 4: 3 + umbrella)
    _affirmationStates = List.generate(
        4,
        (index) => {
              'active': false,
              'hasRecording': false,
              'isRecording': false,
              'isPlaying': false,
              'kept': false,
            });

    _loadSavedSessionPlan();
    _loadRenderedSessionsFromDisk();
  }

  Future<void> _initRecorder() async {
    if (_recorder != null) {
      await _recorder!.openRecorder();
      setState(() {
        _isRecorderInitialized = true;
      });
    }
  }

  Future<void> _initPlayer() async {
    if (_player != null) {
      await _player!.openPlayer();
      await _player!.setVolume(1.0);
      setState(() {
        _isPlayerInitialized = true;
      });
    }
  }

  Future<void> _initRainPlayer() async {
    if (_rainPlayer != null) {
      await _rainPlayer!.openPlayer();
      await _rainPlayer!.setVolume(0.15);
      setState(() {
        _isRainPlayerInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _sessionProgressTimer?.cancel();
    if (_recorder != null) {
      _recorder!.closeRecorder();
    }
    if (_player != null) {
      _player!.closePlayer();
    }
    if (_rainPlayer != null) {
      _rainPlayer!.closePlayer();
    }
    super.dispose();
  }

  Future<void> _startRecording(int index) async {
    if (_isWeb || !_isRecorderInitialized) return;
    await _stopRainBed();
    if (_isSessionPlaying) {
      await _stopSessionPlayback();
    }
    if (_playingIndex != null) {
      await _stopPlayback();
    }
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/affirmation_$index.wav';
    _recordingStartedAt[index] = DateTime.now();
    await _recorder!.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
      numChannels: 1,
      sampleRate: 16000,
    );
    setState(() {
      _sessionStatus = 'Recording...';
    });
  }

  Future<void> _stopRecording(int index) async {
    if (_isWeb || !_isRecorderInitialized) return;
    final filePath = await _recorder!.stopRecorder();
    final startedAt = _recordingStartedAt[index];
    final measuredDuration = startedAt == null
        ? const Duration(seconds: 1)
        : DateTime.now().difference(startedAt);
    if (filePath == null) {
      if (!mounted) return;
      setState(() {
        _affirmationStates[index]['hasRecording'] = false;
        _sessionStatus =
            'No audio file was captured. Please try recording again.';
      });
      return;
    }

    final initialStats = await _inspectRecordedAudio(filePath);
    final isEmptyOrTooShort = initialStats == null ||
        !initialStats.hasAudioData ||
        initialStats.fileSizeBytes <= 44 ||
        initialStats.durationMs < 120;
    if (isEmptyOrTooShort) {
      if (!mounted) return;
      setState(() {
        _affirmationStates[index]['hasRecording'] = false;
        _recordedFilePaths.remove(index);
        _recordedDurations.remove(index);
        _sessionStatus =
            'Recording seems empty. Please speak closer to the mic and try again.';
      });
      return;
    }

    final needsAggressiveBoost =
        initialStats.peak < 1200 || initialStats.averageAbs < 140;

    await _normalizeWavFileIfNeeded(
      filePath,
      targetPeak: needsAggressiveBoost ? 32000 : 30000,
      maxGain: needsAggressiveBoost ? 64.0 : 20.0,
    );

    final finalStats = await _inspectRecordedAudio(filePath);
    final stillVeryQuiet = finalStats != null &&
        (finalStats.peak < 400 || finalStats.averageAbs < 60);

    if (!mounted) return;
    setState(() {
      _recordedFilePaths[index] = filePath;
      _recordedDurations[index] = measuredDuration;
      _affirmationStates[index]['hasRecording'] = true;
      _sessionStatus = stillVeryQuiet
          ? 'Recorded affirmation ${index + 1} (very quiet source captured)'
          : 'Recorded affirmation ${index + 1}';
    });
  }

  Future<void> _playRecording(int index) async {
    if (_isWeb || !_isPlayerInitialized) return;
    await _stopRainBed();
    if (_isSessionPlaying) {
      await _stopSessionPlayback();
    }
    final filePath = _recordedFilePaths[index];
    if (filePath == null) return;

    final stats = await _inspectRecordedAudio(filePath);
    final needsAggressiveBoost =
        stats == null || stats.peak < 1200 || stats.averageAbs < 140;

    await _normalizeWavFileIfNeeded(
      filePath,
      targetPeak: needsAggressiveBoost ? 32000 : 30000,
      maxGain: needsAggressiveBoost ? 64.0 : 20.0,
    );

    if (_playingIndex != null) {
      await _stopPlayback();
    }

    await _player!.startPlayer(
      fromURI: filePath,
      whenFinished: () {
        if (!mounted) return;
        setState(() {
          _playingIndex = null;
          _affirmationStates[index]['isPlaying'] = false;
          _sessionStatus = 'Playback finished';
        });
      },
    );

    setState(() {
      _playingIndex = index;
      _affirmationStates[index]['isPlaying'] = true;
      _sessionStatus = 'Playing affirmation ${index + 1}';
    });
  }

  Future<void> _stopPlayback() async {
    if (_isWeb || !_isPlayerInitialized) return;
    if (_playingIndex == null) return;

    final index = _playingIndex!;
    await _player!.stopPlayer();
    if (!mounted) return;
    setState(() {
      _playingIndex = null;
      _affirmationStates[index]['isPlaying'] = false;
      _sessionStatus = 'Playback stopped';
    });
  }

  void _keepRecording(int index) {
    setState(() {
      _affirmationStates[index]['kept'] = true;
      _affirmationStates[index]['isPlaying'] = false;
      _affirmationStates[index]['active'] = false;
      _selectedAffirmationIndexes.add(index);
      _sessionStatus = 'Saved affirmation ${index + 1}';
    });

    // After user accepts the take, trim leading/trailing silence in-place.
    _trimKeptRecording(index);
  }

  Future<void> _trimKeptRecording(int index) async {
    final filePath = _recordedFilePaths[index];
    if (filePath == null || !filePath.toLowerCase().endsWith('.wav')) return;

    final trimmed = await _trimWavFileSilence(
      filePath,
      amplitudeThreshold: 700,
      keepPaddingMs: 120,
    );

    if (trimmed == null || !mounted) return;

    setState(() {
      _recordedFilePaths[index] = trimmed.filePath;
      _recordedDurations[index] = trimmed.trimmedDuration;
      _sessionStatus =
          'Saved affirmation ${index + 1} (trimmed ${(trimmed.removedMs / 1000).toStringAsFixed(2)}s silence)';
    });
  }

  Future<_TrimResult?> _trimWavFileSilence(
    String filePath, {
    required int amplitudeThreshold,
    required int keepPaddingMs,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    if (bytes.length < 44) return null;

    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') return null;

    final bd = ByteData.sublistView(bytes);
    var offset = 12;
    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    int? dataOffset;
    int? dataSize;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = bd.getUint32(offset + 4, Endian.little);
      final chunkDataStart = offset + 8;
      final next = chunkDataStart + chunkSize + (chunkSize.isOdd ? 1 : 0);
      if (next > bytes.length) break;

      if (chunkId == 'fmt ' && chunkSize >= 16) {
        channels = bd.getUint16(chunkDataStart + 2, Endian.little);
        sampleRate = bd.getUint32(chunkDataStart + 4, Endian.little);
        bitsPerSample = bd.getUint16(chunkDataStart + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = chunkDataStart;
        dataSize = chunkSize;
      }

      offset = next;
    }

    if (channels == null ||
        sampleRate == null ||
        bitsPerSample != 16 ||
        dataOffset == null ||
        dataSize == null) {
      return null;
    }

    final bytesPerSample = bitsPerSample! ~/ 8;
    final blockAlign = channels * bytesPerSample;
    if (blockAlign <= 0 || dataSize < blockAlign) return null;

    final totalFrames = dataSize ~/ blockAlign;
    int firstLoud = -1;
    int lastLoud = -1;

    for (var frame = 0; frame < totalFrames; frame++) {
      final frameStart = dataOffset + frame * blockAlign;
      var framePeak = 0;
      for (var ch = 0; ch < channels; ch++) {
        final sampleOffset = frameStart + ch * bytesPerSample;
        final sample = bd.getInt16(sampleOffset, Endian.little).abs();
        if (sample > framePeak) framePeak = sample;
      }

      if (framePeak >= amplitudeThreshold) {
        if (firstLoud == -1) firstLoud = frame;
        lastLoud = frame;
      }
    }

    if (firstLoud == -1 || lastLoud == -1) return null;

    // If the recording ends with a very short loud burst, it is usually a
    // button-release click rather than spoken audio. Drop that tail burst so
    // it does not get baked into the rendered session.
    final transientTailStart = _findTrailingLoudRunStartFrame(
      bd,
      dataOffset: dataOffset,
      totalFrames: totalFrames,
      blockAlign: blockAlign,
      channels: channels,
      fromFrame: lastLoud,
      amplitudeThreshold: amplitudeThreshold,
    );
    if (transientTailStart != null) {
      final transientTailLength = lastLoud - transientTailStart + 1;
      final transientTailMaxFrames = (sampleRate * 60 / 1000).round();
      if (transientTailLength > 0 &&
          transientTailLength <= transientTailMaxFrames &&
          transientTailStart > firstLoud) {
        lastLoud = transientTailStart - 1;
      }
    }

    final paddingFrames = (sampleRate * keepPaddingMs / 1000).round();
    var startFrame = (firstLoud - paddingFrames).clamp(0, totalFrames - 1);
    var endFrame = (lastLoud + paddingFrames).clamp(0, totalFrames - 1);

    // Snap cut points to low-amplitude frames to avoid hard-cut clicks.
    final snapRadiusFrames = (sampleRate * 25 / 1000).round();
    startFrame = _findLowestAmplitudeFrame(
      bd,
      dataOffset: dataOffset,
      totalFrames: totalFrames,
      blockAlign: blockAlign,
      channels: channels,
      centerFrame: startFrame,
      radiusFrames: snapRadiusFrames,
    );
    endFrame = _findLowestAmplitudeFrame(
      bd,
      dataOffset: dataOffset,
      totalFrames: totalFrames,
      blockAlign: blockAlign,
      channels: channels,
      centerFrame: endFrame,
      radiusFrames: snapRadiusFrames,
    );
    if (endFrame <= startFrame) {
      endFrame = (startFrame + 1).clamp(0, totalFrames - 1);
    }

    final keptFrames = endFrame - startFrame + 1;
    final trimmedPcm = Uint8List.fromList(bytes.sublist(
      dataOffset + startFrame * blockAlign,
      dataOffset + (endFrame + 1) * blockAlign,
    ));

    // Declick hard boundaries by fading the first/last few milliseconds.
    _applyEdgeFadesPcm16(
      trimmedPcm,
      channels: channels,
      sampleRate: sampleRate,
      fadeMs: 32,
    );

    _normalizePcm16ToTargetPeak(
      trimmedPcm,
      targetPeak: 30000,
      maxGain: 12.0,
    );

    final rebuilt = _buildWavPcm16(
      pcmData: trimmedPcm,
      sampleRate: sampleRate,
      channels: channels,
    );

    await file.writeAsBytes(rebuilt, flush: true);

    final originalMs = 1000 * totalFrames ~/ sampleRate;
    final trimmedMs = 1000 * keptFrames ~/ sampleRate;
    final removedMs = (originalMs - trimmedMs).clamp(0, originalMs);

    return _TrimResult(
      filePath: filePath,
      trimmedDuration: Duration(milliseconds: trimmedMs),
      removedMs: removedMs,
    );
  }

  Future<void> _normalizeWavFileIfNeeded(
    String filePath, {
    int targetPeak = 30000,
    double maxGain = 16.0,
  }) async {
    final parsed = await _readWavPcm16(filePath);
    if (parsed == null) return;

    final peak = _pcm16Peak(parsed.pcmData);
    if (peak <= 0) return;

    final neededGain = targetPeak / peak;
    if (neededGain <= 1.01) return;

    _normalizePcm16ToTargetPeak(
      parsed.pcmData,
      targetPeak: targetPeak,
      maxGain: maxGain,
    );

    final rebuilt = _buildWavPcm16(
      pcmData: parsed.pcmData,
      sampleRate: parsed.sampleRate,
      channels: parsed.channels,
    );
    await File(filePath).writeAsBytes(rebuilt, flush: true);
  }

  Future<_RecordedAudioStats?> _inspectRecordedAudio(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final fileStat = await file.stat();
    final parsed = await _readWavPcm16(filePath);
    if (parsed == null) {
      return _RecordedAudioStats(
        fileSizeBytes: fileStat.size,
        durationMs: 0,
        peak: 0,
        averageAbs: 0,
        hasAudioData: fileStat.size > 44,
      );
    }

    final sampleCount = parsed.pcmData.length ~/ 2;
    final totalFrames =
        parsed.channels <= 0 ? 0 : sampleCount ~/ parsed.channels;
    final durationMs =
        parsed.sampleRate <= 0 ? 0 : (1000 * totalFrames ~/ parsed.sampleRate);

    return _RecordedAudioStats(
      fileSizeBytes: fileStat.size,
      durationMs: durationMs,
      peak: _pcm16Peak(parsed.pcmData),
      averageAbs: _pcm16AverageAbs(parsed.pcmData),
      hasAudioData: parsed.pcmData.isNotEmpty,
    );
  }

  int _pcm16Peak(Uint8List pcmData) {
    final bd = ByteData.sublistView(pcmData);
    var peak = 0;
    for (var i = 0; i + 1 < pcmData.length; i += 2) {
      final v = bd.getInt16(i, Endian.little).abs();
      if (v > peak) peak = v;
    }
    return peak;
  }

  double _pcm16AverageAbs(Uint8List pcmData) {
    if (pcmData.length < 2) return 0;
    final bd = ByteData.sublistView(pcmData);
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i + 1 < pcmData.length; i += 2) {
      sum += bd.getInt16(i, Endian.little).abs().toDouble();
      count++;
    }
    if (count == 0) return 0;
    return sum / count;
  }

  void _normalizePcm16ToTargetPeak(
    Uint8List pcmData, {
    required int targetPeak,
    double maxGain = 6.0,
  }) {
    if (pcmData.length < 2) return;

    final currentPeak = _pcm16Peak(pcmData);
    if (currentPeak <= 0) return;

    var gain = targetPeak / currentPeak;
    if (gain <= 1.0) return;
    if (gain > maxGain) gain = maxGain;

    final bd = ByteData.sublistView(pcmData);
    for (var i = 0; i + 1 < pcmData.length; i += 2) {
      var sample = (bd.getInt16(i, Endian.little) * gain).round();
      if (sample > 32767) sample = 32767;
      if (sample < -32768) sample = -32768;
      bd.setInt16(i, sample, Endian.little);
    }
  }

  Uint8List _buildWavPcm16({
    required List<int> pcmData,
    required int sampleRate,
    required int channels,
  }) {
    const bitsPerSample = 16;
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final byteRate = sampleRate * blockAlign;
    final dataSize = pcmData.length;
    final totalSize = 44 + dataSize;

    final out = Uint8List(totalSize);
    final bd = ByteData.sublistView(out);

    out.setRange(0, 4, 'RIFF'.codeUnits);
    bd.setUint32(4, totalSize - 8, Endian.little);
    out.setRange(8, 12, 'WAVE'.codeUnits);
    out.setRange(12, 16, 'fmt '.codeUnits);
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, channels, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, byteRate, Endian.little);
    bd.setUint16(32, blockAlign, Endian.little);
    bd.setUint16(34, bitsPerSample, Endian.little);
    out.setRange(36, 40, 'data'.codeUnits);
    bd.setUint32(40, dataSize, Endian.little);
    out.setRange(44, totalSize, pcmData);

    return out;
  }

  void _applyEdgeFadesPcm16(
    Uint8List pcmData, {
    required int channels,
    required int sampleRate,
    int fadeMs = 20,
  }) {
    final blockAlign = channels * 2;
    if (blockAlign <= 0 || pcmData.length < blockAlign * 2) return;

    final totalFrames = pcmData.length ~/ blockAlign;
    var fadeFrames = (sampleRate * fadeMs / 1000).round();
    if (fadeFrames <= 0) return;
    if (fadeFrames * 2 > totalFrames) {
      fadeFrames = totalFrames ~/ 2;
    }
    if (fadeFrames <= 0) return;

    final bd = ByteData.sublistView(pcmData);

    final denom = fadeFrames - 1;
    for (var i = 0; i < fadeFrames; i++) {
      final inGain = denom <= 0 ? 0.0 : i / denom;
      final outGain = denom <= 0 ? 0.0 : (denom - i) / denom;

      final startFrameOffset = i * blockAlign;
      final endFrame = totalFrames - 1 - i;
      final endFrameOffset = endFrame * blockAlign;

      for (var ch = 0; ch < channels; ch++) {
        final sampleOffsetStart = startFrameOffset + ch * 2;
        final startSample = bd.getInt16(sampleOffsetStart, Endian.little);
        var fadedStart = (startSample * inGain).round();
        if (fadedStart > 32767) fadedStart = 32767;
        if (fadedStart < -32768) fadedStart = -32768;
        bd.setInt16(sampleOffsetStart, fadedStart, Endian.little);

        final sampleOffsetEnd = endFrameOffset + ch * 2;
        final endSample = bd.getInt16(sampleOffsetEnd, Endian.little);
        var fadedEnd = (endSample * outGain).round();
        if (fadedEnd > 32767) fadedEnd = 32767;
        if (fadedEnd < -32768) fadedEnd = -32768;
        bd.setInt16(sampleOffsetEnd, fadedEnd, Endian.little);
      }
    }
  }

  int _findLowestAmplitudeFrame(
    ByteData bd, {
    required int dataOffset,
    required int totalFrames,
    required int blockAlign,
    required int channels,
    required int centerFrame,
    required int radiusFrames,
  }) {
    var bestFrame = centerFrame;
    var bestAmp = 1 << 30;

    final start = (centerFrame - radiusFrames).clamp(0, totalFrames - 1);
    final end = (centerFrame + radiusFrames).clamp(0, totalFrames - 1);

    for (var frame = start; frame <= end; frame++) {
      final frameOffset = dataOffset + frame * blockAlign;
      var peak = 0;
      for (var ch = 0; ch < channels; ch++) {
        final sample = bd.getInt16(frameOffset + ch * 2, Endian.little).abs();
        if (sample > peak) {
          peak = sample;
        }
      }
      if (peak < bestAmp) {
        bestAmp = peak;
        bestFrame = frame;
        if (bestAmp == 0) {
          break;
        }
      }
    }

    return bestFrame;
  }

  int? _findTrailingLoudRunStartFrame(
    ByteData bd, {
    required int dataOffset,
    required int totalFrames,
    required int blockAlign,
    required int channels,
    required int fromFrame,
    required int amplitudeThreshold,
  }) {
    if (fromFrame < 0 || fromFrame >= totalFrames) return null;

    var runStart = fromFrame;
    while (runStart > 0) {
      final frameOffset = dataOffset + (runStart - 1) * blockAlign;
      var framePeak = 0;
      for (var ch = 0; ch < channels; ch++) {
        final sample = bd.getInt16(frameOffset + ch * 2, Endian.little).abs();
        if (sample > framePeak) framePeak = sample;
      }
      if (framePeak < amplitudeThreshold) {
        break;
      }
      runStart--;
    }

    return runStart;
  }

  Set<int> _selectedAffirmationIndexes = <int>{};
  String? _selectedBackground;
  String? _sessionStatus;

  void _toggleSessionAffirmation(int index) {
    setState(() {
      if (_selectedAffirmationIndexes.contains(index)) {
        _selectedAffirmationIndexes.remove(index);
      } else {
        _selectedAffirmationIndexes.add(index);
      }
      _sessionStatus = null;
    });
  }

  void _selectBackground(String background) {
    setState(() {
      _selectedBackground = background;
      _sessionStatus = null;
    });
  }

  Future<void> _createSessionFile() async {
    if (_selectedBackground == null) {
      setState(() {
        _sessionStatus = 'Choose a background sound first.';
      });
      return;
    }

    _syncSelectedAffirmationsFromKeptRecordings();

    if (_selectedAffirmationIndexes.isEmpty) {
      setState(() {
        _sessionStatus = 'Select at least 1 affirmation first.';
      });
      return;
    }

    final selectedIndexes = _selectedAffirmationIndexes.toList()..sort();
    final missingIndexes = <int>[];
    for (final i in selectedIndexes) {
      final kept = _affirmationStates[i]['kept'] == true;
      if (!kept || !_recordedFilePaths.containsKey(i)) {
        missingIndexes.add(i);
      }
    }

    if (missingIndexes.isNotEmpty) {
      setState(() {
        _sessionStatus =
            'Keep recordings for selected affirmations first (missing: ${missingIndexes.map((e) => 'A${e + 1}').join(', ')})';
      });
      return;
    }

    try {
      final createdAt = DateTime.now();
      _sessionBackgroundSound = _selectedBackground;
      final plan = _buildFiveMinuteSessionPlan();
      if (plan.isEmpty) {
        setState(() {
          _sessionStatus =
              'No usable clips found for session. Re-record and keep at least one track.';
        });
        return;
      }
      final trackUsage = _countTrackUsage(plan);
      await _repository.saveAudioSessionTrackUsage(trackUsage);
      final renderedPath = await _renderSessionWav(
        plan,
        fileStamp: createdAt,
      );
      if (renderedPath == null) {
        setState(() {
          _sessionStatus =
              'Could not render session audio. Please re-record and try again.';
        });
        return;
      }
      final planPath = await _saveSessionPlan(
        plan,
        renderedPath: renderedPath,
        createdAt: createdAt,
      );

      setState(() {
        _lastSessionPlanPath = planPath;
        _lastRenderedSessionPath = renderedPath;
        _selectedRenderedSessionPath = renderedPath;
        _sessionCreatedAt = createdAt;
        _currentRenderedFileAt =
            _extractRenderedFileTimestamp(renderedPath) ?? createdAt;
        _sessionPlan = plan;
        _sessionCurrent = Duration.zero;
        _sessionStatus = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text(
              'File ready: 5:00 session created with ${_sessionBackgroundSound == 'rain' ? 'rain background' : 'no background sound'}. Saved locally on device (not downloaded).',
            ),
          ),
        );
      }

      await _loadRenderedSessionsFromDisk();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sessionStatus =
            'Session file creation failed. Please try again after recording one more take.';
      });
    }
  }

  void _syncSelectedAffirmationsFromKeptRecordings() {
    final synced = <int>{};
    for (var i = 0; i < _affirmationStates.length; i++) {
      final kept = _affirmationStates[i]['kept'] == true;
      final hasRecorded = _recordedFilePaths.containsKey(i);
      if (kept && hasRecorded) {
        synced.add(i);
      }
    }
    _selectedAffirmationIndexes
      ..clear()
      ..addAll(synced);
  }

  Map<int, int> _countTrackUsage(List<_SessionSegment> plan) {
    final usage = <int, int>{};
    for (final segment in plan) {
      if (segment.kind != 'clip' || segment.affirmationIndex == null) {
        continue;
      }
      final idx = segment.affirmationIndex!;
      usage[idx] = (usage[idx] ?? 0) + 1;
    }
    return usage;
  }

  String _formatTrackUsage(Map<int, int> usage) {
    final parts = <String>[];
    for (var i = 0; i < 4; i++) {
      parts.add('A${i + 1}: ${usage[i] ?? 0}x');
    }
    return 'Track usage -> ${parts.join(' | ')}';
  }

  Future<void> _loadSavedSessionPlan() async {
    if (_isWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/session_file_plan.json');
      if (!await file.exists()) return;

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final planJson = decoded['plan'];
      if (planJson is! List) return;
      final renderedPath = decoded['renderedWavPath']?.toString();
      final backgroundSound = decoded['backgroundSound']?.toString();
      final createdAtRaw = decoded['createdAt']?.toString();
      var createdAt =
          createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);
      createdAt ??= await file.lastModified();

      final loadedPlan = planJson
          .whereType<Map>()
          .map((entry) => _SessionSegment.fromJson(
                Map<String, dynamic>.from(entry),
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _lastSessionPlanPath = file.path;
        _lastRenderedSessionPath = renderedPath;
        _selectedRenderedSessionPath = renderedPath;
        _sessionBackgroundSound = backgroundSound;
        if (_selectedBackground == null &&
            (backgroundSound == 'rain' || backgroundSound == 'none')) {
          _selectedBackground = backgroundSound;
        }
        _sessionCreatedAt = createdAt;
        _currentRenderedFileAt = renderedPath == null
            ? createdAt
            : (_extractRenderedFileTimestamp(renderedPath) ?? createdAt);
        _sessionPlan = loadedPlan;
      });

      await _loadRenderedSessionsFromDisk();
    } catch (_) {
      // Keep UI usable even if a stale/corrupt saved plan exists.
    }
  }

  Future<void> _loadRenderedSessionsFromDisk() async {
    if (_isWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final items = <_RenderedSessionItem>[];

      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final path = entity.path;
        final name = path.split('/').last;
        final match = RegExp(r'^session_render_(\d+)\.wav$').firstMatch(name);
        if (match == null) continue;

        DateTime? created = _extractRenderedFileTimestamp(path);
        created ??= await entity.lastModified();

        items.add(
          _RenderedSessionItem(
            path: path,
            createdAt: created,
          ),
        );
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Keep a rolling history of the last two rendered session files.
      final kept = items.take(2).toList();
      final stale = items.skip(2).toList();
      for (final old in stale) {
        File(old.path).delete().catchError((_) {});
      }

      if (!mounted) return;
      setState(() {
        _renderedSessions = kept;
        if (_selectedRenderedSessionPath != null &&
            !_renderedSessions
                .any((e) => e.path == _selectedRenderedSessionPath)) {
          _selectedRenderedSessionPath = null;
        }
        _selectedRenderedSessionPath ??= _lastRenderedSessionPath;
        _selectedRenderedSessionPath ??=
            _renderedSessions.isNotEmpty ? _renderedSessions.first.path : null;
        _lastRenderedSessionPath = _selectedRenderedSessionPath;
      });
    } catch (_) {
      // Non-fatal: user can still create/play latest session directly.
    }
  }

  void _selectRenderedSession(String path) {
    final selected = _renderedSessions.where((e) => e.path == path).toList();
    final ts = selected.isNotEmpty
        ? selected.first.createdAt
        : (_extractRenderedFileTimestamp(path) ?? _sessionCreatedAt);

    setState(() {
      _selectedRenderedSessionPath = path;
      _lastRenderedSessionPath = path;
      _currentRenderedFileAt = ts;
      _sessionStatus = 'Selected audio file for playback';
    });

    // Persist the selected file so Home player uses the same chosen track.
    unawaited(
      _saveSessionPlan(
        _sessionPlan,
        renderedPath: path,
        createdAt: ts,
      ),
    );
  }

  void _startSessionProgressTicker() {
    _sessionProgressTimer?.cancel();
    _sessionProgressTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) {
        if (!_isSessionPlaying || _sessionStartedAt == null || !mounted) return;
        final elapsed = DateTime.now().difference(_sessionStartedAt!);
        setState(() {
          _sessionCurrent = elapsed > _sessionTotal ? _sessionTotal : elapsed;
        });
      },
    );
  }

  Future<void> _toggleSessionPlayback() async {
    if (_isSessionPlaying) {
      await _stopSessionPlayback();
      return;
    }
    await _startSessionPlayback();
  }

  Future<void> _startSessionPlayback() async {
    if (_isWeb || !_isPlayerInitialized) return;

    if (_sessionPlan.isEmpty) {
      await _loadSavedSessionPlan();
      if (_sessionPlan.isEmpty) {
        setState(() {
          _sessionStatus = 'Create a session file first.';
        });
        return;
      }
    }

    if (_playingIndex != null) {
      await _stopPlayback();
    }

    await _stopSessionPlayback();

    var renderedPath = _selectedRenderedSessionPath ?? _lastRenderedSessionPath;
    if (renderedPath == null || !await File(renderedPath).exists()) {
      renderedPath = await _renderSessionWav(_sessionPlan);
      if (renderedPath != null) {
        _lastRenderedSessionPath = renderedPath;
        _selectedRenderedSessionPath = renderedPath;
        await _saveSessionPlan(_sessionPlan, renderedPath: renderedPath);
        await _loadRenderedSessionsFromDisk();
      }
    }

    if (renderedPath == null || !await File(renderedPath).exists()) {
      setState(() {
        _sessionStatus = 'Session audio file missing. Create file again.';
      });
      return;
    }

    final fileTimestamp = _extractRenderedFileTimestamp(renderedPath) ??
        await File(renderedPath).lastModified();

    final token = ++_sessionPlaybackToken;
    setState(() {
      _isSessionPlaying = true;
      _sessionCurrent = Duration.zero;
      _sessionStartedAt = DateTime.now();
      _selectedRenderedSessionPath = renderedPath;
      _currentRenderedFileAt = fileTimestamp;
      _sessionStatus = 'Playing saved 5-minute session';
    });
    _startSessionProgressTicker();

    final playbackBackground = _sessionBackgroundSound ?? _selectedBackground;
    if (playbackBackground == 'rain') {
      await _startRainBed();
    } else {
      await _stopRainBed();
    }

    await _player!.startPlayer(
      fromURI: renderedPath,
      whenFinished: () {
        if (!mounted || token != _sessionPlaybackToken) return;
        _onCompletedSessionListen();
        _stopRainBed();
        _sessionProgressTimer?.cancel();
        setState(() {
          _isSessionPlaying = false;
          _sessionCurrent = _sessionTotal;
          _sessionStartedAt = null;
          _sessionStatus = 'Session playback finished';
        });
      },
    );
  }

  Future<void> _onCompletedSessionListen() async {
    await _repository.incrementAudioSessionCompletedPlay();
    const counterConfigs = <Map<String, dynamic>>[
      {'key': AppRepository.counter1Count, 'trackIndex': 0},
      {'key': AppRepository.counter2Count, 'trackIndex': 1},
      {'key': AppRepository.counter3Count, 'trackIndex': 2},
      {'key': AppRepository.umbrellaCount, 'trackIndex': 3},
    ];

    for (final config in counterConfigs) {
      final counterKey = config['key'] as String;
      final trackIndex = config['trackIndex'] as int;

      await _repository.settleAudioSessionAutoDailyTotalsForCounter(counterKey);

      final counterEnabled = await _repository.getCounterEnabled(counterKey);
      if (!counterEnabled) continue;

      final autoAdd =
          await _repository.getAudioSessionAutoAddForCounter(counterKey);
      if (!autoAdd) continue;

      final perSession =
          await _repository.getAudioSessionTrackUsageForIndex(trackIndex);
      if (perSession <= 0) continue;

      await _repository.addAudioSessionAutoPendingTotalTodayForCounter(
        counterKey,
        perSession,
      );
      await _repository.incrementAudioSessionAppliedPlaysTodayForCounter(
        counterKey,
      );
    }
  }

  Future<void> _stopSessionPlayback({bool resetPosition = false}) async {
    _sessionPlaybackToken++;
    _sessionProgressTimer?.cancel();
    _sessionProgressTimer = null;
    await _stopRainBed();

    if (_isPlayerInitialized && _player != null && _player!.isPlaying) {
      await _player!.stopPlayer();
    }

    if (!mounted) return;
    setState(() {
      _isSessionPlaying = false;
      _sessionStartedAt = null;
      if (resetPosition) {
        _sessionCurrent = Duration.zero;
      }
      _sessionStatus = 'Session playback stopped';
    });
  }

  Future<String?> _prepareRainAssetFile() async {
    if (_isWeb) return null;
    if (_rainAssetFilePath != null &&
        await File(_rainAssetFilePath!).exists()) {
      return _rainAssetFilePath;
    }

    try {
      final bytes = await rootBundle.load(_rainAssetPath);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/rain_background_source.mp3');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      _rainAssetFilePath = file.path;
      return _rainAssetFilePath;
    } catch (_) {
      return null;
    }
  }

  Future<void> _startRainBed() async {
    if (_isWeb || !_isRainPlayerInitialized || _rainPlayer == null) return;
    final path = await _prepareRainAssetFile();
    if (path == null) return;

    if (_rainPlayer!.isPlaying) {
      await _rainPlayer!.stopPlayer();
    }

    await _rainPlayer!.setVolume(0.15);
    await _rainPlayer!.startPlayer(
      fromURI: path,
      whenFinished: () {
        if (!_isSessionPlaying ||
            (_sessionBackgroundSound ?? _selectedBackground) != 'rain') {
          return;
        }
        _startRainBed();
      },
    );
  }

  Future<void> _stopRainBed() async {
    if (!_isRainPlayerInitialized || _rainPlayer == null) return;
    if (_rainPlayer!.isPlaying) {
      await _rainPlayer!.stopPlayer();
    }
  }

  List<_SessionSegment> _buildFiveMinuteSessionPlan() {
    const targetMs = 5 * 60 * 1000;
    final selected = _selectedAffirmationIndexes.toList()..sort();
    final available = selected
        .where((i) => _recordedFilePaths.containsKey(i))
        .toList(growable: false);

    if (available.isEmpty) {
      return <_SessionSegment>[];
    }

    // Build rotating block pattern dynamically based on number of tracks
    final blocks = <List<int>>[];
    if (available.length == 1) {
      // Single track: repeat it
      blocks.add(available);
    } else if (available.length == 2) {
      // Two tracks: alternate patterns
      blocks.add(available);
      blocks.add(<int>[available[1], available[0]]);
    } else if (available.length == 3) {
      // Three tracks: rotate
      blocks.add(available);
      blocks.add(<int>[available[1], available[2], available[0]]);
      blocks.add(<int>[available[2], available[0], available[1]]);
    } else {
      // Four or more: use original pattern on first 4
      final first4 = available.take(4).toList();
      blocks.add(first4);
      blocks.add(<int>[first4[1], first4[3], first4[0], first4[2]]);
      blocks.add(<int>[first4[2], first4[0], first4[3], first4[1]]);
      blocks.add(<int>[first4[3], first4[2], first4[1], first4[0]]);
    }

    final output = <_SessionSegment>[];
    var outputMs = 0;
    var blockIndex = 0;

    while (outputMs < targetMs) {
      final block = blocks[blockIndex % blocks.length];

      for (final fileIndex in block) {
        final path = _recordedFilePaths[fileIndex];
        final clipDuration =
            _recordedDurations[fileIndex] ?? const Duration(seconds: 3);
        if (path == null) {
          continue;
        }

        final clipMs = clipDuration.inMilliseconds;
        final remainingMs = targetMs - outputMs;
        final appliedClipMs = clipMs > remainingMs ? remainingMs : clipMs;

        output.add(
          _SessionSegment.clip(
            affirmationIndex: fileIndex,
            path: path,
            sourceDurationMs: clipMs,
            appliedDurationMs: appliedClipMs,
          ),
        );
        outputMs += appliedClipMs;

        if (outputMs >= targetMs) {
          break;
        }
      }

      blockIndex++;
    }

    return output;
  }

  Future<String> _saveSessionPlan(
    List<_SessionSegment> plan, {
    String? renderedPath,
    DateTime? createdAt,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/session_file_plan.json');
    final payload = <String, dynamic>{
      'version': 1,
      'targetMs': 5 * 60 * 1000,
      'backgroundSound': _sessionBackgroundSound ?? _selectedBackground,
      'renderedWavPath': renderedPath ?? _lastRenderedSessionPath,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'plan': plan.map((segment) => segment.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }

  String _sessionFileTitle() {
    final d = _currentRenderedFileAt ?? _sessionCreatedAt;
    if (d == null) return 'Audio File • Created --/--/---- --:--';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return 'Audio File • Played File $mm/$dd/${d.year} $hh:$min';
  }

  DateTime? _extractRenderedFileTimestamp(String path) {
    final name = path.split('/').isNotEmpty ? path.split('/').last : path;
    final match = RegExp(r'^session_render_(\d+)\.wav$').firstMatch(name);
    if (match == null) return null;
    final ms = int.tryParse(match.group(1) ?? '');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<String?> _renderSessionWav(
    List<_SessionSegment> plan, {
    DateTime? fileStamp,
  }) async {
    if (plan.isEmpty) return null;

    _ParsedWav? reference;
    for (final segment in plan) {
      if (segment.kind != 'clip' || segment.path == null) continue;
      final parsed = await _readWavPcm16(segment.path!);
      if (parsed != null) {
        reference = parsed;
        break;
      }
    }
    if (reference == null) return null;

    final sampleRate = reference.sampleRate;
    final channels = reference.channels;
    final blockAlign = channels * 2;
    final targetFrames =
        (sampleRate * _sessionTotal.inMilliseconds / 1000).round();

    final builder = BytesBuilder(copy: false);
    var writtenFrames = 0;

    for (final segment in plan) {
      if (writtenFrames >= targetFrames) break;

      if (segment.kind == 'silence') {
        final segFrames =
            (sampleRate * segment.appliedDurationMs / 1000).round();
        final framesToWrite = (targetFrames - writtenFrames) < segFrames
            ? (targetFrames - writtenFrames)
            : segFrames;
        if (framesToWrite > 0) {
          builder.add(Uint8List(framesToWrite * blockAlign));
          writtenFrames += framesToWrite;
        }
        continue;
      }

      final path = segment.path;
      if (path == null) continue;

      final parsed = await _readWavPcm16(path);
      if (parsed == null) continue;

      if (parsed.sampleRate != sampleRate || parsed.channels != channels) {
        continue;
      }

      final requiredFrames =
          (sampleRate * segment.appliedDurationMs / 1000).round();
      final availableFrames = parsed.pcmData.length ~/ blockAlign;
      var useFrames =
          requiredFrames < availableFrames ? requiredFrames : availableFrames;
      final room = targetFrames - writtenFrames;
      if (useFrames > room) {
        useFrames = room;
      }
      if (useFrames <= 0) continue;

      builder.add(
        Uint8List.fromList(parsed.pcmData.sublist(0, useFrames * blockAlign)),
      );
      writtenFrames += useFrames;
    }

    if (writtenFrames < targetFrames) {
      builder.add(Uint8List((targetFrames - writtenFrames) * blockAlign));
      writtenFrames = targetFrames;
    }

    var pcm = builder.toBytes();
    final maxBytes = targetFrames * blockAlign;
    if (pcm.length > maxBytes) {
      pcm = Uint8List.fromList(pcm.sublist(0, maxBytes));
    }

    _normalizePcm16ToTargetPeak(
      pcm,
      targetPeak: 28000,
      maxGain: 4.0,
    );

    // Apply one master edge fade to the final rendered file to avoid
    // end-of-file click without repeatedly re-fading every segment boundary.
    _applyEdgeFadesPcm16(
      pcm,
      channels: channels,
      sampleRate: sampleRate,
      fadeMs: 40,
    );

    final wavBytes = _buildWavPcm16(
      pcmData: pcm,
      sampleRate: sampleRate,
      channels: channels,
    );

    final dir = await getApplicationDocumentsDirectory();
    final stamp = (fileStamp ?? DateTime.now()).millisecondsSinceEpoch;
    final out = File('${dir.path}/session_render_$stamp.wav');
    await out.writeAsBytes(wavBytes, flush: true);
    return out.path;
  }

  Future<_ParsedWav?> _readWavPcm16(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length < 44) return null;

    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') return null;

    final bd = ByteData.sublistView(bytes);
    var offset = 12;
    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    int? dataOffset;
    int? dataSize;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = bd.getUint32(offset + 4, Endian.little);
      final chunkDataStart = offset + 8;
      final next = chunkDataStart + chunkSize + (chunkSize.isOdd ? 1 : 0);
      if (next > bytes.length) break;

      if (chunkId == 'fmt ' && chunkSize >= 16) {
        channels = bd.getUint16(chunkDataStart + 2, Endian.little);
        sampleRate = bd.getUint32(chunkDataStart + 4, Endian.little);
        bitsPerSample = bd.getUint16(chunkDataStart + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = chunkDataStart;
        dataSize = chunkSize;
      }

      offset = next;
    }

    if (channels == null ||
        sampleRate == null ||
        bitsPerSample != 16 ||
        dataOffset == null ||
        dataSize == null) {
      return null;
    }

    final safeDataSize = (dataOffset + dataSize > bytes.length)
        ? bytes.length - dataOffset
        : dataSize;
    if (safeDataSize <= 0) return null;

    return _ParsedWav(
      pcmData: Uint8List.fromList(
        bytes.sublist(dataOffset, dataOffset + safeDataSize),
      ),
      sampleRate: sampleRate,
      channels: channels,
    );
  }

  void _resetAffirmation(int index) {
    setState(() {
      _affirmationStates[index] = {
        'active': false,
        'hasRecording': false,
        'isRecording': false,
        'isPlaying': false,
        'kept': false,
      };
      _selectedAffirmationIndexes.remove(index);
      _recordedFilePaths.remove(index);
      _recordedDurations.remove(index);
      _recordingStartedAt.remove(index);
      if (_playingIndex == index) {
        _playingIndex = null;
      }
    });
  }

  Future<void> _cancelRecording(int index) async {
    if (_isWeb) {
      _resetAffirmation(index);
      return;
    }

    // Cancel should stop an active recorder first to avoid recorder state errors.
    if (_recorder != null && _recorder!.isRecording) {
      try {
        await _recorder!.stopRecorder();
      } catch (_) {
        // Ignore cancel-stop failures and continue resetting local state.
      }
    }

    if (_playingIndex == index) {
      await _stopPlayback();
    }

    if (!mounted) return;
    _resetAffirmation(index);
  }

  void _activateAffirmation(int index) {
    setState(() {
      for (int i = 0; i < _affirmationStates.length; i++) {
        _affirmationStates[i]['active'] = (i == index);
        if (i != index) {
          _affirmationStates[i]['isRecording'] = false;
          _affirmationStates[i]['isPlaying'] = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      if (_isWeb) {
        return AppCardSurface(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Audio recording is not supported on web. Please use the mobile app to record your affirmations.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.orange.shade200),
            ),
          ),
        );
      }

      return _buildEmbeddedBuilder(context);
    }

    if (_isWeb) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.warning, color: Colors.orange, size: 48),
                SizedBox(height: 24),
                Text(
                  'Audio recording is not supported on web.\nPlease use the mobile app to record your affirmations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.orange),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF232526), // dark gray
              Color(0xFF414345), // lighter gray
              Color(0xFF6A82FB), // blue
              Color(0xFFFC5C7D), // pink
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<AudioAffirmationOption>>(
            future: _labelsUtil.getOptions(),
            builder: (context, snapshot) {
              final options = snapshot.data ??
                  const <AudioAffirmationOption>[
                    AudioAffirmationOption(
                        slotIndex: 0, label: 'Affirmation 1'),
                  ];
              final isFirstTime = options.length == 1 &&
                  options[0].slotIndex == 0 &&
                  options[0].label == _fallbackAffirmations[0];
              final playbackStatus =
                  _sessionStatus == 'Playing saved 5-minute session'
                      ? _sessionStatus
                      : null;
              final builderStatus =
                  _sessionStatus == 'Playing saved 5-minute session'
                      ? null
                      : _sessionStatus;
              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                children: [
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      const Text(
                        'Session',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.8,
                          color: _audioTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Build Your File',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: _audioBody,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 52,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Color(0xAAFFFFFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      if (isFirstTime) ...[
                        const SizedBox(height: 24),
                        AppSelectionPillButton(
                          label: 'Set up your affirmations',
                          selected: false,
                          onTap: () {
                            Navigator.of(context).pushNamed('/setup');
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 36),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create your 5-minute file',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _audioTextSecondary,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SessionBuilderCard(
                    affirmations: options,
                    affirmationStates: _affirmationStates,
                    selectedAffirmationIndexes: _selectedAffirmationIndexes,
                    selectedBackground: _selectedBackground,
                    status: builderStatus,
                    lastSessionPlanPath: _lastSessionPlanPath,
                    onToggleAffirmation: _toggleSessionAffirmation,
                    onSelectBackground: _selectBackground,
                    onCreateFile: _createSessionFile,
                    recordedFilePaths: _recordedFilePaths,
                    isRecorderInitialized: _isRecorderInitialized,
                    onStartRecording: _startRecording,
                    onStopRecording: _stopRecording,
                    onPlayRecording: _playRecording,
                    onStopPlayback: _stopPlayback,
                    onKeepRecording: _keepRecording,
                    onParentSetState: setState,
                    onResetAffirmation: _resetAffirmation,
                    onCancelRecording: _cancelRecording,
                    onActivate: _activateAffirmation,
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(height: 24),
                  if (playbackStatus != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        playbackStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: _audioTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Demo: Show AudioProgressCard at the bottom for playback UI
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: AudioProgressCard(
                      title: _sessionFileTitle(),
                      current: _sessionCurrent,
                      total: _sessionTotal,
                      progress: (_sessionCurrent.inMilliseconds /
                              _sessionTotal.inMilliseconds)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      isPlaying: _isSessionPlaying,
                      onPlayPause: () {
                        _toggleSessionPlayback();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _SessionLibraryCard(
                      sessions: _renderedSessions,
                      selectedPath: _selectedRenderedSessionPath,
                      onSelect: _selectRenderedSession,
                    ),
                  ),
                  const NavigationBottomGrid(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmbeddedBuilder(BuildContext context) {
    final builderStatus = _sessionStatus == 'Playing saved 5-minute session'
        ? null
        : _sessionStatus;

    return FutureBuilder<List<AudioAffirmationOption>>(
      future: _labelsUtil.getOptions(),
      builder: (context, snapshot) {
        final affirmations = snapshot.data ??
            const <AudioAffirmationOption>[
              AudioAffirmationOption(slotIndex: 0, label: 'Affirmation 1'),
            ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SessionBuilderCard(
              affirmations: affirmations,
              affirmationStates: _affirmationStates,
              selectedAffirmationIndexes: _selectedAffirmationIndexes,
              selectedBackground: _selectedBackground,
              status: builderStatus,
              lastSessionPlanPath: _lastSessionPlanPath,
              onToggleAffirmation: _toggleSessionAffirmation,
              onSelectBackground: _selectBackground,
              onCreateFile: _createSessionFile,
              recordedFilePaths: _recordedFilePaths,
              isRecorderInitialized: _isRecorderInitialized,
              onStartRecording: _startRecording,
              onStopRecording: _stopRecording,
              onPlayRecording: _playRecording,
              onStopPlayback: _stopPlayback,
              onKeepRecording: _keepRecording,
              onParentSetState: (fn) => setState(fn),
              onResetAffirmation: _resetAffirmation,
              onCancelRecording: _cancelRecording,
              onActivate: _activateAffirmation,
            ),
            const SizedBox(height: 12),
            _SessionLibraryCard(
              sessions: _renderedSessions,
              selectedPath: _selectedRenderedSessionPath,
              onSelect: _selectRenderedSession,
            ),
            if (_sessionStatus == 'Playing saved 5-minute session') ...[
              const SizedBox(height: 14),
              AudioProgressCard(
                title: _sessionFileTitle(),
                current: _sessionCurrent,
                total: _sessionTotal,
                progress: _sessionTotal.inMilliseconds == 0
                    ? 0
                    : _sessionCurrent.inMilliseconds /
                        _sessionTotal.inMilliseconds,
                isPlaying: _isSessionPlaying,
                onPlayPause: _toggleSessionPlayback,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SessionBuilderCard extends StatelessWidget {
  final List<AudioAffirmationOption> affirmations;
  final List<Map<String, dynamic>> affirmationStates;
  final Set<int> selectedAffirmationIndexes;
  final String? selectedBackground;
  final String? status;
  final String? lastSessionPlanPath;
  final ValueChanged<int> onToggleAffirmation;
  final ValueChanged<String> onSelectBackground;
  final VoidCallback onCreateFile;
  final Map<int, String> recordedFilePaths;
  final bool isRecorderInitialized;
  final Future<void> Function(int) onStartRecording;
  final Future<void> Function(int) onStopRecording;
  final Future<void> Function(int) onPlayRecording;
  final Future<void> Function() onStopPlayback;
  final ValueChanged<int> onKeepRecording;
  final void Function(void Function()) onParentSetState;
  final void Function(int) onResetAffirmation;
  final Future<void> Function(int) onCancelRecording;
  final ValueChanged<int> onActivate;

  const _SessionBuilderCard({
    required this.affirmations,
    required this.affirmationStates,
    required this.selectedAffirmationIndexes,
    required this.selectedBackground,
    required this.status,
    required this.lastSessionPlanPath,
    required this.onToggleAffirmation,
    required this.onSelectBackground,
    required this.onCreateFile,
    required this.recordedFilePaths,
    required this.isRecorderInitialized,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPlayRecording,
    required this.onStopPlayback,
    required this.onKeepRecording,
    required this.onParentSetState,
    required this.onResetAffirmation,
    required this.onCancelRecording,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final canCreate =
        selectedAffirmationIndexes.isNotEmpty && selectedBackground != null;

    return AppCardSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    showAppBottomPopupDialog<void>(
                      context: context,
                      title: 'About Audio Session',
                      content: const Text(
                        'Record each affirmation and save the ones you want to keep. Once all 4 affirmations are saved, you can build a compiled file with or without background sound. Daily audio track counts can be tracked in your individual counters. Only the last two compiled files are stored.',
                        style: AppTextStyles.body,
                      ),
                      actions: const [
                        AppBottomPopupAction<void>(label: 'Close'),
                      ],
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Click on your affirmations to start building your file',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _audioBody,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          // Change to a vertical ListView for 1x1 affirmations
          ListView.builder(
            itemCount: affirmations.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final option = affirmations[index];
              final slotIndex = option.slotIndex;
              final state = affirmationStates[slotIndex];
              final isActive = state['active'];
              final hasRecording = state['hasRecording'];
              final isRecording = state['isRecording'];
              final isPlaying = state['isPlaying'];
              final kept = state['kept'];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSelectionPillButton(
                      label: option.label,
                      selected: isActive || kept,
                      onTap: () {
                        if (!isActive) onActivate(slotIndex);
                      },
                    ),
                    if (isActive && !isRecording && !isPlaying)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 8.0;
                            final buttonWidth =
                                (constraints.maxWidth - spacing) / 2;

                            return Wrap(
                              alignment: WrapAlignment.center,
                              runAlignment: WrapAlignment.center,
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                if (!hasRecording)
                                  SizedBox(
                                    width: buttonWidth,
                                    child: AppSelectionPillButton(
                                      label: 'Record',
                                      selected: false,
                                      onTap: () {
                                        onParentSetState(() {
                                          state['isRecording'] = true;
                                        });
                                        onStartRecording(slotIndex);
                                      },
                                    ),
                                  ),
                                if (hasRecording)
                                  SizedBox(
                                    width: buttonWidth,
                                    child: AppSelectionPillButton(
                                      label: 'Keep',
                                      selected: false,
                                      onTap: () {
                                        onKeepRecording(slotIndex);
                                      },
                                    ),
                                  ),
                                if (hasRecording)
                                  SizedBox(
                                    width: buttonWidth,
                                    child: AppSelectionPillButton(
                                      label: 'Listen',
                                      selected: false,
                                      onTap: () {
                                        onParentSetState(() {
                                          state['isPlaying'] = true;
                                        });
                                        onPlayRecording(slotIndex);
                                      },
                                    ),
                                  ),
                                if (hasRecording)
                                  SizedBox(
                                    width: buttonWidth,
                                    child: AppSelectionPillButton(
                                      label: 'Retake',
                                      selected: false,
                                      onTap: () {
                                        onParentSetState(() {
                                          state['isRecording'] = true;
                                          state['hasRecording'] = false;
                                          state['isPlaying'] = false;
                                          state['kept'] = false;
                                        });
                                        onStartRecording(slotIndex);
                                      },
                                    ),
                                  ),
                                SizedBox(
                                  width: buttonWidth,
                                  child: AppSelectionPillButton(
                                    label: 'Cancel',
                                    selected: false,
                                    onTap: () {
                                      onResetAffirmation(slotIndex);
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (isActive && isRecording)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppSelectionPillButton(
                              label: 'Stop',
                              selected: false,
                              onTap: () async {
                                onParentSetState(() {
                                  state['isRecording'] = false;
                                  state['hasRecording'] = false;
                                });
                                await onStopRecording(slotIndex);
                              },
                            ),
                            AppSelectionPillButton(
                              label: 'Cancel',
                              selected: false,
                              onTap: () async {
                                onParentSetState(() {
                                  state['isRecording'] = false;
                                });
                                await onCancelRecording(slotIndex);
                              },
                            ),
                          ],
                        ),
                      ),
                    if (isActive && isPlaying)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppSelectionPillButton(
                              label: 'Keep',
                              selected: false,
                              onTap: () {
                                onStopPlayback();
                                onKeepRecording(slotIndex);
                              },
                            ),
                            AppSelectionPillButton(
                              label: 'Re-record',
                              selected: false,
                              onTap: () {
                                onStopPlayback();
                                onParentSetState(() {
                                  state['isRecording'] = true;
                                  state['hasRecording'] = false;
                                  state['isPlaying'] = false;
                                  state['kept'] = false;
                                });
                                onStartRecording(slotIndex);
                              },
                            ),
                            AppSelectionPillButton(
                              label: 'Stop',
                              selected: false,
                              onTap: () {
                                onStopPlayback();
                                onParentSetState(() {
                                  state['isPlaying'] = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    if (kept)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Icon(Icons.check_circle,
                            color: Colors.green, size: 22),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          const Text(
            'Choose background sound',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _audioTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelectBackground('none'),
                  child: _SelectionButton(
                    label: 'No background',
                    selected: selectedBackground == 'none',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelectBackground('rain'),
                  child: _SelectionButton(
                    label: 'Rain',
                    selected: selectedBackground == 'rain',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: canCreate ? onCreateFile : null,
            child: _PrimaryButton(
              label: 'Create File',
              enabled: canCreate,
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 14),
            Text(
              status!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _audioTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionLibraryCard extends StatelessWidget {
  final List<_RenderedSessionItem> sessions;
  final String? selectedPath;
  final ValueChanged<String> onSelect;

  const _SessionLibraryCard({
    required this.sessions,
    required this.selectedPath,
    required this.onSelect,
  });

  String _format(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$mm/$dd/${d.year} $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Audio Library (Last 2 Compiled)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _audioTextSecondary,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  Navigator.of(context).pushNamed('/home_final');
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            const Text(
              'No rendered files yet. Create File to generate one.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _audioBody,
                letterSpacing: -0.1,
              ),
            )
          else
            ...sessions.map((session) {
              final selected = session.path == selectedPath;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(session.path),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFEDEDED)
                          : const Color(0xFF2A2A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF0B0B0D)
                            : const Color(0x26FFFFFF),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color:
                              selected ? const Color(0xFF0B0B0D) : Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'File ${_format(session.createdAt)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? const Color(0xFF0B0B0D)
                                  : Colors.white,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SessionSegment {
  final String kind;
  final int? affirmationIndex;
  final String? path;
  final int sourceDurationMs;
  final int appliedDurationMs;

  const _SessionSegment._({
    required this.kind,
    required this.affirmationIndex,
    required this.path,
    required this.sourceDurationMs,
    required this.appliedDurationMs,
  });

  factory _SessionSegment.clip({
    required int affirmationIndex,
    required String path,
    required int sourceDurationMs,
    required int appliedDurationMs,
  }) {
    return _SessionSegment._(
      kind: 'clip',
      affirmationIndex: affirmationIndex,
      path: path,
      sourceDurationMs: sourceDurationMs,
      appliedDurationMs: appliedDurationMs,
    );
  }

  factory _SessionSegment.silence({
    required int durationMs,
  }) {
    return _SessionSegment._(
      kind: 'silence',
      affirmationIndex: null,
      path: null,
      sourceDurationMs: durationMs,
      appliedDurationMs: durationMs,
    );
  }

  factory _SessionSegment.fromJson(Map<String, dynamic> json) {
    final kind = (json['kind'] ?? 'silence').toString();
    final sourceDurationMs = (json['sourceDurationMs'] as num?)?.toInt() ?? 0;
    final appliedDurationMs = (json['appliedDurationMs'] as num?)?.toInt() ?? 0;

    if (kind == 'clip') {
      return _SessionSegment.clip(
        affirmationIndex: (json['affirmationIndex'] as num?)?.toInt() ?? 0,
        path: (json['path'] ?? '').toString(),
        sourceDurationMs: sourceDurationMs,
        appliedDurationMs: appliedDurationMs,
      );
    }

    return _SessionSegment.silence(
      durationMs: appliedDurationMs > 0 ? appliedDurationMs : sourceDurationMs,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kind': kind,
      'affirmationIndex': affirmationIndex,
      'path': path,
      'sourceDurationMs': sourceDurationMs,
      'appliedDurationMs': appliedDurationMs,
    };
  }
}

class _TrimResult {
  final String filePath;
  final Duration trimmedDuration;
  final int removedMs;

  const _TrimResult({
    required this.filePath,
    required this.trimmedDuration,
    required this.removedMs,
  });
}

class _ParsedWav {
  final Uint8List pcmData;
  final int sampleRate;
  final int channels;

  const _ParsedWav({
    required this.pcmData,
    required this.sampleRate,
    required this.channels,
  });
}

class _RecordedAudioStats {
  final int fileSizeBytes;
  final int durationMs;
  final int peak;
  final double averageAbs;
  final bool hasAudioData;

  const _RecordedAudioStats({
    required this.fileSizeBytes,
    required this.durationMs,
    required this.peak,
    required this.averageAbs,
    required this.hasAudioData,
  });
}

class _RenderedSessionItem {
  final String path;
  final DateTime createdAt;

  const _RenderedSessionItem({
    required this.path,
    required this.createdAt,
  });
}

class _SelectionButton extends StatelessWidget {
  final String label;
  final bool selected;

  const _SelectionButton({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: selected ? const Color(0x22FFFFFF) : _audioNavCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0x66FFFFFF) : _audioBorder,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.buttonLabel13.copyWith(
            fontWeight: FontWeight.w400,
            color: selected ? _audioTextPrimary : _audioBody,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;

  const _PrimaryButton({
    required this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: enabled ? const Color(0x22FFFFFF) : const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? const Color(0x66FFFFFF) : const Color(0x22FFFFFF),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x66000000),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.buttonLabel13.copyWith(
            fontWeight: FontWeight.w400,
            color: enabled ? _audioTextPrimary : _audioTextSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class AudioProgressCard extends StatelessWidget {
  final String? title;
  final Duration current;
  final Duration total;
  final double progress; // 0.0 - 1.0
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final bool isLooping;
  final VoidCallback? onLoopToggle;
  final Widget? leadingControl;
  final Widget? bottomLeftControl;

  const AudioProgressCard({
    super.key,
    this.title,
    required this.current,
    required this.total,
    required this.progress,
    required this.isPlaying,
    this.onPlayPause,
    this.isLooping = false,
    this.onLoopToggle,
    this.leadingControl,
    this.bottomLeftControl,
  });

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      backgroundColor:
          Colors.black.withOpacity(0.7), // Add dark background for contrast
      padding: const EdgeInsets.symmetric(
          vertical: 20, horizontal: 18), // Increase height
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null && title!.trim().isNotEmpty) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (leadingControl != null) ...[
                leadingControl!,
                const SizedBox(width: 6),
              ],
              // Controls
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white, // Explicit icon color
                      size: 32,
                    ),
                    onPressed: onPlayPause,
                    tooltip: isPlaying ? 'Pause' : 'Play',
                  ),
                  if (onLoopToggle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onLoopToggle,
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLooping
                                ? const Color(0x3325D366)
                                : Colors.transparent,
                            border: Border.all(
                              color: isLooping
                                  ? const Color(0xFF25D366)
                                  : Colors.white24,
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.loop_rounded,
                            color: isLooping
                                ? const Color(0xFF25D366)
                                : Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Progress bar and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(_formatTime(current),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey[400]!),
                            ),
                          ),
                        ),
                        Text(_formatTime(total),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (bottomLeftControl != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: bottomLeftControl!,
            ),
          ],
        ],
      ),
    );
  }
}
