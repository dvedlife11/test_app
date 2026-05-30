// audio_handler.dart
//
// AudioHandler for lock screen / Control Center Now Playing integration.
// Uses audio_service to expose playback state and media metadata to iOS.
// The actual FlutterSoundPlayer for the main WAV lives here.
// Rain (background) remains in audio_player_widget.dart.

import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Global accessor — initialised once in main()
// ---------------------------------------------------------------------------

AppAudioHandler? _handlerInstance;

AppAudioHandler get audioHandler {
  assert(_handlerInstance != null,
      'initAudioHandler() must be called before accessing audioHandler');
  return _handlerInstance!;
}

Future<AppAudioHandler> initAudioHandler() async {
  _handlerInstance = await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.test_app.audio',
      androidNotificationChannelName: 'Daily Affirmations',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: const Color(0xFF111111),
    ),
  );
  return _handlerInstance!;
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

class AppAudioHandler extends BaseAudioHandler {
  final _player = FlutterSoundPlayer();
  bool _isInitialized = false;
  int _token = 0;
  Timer? _positionTimer;
  Duration _lastPosition = Duration.zero;
  String? _currentPath;
  bool _isLooping = false;

  static const _total = Duration(minutes: 5);

  // Callbacks so the widget can react to playback events.
  VoidCallback? onPlaybackCompleted;
  VoidCallback? onLoopRestarted;

  // -------------------------------------------------------------------------
  // Initialisation
  // -------------------------------------------------------------------------

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _player.openPlayer();
    _isInitialized = true;
  }

  // Call this after loading the session path from disk.
  Future<void> prepareSession(String path) async {
    await ensureInitialized();
    _currentPath = path;

    // Copy artwork to a file so audio_service can reference it via URI.
    final artUri = await _artworkUri();

    mediaItem.add(MediaItem(
      id: path,
      title: 'Daily Affirmations',
      album: 'TheBone.',
      duration: _total,
      artUri: artUri,
    ));

    queue.add([
      MediaItem(
        id: path,
        title: 'Daily Affirmations',
        album: 'TheBone.',
        duration: _total,
        artUri: artUri,
      ),
    ]);

    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      processingState: AudioProcessingState.ready,
      playing: false,
      updatePosition: Duration.zero,
    ));
  }

  void setLooping(bool loop) => _isLooping = loop;

  // -------------------------------------------------------------------------
  // BaseAudioHandler overrides (called from lock screen / headset buttons)
  // -------------------------------------------------------------------------

  @override
  Future<void> play() async {
    if (_currentPath == null) return;
    await ensureInitialized();
    if (!await File(_currentPath!).exists()) return;

    final token = ++_token;

    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.pause],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      playing: true,
      processingState: AudioProcessingState.ready,
      updatePosition: Duration.zero,
      bufferedPosition: _total,
    ));

    _lastPosition = Duration.zero;

    _startPositionTimer(startedAt: DateTime.now());

    await _player.startPlayer(
      fromURI: _currentPath!,
      whenFinished: () => _handleFinished(token),
    );
  }

  @override
  Future<void> pause() async {
    _token++;
    _positionTimer?.cancel();
    if (_isInitialized && _player.isPlaying) await _player.stopPlayer();

    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.ready,
      controls: [MediaControl.play],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      updatePosition: _lastPosition,
    ));
  }

  @override
  Future<void> stop() async {
    _token++;
    _positionTimer?.cancel();
    if (_isInitialized && _player.isPlaying) await _player.stopPlayer();

    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.ready,
      controls: [MediaControl.play],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      updatePosition: Duration.zero,
    ));

    _lastPosition = Duration.zero;
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  void _startPositionTimer({required DateTime startedAt}) {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final elapsed = DateTime.now().difference(startedAt);
      final pos = elapsed > _total ? _total : elapsed;
      _lastPosition = pos;
      playbackState.add(playbackState.value.copyWith(
        updatePosition: pos,
      ));
    });
  }

  Future<void> _handleFinished(int token) async {
    if (token != _token) return;

    if (_isLooping) {
      await _restartForLoop(token);
      return;
    }

    _positionTimer?.cancel();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.completed,
      updatePosition: _total,
      controls: [MediaControl.play],
    ));
    onPlaybackCompleted?.call();
  }

  Future<void> _restartForLoop(int token) async {
    if (token != _token || _currentPath == null) return;

    playbackState.add(playbackState.value.copyWith(
      updatePosition: Duration.zero,
    ));
    _startPositionTimer(startedAt: DateTime.now());

    onLoopRestarted?.call();

    await _player.startPlayer(
      fromURI: _currentPath!,
      whenFinished: () => _handleFinished(token),
    );
  }

  // Copy the artwork PNG from assets to documents so audio_service can load it.
  static String? _cachedArtPath;
  Future<Uri?> _artworkUri() async {
    try {
      if (_cachedArtPath != null && await File(_cachedArtPath!).exists()) {
        return Uri.file(_cachedArtPath!);
      }
      const assetPath = 'assets/images/TheBone_Fac.png';
      final bytes = await rootBundle.load(assetPath);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/now_playing_art.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      _cachedArtPath = file.path;
      return Uri.file(file.path);
    } catch (_) {
      return null;
    }
  }

  Future<void> disposeHandler() async {
    _positionTimer?.cancel();
    await _player.closePlayer();
  }
}
