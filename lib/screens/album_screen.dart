import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import 'player_screen.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioPlayerProvider>(context);

    // Group tracks by album
    final albums = <String, List<int>>{};
    for (var i = 0; i < provider.playlist.length; i++) {
      final album = provider.playlist[i].album;
      albums.putIfAbsent(album, () => []).add(i);
    }

    return Scaffold(
      body: Container(
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
                      'Albums',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: albums.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.album,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No albums found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final albumName = albums.keys.elementAt(index);
                    final trackCount = albums[albumName]!.length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.album,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        title: Text(
                          albumName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '$trackCount ${trackCount == 1 ? 'track' : 'tracks'}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        trailing: Icon(
                          Icons.play_circle_outline,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                        onTap: () {
                          final trackIndexes = albums[albumName]!;
                          final albumTracks = trackIndexes
                              .map((i) => provider.playlist[i])
                              .toList();

                          provider.setPlaylist(albumTracks);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlayerScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}