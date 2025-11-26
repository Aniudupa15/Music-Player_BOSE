import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/mini_player.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  Future<void> _addMoreSongs(BuildContext context) async {
    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePaths = result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();

        await provider.addMultipleToPlaylist(filePaths);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${filePaths.length} songs added'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E293B),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Playlist',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Consumer<AudioPlayerProvider>(
                          builder: (context, provider, _) {
                            if (provider.playlist.isNotEmpty) {
                              return IconButton(
                                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Clear Playlist'),
                                      content: const Text(
                                        'Remove all songs from playlist?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            provider.clearPlaylist();
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Clear'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer<AudioPlayerProvider>(
                      builder: (context, provider, _) {
                        if (provider.playlist.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.music_off,
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No songs in playlist',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton.icon(
                                  onPressed: () => _addMoreSongs(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Songs'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: provider.playlist.length,
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 100, // Space for mini player
                          ),
                          itemBuilder: (context, index) {
                            final track = provider.playlist[index];
                            final isPlaying = index == provider.currentIndex;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isPlaying
                                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                                  : Theme.of(context).cardColor,
                              child: ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColor,
                                        Theme.of(context).colorScheme.secondary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.equalizer : Icons.music_note,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  track.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  track.artist,
                                  style: TextStyle(color: Colors.grey[400]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPlaying)
                                      Icon(
                                        provider.isPlaying
                                            ? Icons.volume_up
                                            : Icons.pause,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        provider.removeFromPlaylist(index);
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  provider.playTrackAt(index);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _addMoreSongs(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add More Songs'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Mini Player
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}