import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, provider, _) {
        if (!provider.hasTrack || provider.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = provider.currentTrack!;
        final progress = provider.totalDuration.inSeconds > 0
            ? provider.currentPosition.inSeconds /
            provider.totalDuration.inSeconds
            : 0.0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            );
          },
          child: Container(
            height: 80,
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.94),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.94),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Progress bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      color: Colors.white.withOpacity(0.25),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        // Album Art
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (track.albumArt != null &&
                                track.albumArt!.isNotEmpty)
                                ? Image.memory(track.albumArt!,
                                fit: BoxFit.cover)
                                : Icon(Icons.music_note_rounded,
                                size: 36,
                                color: Colors.white.withOpacity(0.9)),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Title + artist (NO SCROLL)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  // Wave animation
                                  AnimatedBuilder(
                                    animation: _waveController,
                                    builder: (_, __) {
                                      double h = provider.isPlaying
                                          ? 6 + (_waveController.value * 6)
                                          : 4;
                                      return Row(
                                        children: [
                                          _waveBar(h),
                                          _waveBar(h * 1.2),
                                          _waveBar(h * 0.8),
                                        ],
                                      );
                                    },
                                  ),

                                  const SizedBox(width: 6),

                                  // Artist
                                  Expanded(
                                    child: Text(
                                      track.artist ?? "Unknown Artist",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                        Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        // Controls
                        Row(
                          children: [
                            InkWell(
                              onTap: provider.hasPrevious
                                  ? provider.playPrevious
                                  : null,
                              child: Icon(
                                Icons.skip_previous_rounded,
                                size: 28,
                                color: provider.hasPrevious
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),

                            const SizedBox(width: 5),

                            GestureDetector(
                              onTap: provider.togglePlayPause,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  provider.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 28,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            InkWell(
                              onTap: provider.hasNext
                                  ? provider.playNext
                                  : null,
                              child: Icon(
                                Icons.skip_next_rounded,
                                size: 28,
                                color: provider.hasNext
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Wave bar helper
  Widget _waveBar(double height) {
    return Container(
      width: 3,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
