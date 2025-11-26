import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // ---- Shuffle & Repeat ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _chip(
                    context,
                    icon: Icons.shuffle_rounded,
                    active: provider.isShuffle,
                    onTap: provider.toggleShuffle,
                  ),
                  _chip(
                    context,
                    icon: _repeatIcon(provider.repeatMode),
                    active: provider.repeatMode != RepeatMode.off,
                    onTap: provider.toggleRepeatMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ---- Main Controls ----
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _sideBtn(
                  icon: Icons.skip_previous_rounded,
                  enabled: provider.hasPrevious,
                  onTap: provider.hasPrevious ? provider.playPrevious : null,
                ),

                const SizedBox(width: 28),

                // Main play button
                GestureDetector(
                  onTap: provider.togglePlayPause,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).colorScheme.secondary
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      provider.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 28),

                _sideBtn(
                  icon: Icons.skip_next_rounded,
                  enabled: provider.hasNext,
                  onTap: provider.hasNext ? provider.playNext : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Small rounded chip (Shuffle / Repeat)
  Widget _chip(BuildContext context,
      {required IconData icon,
        required bool active,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? Theme.of(context).primaryColor
                : Colors.white30,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active
              ? Theme.of(context).primaryColor
              : Colors.white70,
        ),
      ),
    );
  }

  Widget _sideBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
          enabled ? Colors.white12 : Colors.white10.withOpacity(0.3),
        ),
        child: Icon(
          icon,
          size: 28,
          color: enabled ? Colors.white : Colors.white30,
        ),
      ),
    );
  }

  IconData _repeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Icons.repeat_rounded;
      case RepeatMode.all:
        return Icons.repeat_rounded;
      case RepeatMode.one:
        return Icons.repeat_one_rounded;
    }
  }
}
