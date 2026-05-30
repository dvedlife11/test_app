// audio_player_widget.dart
//
// Standalone daily-use player widget.  Drop this into Home (or anywhere)
// to let the user play their saved 5-minute session WAV.
// It has its own audio-player lifecycle and loads the saved session path
// from disk on init — no builder state needed.
//
// Usage in home_final.dart:
//   import 'audio_player_widget.dart';
//   ...
//   const AudioSessionPlayerWidget()

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audio_session/audio_session.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_handler.dart';

import 'app_card_surface.dart';
import 'app_repository.dart';
import 'audio.dart' show AudioProgressCard;
import 'design_system.dart';

class AudioSessionPlayerWidget extends StatefulWidget {
  const AudioSessionPlayerWidget({super.key});

  @override
  State<AudioSessionPlayerWidget> createState() =>
      _AudioSessionPlayerWidgetState();
}

class _AudioSessionPlayerWidgetState extends State<AudioSessionPlayerWidget>
    with WidgetsBindingObserver {
  static const String _rainAssetPath =
      'assets/data/5 Minute Timer with Rain Sounds  Timers.mp3';
  static final RegExp _renderedFilePattern =
      RegExp(r'^session_render_(\d+)\.wav$');

  final bool _isWeb = kIsWeb;

  // Main WAV player is now managed by audioHandler (lock screen integration).
  FlutterSoundPlayer? _rainPlayer;
  bool _isRainPlayerInitialized = false;

  String? _renderedWavPath;
  String? _backgroundSound;
  String? _rainAssetFilePath;

  bool _isPlaying = false;
  bool _isLooping = false;
  DateTime? _startedAt;
  Timer? _progressTimer;

  static const Duration _sessionTotal = Duration(minutes: 5);
  Duration _sessionCurrent = Duration.zero;
  final AppRepository _repository = AppRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Home can be shown again without app lifecycle resume; refresh here too.
    unawaited(_loadSessionFromDisk());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadSessionFromDisk());
    }
  }

  Future<void> _openBuilderAndRefresh() async {
    await Navigator.of(context).pushNamed('/setup', arguments: 'audio_session');
    await _loadSessionFromDisk();
  }

  Future<void> _initPlayers() async {
    if (_isWeb) return;

    // Configure the iOS audio session for playback with interruption handling.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.longFormAudio,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    // Stop on audio interruptions (phone calls, Siri, other apps).
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (_isPlaying) _stop();
      }
    });
    // Headphones unplugged — stop to avoid blasting from speaker.
    session.becomingNoisyEventStream.listen((_) {
      if (_isPlaying) _stop();
    });

    _rainPlayer = FlutterSoundPlayer();
    await _rainPlayer!.openPlayer();
    await _rainPlayer!.setVolume(0.15);

    // Wire handler callbacks so the widget reacts to completion/loop events.
    audioHandler.onPlaybackCompleted = () {
      if (!mounted) return;
      _stopRain();
      _progressTimer?.cancel();
      _onCompletedSessionListen();
      setState(() {
        _isPlaying = false;
        _sessionCurrent = _sessionTotal;
        _startedAt = null;
      });
    };
    audioHandler.onLoopRestarted = () {
      if (!mounted) return;
      if (_backgroundSound == 'rain') _startRain();
      setState(() {
        _sessionCurrent = Duration.zero;
        _startedAt = DateTime.now();
      });
    };

    if (!mounted) return;
    setState(() {
      _isRainPlayerInitialized = true;
    });
    await _loadSessionFromDisk();
  }

  Future<void> _loadSessionFromDisk() async {
    if (_isWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final planFile = File('${dir.path}/session_file_plan.json');
      String? renderedPath;
      String? bg;

      if (await planFile.exists()) {
        final raw = await planFile.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          renderedPath = decoded['renderedWavPath']?.toString();
          bg = decoded['backgroundSound']?.toString();
        }
      }

      if (renderedPath == null || !await File(renderedPath).exists()) {
        renderedPath = await _findLatestRenderedSessionPath(dir);
      }

      if (renderedPath != null && await File(renderedPath).exists()) {
        final oldPath = _renderedWavPath;
        if (_isPlaying && oldPath != null && oldPath != renderedPath) {
          await _stop();
        }
        // Tell the handler so it can set Now Playing metadata.
        // Do not block local playback setup if metadata setup fails.
        try {
          await audioHandler.prepareSession(renderedPath);
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _renderedWavPath = renderedPath;
          _backgroundSound = bg;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _renderedWavPath = null;
          _backgroundSound = bg;
        });
      }
    } catch (_) {}
  }

  Future<String?> _findLatestRenderedSessionPath(Directory dir) async {
    File? latest;
    int latestStamp = -1;

    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = entity.path.split('/').last;
      final match = _renderedFilePattern.firstMatch(name);
      if (match == null) continue;

      final stamp = int.tryParse(match.group(1) ?? '');
      if (stamp == null) continue;
      if (stamp > latestStamp) {
        latestStamp = stamp;
        latest = entity;
      }
    }

    return latest?.path;
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _stop();
    } else {
      await _play();
    }
  }

  void _toggleLoop() {
    if (!mounted) return;
    setState(() {
      _isLooping = !_isLooping;
    });
    audioHandler.setLooping(_isLooping);
  }

  Future<void> _play() async {
    if (_isWeb || _renderedWavPath == null) return;
    if (!await File(_renderedWavPath!).exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session file not found. Record in Setup first.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    audioHandler.setLooping(_isLooping);

    setState(() {
      _isPlaying = true;
      _sessionCurrent = Duration.zero;
      _startedAt = DateTime.now();
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_isPlaying || _startedAt == null || !mounted) return;
      final elapsed = DateTime.now().difference(_startedAt!);
      setState(() {
        _sessionCurrent = elapsed > _sessionTotal ? _sessionTotal : elapsed;
      });
    });

    if (_backgroundSound == 'rain') {
      await _startRain();
    }

    await audioHandler.play();
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

  Future<void> _stop() async {
    _progressTimer?.cancel();
    _progressTimer = null;
    await _stopRain();
    await audioHandler.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _startedAt = null;
    });
  }

  Future<void> _startRain() async {
    if (_isWeb || !_isRainPlayerInitialized || _rainPlayer == null) return;
    final path = await _prepareRainFile();
    if (path == null) return;
    if (_rainPlayer!.isPlaying) await _rainPlayer!.stopPlayer();
    await _rainPlayer!.startPlayer(
      fromURI: path,
      whenFinished: () {
        if (_isPlaying && _backgroundSound == 'rain') _startRain();
      },
    );
  }

  Future<void> _stopRain() async {
    if (!_isRainPlayerInitialized || _rainPlayer == null) return;
    if (_rainPlayer!.isPlaying) await _rainPlayer!.stopPlayer();
  }

  Future<String?> _prepareRainFile() async {
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

  @override
  void dispose() {
    // Clear handler callbacks so they don't fire after widget is gone.
    WidgetsBinding.instance.removeObserver(this);
    audioHandler.onPlaybackCompleted = null;
    audioHandler.onLoopRestarted = null;
    _progressTimer?.cancel();
    _rainPlayer?.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isWeb) {
      return const SizedBox.shrink();
    }

    final hasSession = _renderedWavPath != null;
    final progress = _sessionTotal.inMilliseconds > 0
        ? (_sessionCurrent.inMilliseconds / _sessionTotal.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasSession)
          AppCardSurface(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await _openBuilderAndRefresh();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x1FFFFFFF),
                      Color(0x0FFFFFFF),
                    ],
                  ),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.graphic_eq_rounded,
                            color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Daily Audio Player',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No session file yet. Tap to open the builder in Setup and create your 5-minute track.',
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x40FFFFFF)),
                        ),
                        child: Text(
                          'Open Builder',
                          style: AppTextStyles.buttonLabel13Medium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AudioProgressCard(
                    title: 'Daily Affirmations • 5:00',
                    current: _sessionCurrent,
                    total: _sessionTotal,
                    progress: progress,
                    isPlaying: _isPlaying,
                    onPlayPause: _togglePlay,
                    isLooping: _isLooping,
                    onLoopToggle: _toggleLoop,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () async {
                        await _openBuilderAndRefresh();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 17,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
