import 'dart:typed_data';

class AudioMetadata {
  final String title;
  final String artist;
  final String album;
  final String filePath;

  // You already had this — RAW BYTES (UI only)
  final Uint8List? albumArt;

  // You MUST add this — FILE PATH (for background notifications)
  final String? albumArtPath;

  final Duration? duration;

  AudioMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    this.albumArt,
    this.albumArtPath,
    this.duration,
  });

  AudioMetadata copyWith({
    String? title,
    String? artist,
    String? album,
    String? filePath,
    Uint8List? albumArt,
    String? albumArtPath,
    Duration? duration,
  }) {
    return AudioMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      albumArt: albumArt ?? this.albumArt,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      duration: duration ?? this.duration,
    );
  }
}
