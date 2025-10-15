import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/providers/theme_provider.dart';
import 'core/services/audio_service.dart';
import 'core/services/database_service.dart';
import 'core/services/playlist_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optimize image cache for better performance and reduced memory
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 30 << 20;
  
  try {
    // Initialize Hive first
    await Hive.initFlutter();
    
    // Initialize services in parallel for faster startup
    await Future.wait([
      JustAudioBackground.init(
        androidNotificationChannelId: 'com.shrynex.auramusic.channel.audio',
        androidNotificationChannelName: 'AuraMusic Playbook',
        androidNotificationOngoing: true,
      ),
      DatabaseService.init(),
      PlaylistService.init(),
    ]);
    
    // Initialize audio service last
    await AudioPlayerService.init();
  } catch (_) {
    // Initialization error - app will continue with limited functionality
  }
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  
  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(
    const ProviderScope(
      child: AuraMusicApp(),
    ),
  );
}

class AuraMusicApp extends ConsumerWidget {
  const AuraMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'AuraMusic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
