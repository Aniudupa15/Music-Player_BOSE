import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  MyAudioHandler() {
    _init();
  }

  void _init() {
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        playing: state.playing,
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
      ));
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      final oldMediaItem = mediaItem.value;
      if (oldMediaItem != null && duration != null) {
        mediaItem.add(oldMediaItem.copyWith(duration: duration));
      }
    });
  }

  AudioPlayer get player => _player;

  Future<void> setMediaItemFromPath(
      String filePath,
      String title,
      String artist,
      ) async {
    final newMediaItem = MediaItem(
      id: filePath,
      title: title,
      artist: artist,
      album: 'Unknown Album',
      duration: Duration.zero,
      artUri: null,
    );

    mediaItem.add(newMediaItem);
    await _player.setFilePath(filePath);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // This will be handled by the provider
  }

  @override
  Future<void> skipToPrevious() async {
    // This will be handled by the provider
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
}