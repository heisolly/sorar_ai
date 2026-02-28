import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:provider/provider.dart';

import 'screens/auth/splash_screen.dart';
import 'config/supabase_config.dart';
import 'config/navigation_key.dart';
import 'theme/app_theme.dart';
import 'services/ai_service.dart';
import 'services/coach_service.dart';
import 'services/notification_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      anonKey: SupabaseConfig.anonKey,
      debug: false, // Set to true for debugging
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
        timeout: Duration(seconds: 30),
      ),
    );
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
    // App can still run with local features if Supabase fails
  }

  // Initialize notification service
  try {
    await NotificationService().initialize();
    debugPrint('✅ Notification service initialized successfully');
  } catch (e) {
    debugPrint('❌ Notification service initialization failed: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Dark background
    ),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AiService>(create: (_) => AiService()),
        ChangeNotifierProvider<CoachService>(create: (_) => CoachService()),
      ],
      child: MaterialApp(
        title: 'Parot',
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: messengerKey,
        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
