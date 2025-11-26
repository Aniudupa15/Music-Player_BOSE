// lib/providers/audio_player_provider.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

import '../models/audio_metadata.dart';

enum RepeatMode { off, one, all }

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Playlist / indices
  final List<AudioMetadata> _playlist = [];
  final List<int> _shuffledIndices = [];

  // -1 means "no selection yet"
  int _currentIndex = -1;
  int _currentShuffleIndex = 0;

  // UI state
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _errorMessage;

  // Playback options
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;
  double _volume = 1.0;

  // Sleep timer
  Timer? _sleepTimer;
  bool _isSleepTimerActive = false;
  int? _sleepTimerMinutesRemaining;
  Timer? _sleepTimerCountdown;

  // Expose safe getters
  AudioPlayer get audioPlayer => _audioPlayer;
  List<AudioMetadata> get playlist => List.unmodifiable(_playlist);
  AudioMetadata? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String? get errorMessage => _errorMessage;
  bool get hasTrack => _playlist.isNotEmpty;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  double get volume => _volume;
  int get currentIndex => _currentIndex;
  bool get isSleepTimerActive => _isSleepTimerActive;
  int? get sleepTimerMinutesRemaining => _sleepTimerMinutesRemaining;

  bool get hasNext => _isShuffle
      ? (_currentShuffleIndex < _shuffledIndices.length - 1)
      : (_currentIndex >= 0 && _currentIndex < _playlist.length - 1);
  bool get hasPrevious => _isShuffle
      ? (_currentShuffleIndex > 0)
      : (_currentIndex > 0);

  AudioPlayerProvider() {
    _initializeListeners();
  }

  void _initializeListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      final playing = state.playing;
      if (playing != _isPlaying) {
        _isPlaying = playing;
        notifyListeners();
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      _currentPosition = pos;
      // Position updates are frequent — avoid excessive notify if you prefer throttling.
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null && dur != _totalDuration) {
        _totalDuration = dur;
        notifyListeners();
      }
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });
  }

  // ---------------------------
  // Sleep timer
  // ---------------------------
  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerCountdown?.cancel();

    _isSleepTimerActive = true;
    _sleepTimerMinutesRemaining = minutes;
    notifyListeners();

    _sleepTimer = Timer(Duration(minutes: minutes), () async {
      await stop();
      _isSleepTimerActive = false;
      _sleepTimerMinutesRemaining = null;
      notifyListeners();
    });

    // Countdown for UI (optional)
    _sleepTimerCountdown = Timer.periodic(const Duration(minutes: 1), (t) {
      if (_sleepTimerMinutesRemaining != null && _sleepTimerMinutesRemaining! > 0) {
        _sleepTimerMinutesRemaining = _sleepTimerMinutesRemaining! - 1;
        notifyListeners();
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerCountdown?.cancel();
    _isSleepTimerActive = false;
    _sleepTimerMinutesRemaining = null;
    notifyListeners();
  }

  // ---------------------------
  // Playlist management (no auto-play)
  // ---------------------------
  Future<void> addToPlaylist(String filePath) async {
    try {
      _errorMessage = null;
      final meta = _extractMetadata(filePath);
      _playlist.add(meta);

      // if no current selection, keep it unselected to avoid auto-play
      // caller must call playTrackAt(...) or play()
      if (_isShuffle) {
        _generateShuffledIndices();
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Could not add file: $e';
      notifyListeners();
    }
  }

  Future<void> addMultipleToPlaylist(List<String> filePaths) async {
    try {
      final startLen = _playlist.length;
      for (final fp in filePaths) {
        _playlist.add(_extractMetadata(fp));
      }

      if (_isShuffle) {
        _generateShuffledIndices();
      }

      // do NOT auto-play even if previously empty.
      // if you want auto-play behavior, call playTrackAt(0) explicitly from UI.
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Could not add files: $e';
      notifyListeners();
    }
  }

  void removeFromPlaylist(int index) {
    if (index < 0 || index >= _playlist.length) return;

    final wasCurrent = index == _currentIndex;
    _playlist.removeAt(index);

    if (_playlist.isEmpty) {
      _currentIndex = -1;
      _shuffledIndices.clear();
      _currentShuffleIndex = 0;
      _audioPlayer.stop();
    } else {
      // adjust current index if needed
      if (wasCurrent) {
        // stop current and clear selection - user must pick or call playTrackAt
        _audioPlayer.stop();
        _currentIndex = -1;
      } else if (index < _currentIndex) {
        _currentIndex -= 1;
      }

      if (_isShuffle) _generateShuffledIndices();
    }
    notifyListeners();
  }

  void clearPlaylist() {
    _playlist.clear();
    _currentIndex = -1;
    _shuffledIndices.clear();
    _currentShuffleIndex = 0;
    _audioPlayer.stop();
    notifyListeners();
  }

  void setPlaylist(List<AudioMetadata> newPlaylist, {bool autoPlay = false}) {
    _playlist
      ..clear()
      ..addAll(newPlaylist);
    _currentIndex = -1;
    _currentShuffleIndex = 0;
    if (_isShuffle) _generateShuffledIndices();

    notifyListeners();

    if (autoPlay && _playlist.isNotEmpty) {
      playTrackAt(0);
    }
  }

  // ---------------------------
  // Playback control
  // ---------------------------
  Future<void> _loadFileAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) {
      _errorMessage = 'Index out of range';
      notifyListeners();
      return;
    }

    final filePath = _playlist[index].filePath;

    try {
      // stop current playback before setting new source to avoid overlap
      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(filePath);
      _currentIndex = index;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Could not load file: $e';
      notifyListeners();
    }
  }

  Future<void> playTrackAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    // If shuffle is enabled, ensure shuffle indices point to index
    if (_isShuffle) {
      if (_shuffledIndices.isEmpty) _generateShuffledIndices();
      final shufflePos = _shuffledIndices.indexOf(index);
      if (shufflePos != -1) {
        _currentShuffleIndex = shufflePos;
      } else {
        // regenerate and put selected first
        _generateShuffledIndices();
        _currentShuffleIndex = _shuffledIndices.indexOf(index);
      }
    }

    await _loadFileAtIndex(index);
    // start playback after load
    try {
      await _audioPlayer.play();
    } catch (e) {
      _errorMessage = 'Play failed: $e';
      notifyListeners();
    }
  }

  Future<void> play() async {
    // If nothing selected, select first track (but do not auto-add if empty)
    if (_currentIndex == -1) {
      if (_playlist.isEmpty) return;
      _currentIndex = 0;
      if (_isShuffle) {
        _generateShuffledIndices();
        _currentShuffleIndex = 0;
        _currentIndex = _shuffledIndices[0];
      }
      await _loadFileAtIndex(_currentIndex);
    }

    try {
      await _audioPlayer.play();
    } catch (e) {
      _errorMessage = 'Play failed: $e';
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration pos) async {
    await _audioPlayer.seek(pos);
  }

  // Next / previous implement shuffle awareness
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;

    if (_isShuffle) {
      if (_shuffledIndices.isEmpty) _generateShuffledIndices();
      if (_currentShuffleIndex < _shuffledIndices.length - 1) {
        _currentShuffleIndex++;
      } else {
        if (_repeatMode == RepeatMode.all) {
          _currentShuffleIndex = 0;
        } else {
          // no next
          return;
        }
      }
      final nextIndex = _shuffledIndices[_currentShuffleIndex];
      await playTrackAt(nextIndex);
    } else {
      if (_currentIndex < 0) return;
      if (_currentIndex < _playlist.length - 1) {
        await playTrackAt(_currentIndex + 1);
      } else if (_repeatMode == RepeatMode.all) {
        await playTrackAt(0);
      }
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    // if playback position > 3s then seek to beginning
    if (_currentPosition.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_isShuffle) {
      if (_currentShuffleIndex > 0) {
        _currentShuffleIndex--;
      } else {
        if (_repeatMode == RepeatMode.all) {
          _currentShuffleIndex = _shuffledIndices.length - 1;
        } else {
          return;
        }
      }
      final prevIndex = _shuffledIndices[_currentShuffleIndex];
      await playTrackAt(prevIndex);
    } else {
      if (_currentIndex > 0) {
        await playTrackAt(_currentIndex - 1);
      } else if (_repeatMode == RepeatMode.all) {
        await playTrackAt(_playlist.length - 1);
      }
    }
  }

  // ---------------------------
  // Shuffle / repeat / volume
  // ---------------------------
  void _generateShuffledIndices() {
    _shuffledIndices
      ..clear()
      ..addAll(List.generate(_playlist.length, (i) => i));

    if (_playlist.isEmpty) return;

    // Keep current index at front of shuffled list if selected
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      _shuffledIndices.remove(_currentIndex);
      _shuffledIndices.shuffle(Random());
      _shuffledIndices.insert(0, _currentIndex);
      _currentShuffleIndex = 0;
    } else {
      _shuffledIndices.shuffle(Random());
      _currentShuffleIndex = 0;
      _currentIndex = _shuffledIndices[0];
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;

    if (_isShuffle) {
      _generateShuffledIndices();
    } else {
      _shuffledIndices.clear();
      _currentShuffleIndex = 0;
    }
    notifyListeners();
  }

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  // ---------------------------
  // Helpers
  // ---------------------------
  void _handleTrackCompletion() {
    if (_repeatMode == RepeatMode.one) {
      // restart same track
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
      return;
    }

    // attempt to play next, respecting shuffle and repeat
    if (hasNext) {
      playNext();
    } else if (_repeatMode == RepeatMode.all && _playlist.isNotEmpty) {
      // restart from beginning
      if (_isShuffle) {
        _currentShuffleIndex = 0;
        final nextIdx = _shuffledIndices[_currentShuffleIndex];
        playTrackAt(nextIdx);
      } else {
        playTrackAt(0);
      }
    } else {
      // stop at end
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.pause();
    }
  }

  AudioMetadata _extractMetadata(String filePath) {
    final fileName = p.basenameWithoutExtension(filePath);
    return AudioMetadata(
      title: fileName,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      filePath: filePath,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimerCountdown?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
