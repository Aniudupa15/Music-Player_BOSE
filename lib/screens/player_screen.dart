import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/player_controls.dart';
import '../widgets/seek_bar_widget.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Consumer<AudioPlayerProvider>(
            builder: (context, provider, _) {
              final track = provider.currentTrack;
              if (track == null) return _empty(context);

              return Column(
                children: [
                  _appBar(context),
                  const SizedBox(height: 10),

                  // Smaller artwork
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: AlbumArtWidget(albumArt: track.albumArt),
                  ),

                  const SizedBox(height: 16),

                  // Track info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artist ?? "Unknown Artist",
                          style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.album ?? "",
                          style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Seek bar compact
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    child: SeekBarWidget(),
                  ),

                  const SizedBox(height: 16),

                  // Compact controls
                  const PlayerControls(),

                  const Spacer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: const [
                Icon(Icons.music_note_rounded, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text("Now Playing",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white10,
            ),
            child: const Icon(Icons.queue_music_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return const Center(
      child: Text(
        "No track loaded",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
