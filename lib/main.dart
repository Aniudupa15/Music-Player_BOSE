  // import 'package:flutter/material.dart';
  // import 'package:provider/provider.dart';
  // import 'package:just_audio_background/just_audio_background.dart';
  //
  // import 'providers/audio_player_provider.dart';
  // import 'screens/home_screen.dart';
  // import 'theme/app_theme.dart';
  //
  // Future<void> main() async {
  //   WidgetsFlutterBinding.ensureInitialized();
  //
  //   // Initialize background audio
  //   // await JustAudioBackground.init(
  //   //   androidNotificationChannelId: 'com.example.music_player.channel.audio',
  //   //   androidNotificationChannelName: 'Music Playback',
  //   //   androidNotificationOngoing: true,
  //   // );
  //
  //   runApp(const MyApp());
  // }
  //
  // class MyApp extends StatelessWidget {
  //   const MyApp({super.key});
  //
  //   @override
  //   Widget build(BuildContext context) {
  //     return ChangeNotifierProvider(
  //       create: (_) => AudioPlayerProvider(),
  //       child: MaterialApp(
  //         title: 'Local Music Player',
  //         debugShowCheckedModeBanner: false,
  //         theme: AppTheme.darkTheme,
  //         home: const HomeScreen(),
  //       ),
  //     );
  //   }
  // }


  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:just_audio_background/just_audio_background.dart';

  import 'providers/audio_player_provider.dart';
  import 'screens/home_screen.dart';
  import 'theme/app_theme.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // await JustAudioBackground.init(
    //   androidNotificationChannelId: 'com.example.music_player.channel.audio',
    //   androidNotificationChannelName: 'Music Playback',
    //   androidNotificationOngoing: true,
    //   androidNotificationClickStartsActivity: true,
    //   androidNotificationIcon: 'mipmap/ic_launcher',
    // );

    runApp(const MyApp());
  }

  final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return ChangeNotifierProvider(
        create: (_) => AudioPlayerProvider(),
        child: MaterialApp(
          title: 'Local Music Player',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: const HomeScreen(),
        ),
      );
    }
  }
