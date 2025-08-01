import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/services/firebase_service.dart';
import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/cart_provider.dart';
import 'routes/app_router.dart';

void main() async {
  // Catch any errors during app initialization
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Print debug info
    debugPrint('🔍 App initialization started');
    
    // Initialize Firebase
    debugPrint('🔍 Initializing Firebase...');
    await FirebaseService.initialize();
    debugPrint('✅ Firebase initialized successfully');
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    debugPrint('🚀 Starting EggstraFarmsApp...');
    runApp(const EggstraFarmsApp());
  } catch (e, stackTrace) {
    // Print error information for debugging
    debugPrint('❌ ERROR DURING APP INITIALIZATION: $e');
    debugPrint('📋 STACK TRACE: $stackTrace');
    
    // Show a minimal error app instead of crashing completely
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong during initialization',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Attempt to restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    ));
  }
}

class EggstraFarmsApp extends StatelessWidget {
  const EggstraFarmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) => CartProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, cart) => cart ?? CartProvider(auth),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}


