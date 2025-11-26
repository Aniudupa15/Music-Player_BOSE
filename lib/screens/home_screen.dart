import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../providers/audio_player_provider.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';
import 'playlist_screen.dart';
import 'album_screen.dart';

// ACCESS GLOBAL SNACKBAR KEY
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoadingAudio = false;
  int _loadedSongsCount = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _requestPermissionsAndLoadAudio();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // PERMISSIONS + AUTO-SCAN (NO AUTOPLAY)
  // ---------------------------------------------------------------------
  Future<void> _requestPermissionsAndLoadAudio() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.audio.isDenied) {
      final status = await Permission.audio.request();
      if (status.isDenied) {
        if (mounted) _showPermissionDialog();
        return;
      }
    }

    await _autoLoadAudioFiles();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Please grant audio permission to scan your music files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _autoLoadAudioFiles() async {
    if (_isLoadingAudio) return;

    setState(() => _isLoadingAudio = true);

    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);

    try {
      final List<String> musicPaths = [];
      final dirs = await getExternalStorageDirectories();

      if (dirs != null) {
        for (var d in dirs) {
          if (await Directory("${d.path}/Music").exists()) {
            musicPaths.add("${d.path}/Music");
          }
        }
      }

      const commonDirs = [
        "/storage/emulated/0/Music",
        "/storage/emulated/0/Download",
        "/sdcard/Music",
        "/sdcard/Download",
      ];

      for (var p in commonDirs) {
        if (await Directory(p).exists()) musicPaths.add(p);
      }

      final List<String> songs = [];
      const exts = ["mp3", "wav", "m4a", "aac", "flac", "ogg"];

      for (var dirPath in musicPaths) {
        try {
          final dir = Directory(dirPath);
          await for (var e in dir.list(recursive: true)) {
            if (e is File) {
              final ext = e.path.split('.').last.toLowerCase();
              if (exts.contains(ext)) songs.add(e.path);
            }
          }
        } catch (_) {}
      }

      if (songs.isNotEmpty) {
        await provider.addMultipleToPlaylist(songs);
        _loadedSongsCount = songs.length;

        // USE GLOBAL SNACKBAR
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text("Loaded ${songs.length} songs"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  // ---------------------------------------------------------------------
  // PICK FILES
  // ---------------------------------------------------------------------
  Future<void> _pickSingle(BuildContext context) async {
    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac'],
    );

    if (result == null || result.files.single.path == null) return;

    await provider.addToPlaylist(result.files.single.path!);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }

  Future<void> _pickMultiple(BuildContext context) async {
    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac'],
    );

    if (result == null) return;

    final files =
    result.files.where((f) => f.path != null).map((f) => f.path!).toList();

    await provider.addMultipleToPlaylist(files);

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text("Added ${files.length} songs"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SLEEP TIMER
  // ---------------------------------------------------------------------
  void _showSleepTimerDialog(BuildContext context) {
    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Sleep Timer",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(),
            ...[15, 30, 45, 60, 120].map(
                  (min) => ListTile(
                leading: const Icon(Icons.timer),
                title: Text("Turn off in $min minutes"),
                onTap: () {
                  provider.setSleepTimer(min);

                  rootScaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text("Sleep timer set for $min minutes"),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.pop(context);
                },
              ),
            ),
            if (provider.isSleepTimerActive)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  provider.cancelSleepTimer();
                  Navigator.pop(context);
                },
                child: const Text("Cancel Timer"),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UI BUILDING
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: Consumer<AudioPlayerProvider>(
                    builder: (_, p, __) {
                      if (_isLoadingAudio) return _loadingView();
                      if (!p.hasTrack) return _emptyView();
                      return _libraryView(p);
                    },
                  ),
                ),
              ],
            ),
          ),

          // MINI PLAYER
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------

  Widget _background() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF311B92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<AudioPlayerProvider>(
        builder: (_, p, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Music Player",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed:
                    p.hasTrack ? () => _showSleepTimerDialog(context) : null,
                    icon: Icon(
                      p.isSleepTimerActive
                          ? Icons.bedtime
                          : Icons.bedtime_outlined,
                      color:
                      p.isSleepTimerActive ? Colors.amber : Colors.white70,
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoadingAudio ? null : _autoLoadAudioFiles,
                    icon: _isLoadingAudio
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ))
                        : const Icon(Icons.refresh, color: Colors.white70),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _loadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 1 + (_pulseController.value * 0.1),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white24,
                child: const Icon(Icons.music_note,
                    size: 45, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Scanning music...",
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music,
                size: 90, color: Colors.white54),
            const SizedBox(height: 20),
            const Text("No Music Found",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            const Text("Add songs to start listening",
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () => _pickSingle(context),
              icon: const Icon(Icons.audio_file),
              label: const Text("Add Song"),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _pickMultiple(context),
              icon: const Icon(Icons.library_add),
              label: const Text("Add Multiple"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _libraryView(AudioPlayerProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _menuCard(
          icon: Icons.play_circle_fill,
          title: "Now Playing",
          subtitle: provider.currentTrack?.title ?? "No track selected",
          colors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const PlayerScreen())),
        ),
        const SizedBox(height: 12),
        _menuCard(
          icon: Icons.queue_music,
          title: "Playlist",
          subtitle: "${provider.playlist.length} songs",
          colors: const [Color(0xFFF093FB), Color(0xFFF5576C)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PlaylistScreen())),
        ),
        const SizedBox(height: 12),
        _menuCard(
          icon: Icons.album,
          title: "Albums",
          subtitle: "Browse by album",
          colors: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AlbumScreen())),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickSingle(context),
                icon: const Icon(Icons.audio_file),
                label: const Text("Add Song"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickMultiple(context),
                icon: const Icon(Icons.library_add),
                label: const Text("Add Multiple"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
