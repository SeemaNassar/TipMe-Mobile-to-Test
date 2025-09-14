// lib/main.dart (updated)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'; 
import 'package:flutter/foundation.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:tipme_app/core/storage/storage_service.dart';
import 'package:tipme_app/data/services/language_service.dart';
import 'package:tipme_app/di/gitIt.dart';
import 'package:tipme_app/routs/app_routs.dart';
import 'package:tipme_app/services/signalRService.dart';
import 'package:tipme_app/services/notificationInitializationService.dart';
import 'package:tipme_app/utils/colors.dart';
import 'package:tipme_app/core/dio/client/dio_client_pool.dart';
import 'package:tipme_app/providersChangeNotifier/profileSetupProvider.dart';
import 'package:tipme_app/core/dio/interceptors/auth_interceptor.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; 

// Global navigator key for error navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global error handler
void handleGlobalError(Object error, StackTrace stackTrace, {String? context}) {
  print('=== GLOBAL ERROR CAUGHT ===');
  print('Context: ${context ?? "Unknown"}');
  print('Error: $error');
  print('StackTrace: $stackTrace');
  print('========================');

  // Navigate to error screen using global navigator
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // navigator.pushNamed(
      //   AppRoutes.errorScreen,
      //   arguments: {
      //     'title': 'Unexpected Error',
      //     'message': 'An unexpected error occurred in the application. This information has been logged for debugging.',
      //     'errorDetails': 'Context: ${context ?? "Global"}\n\nError: $error\n\nStack Trace:\n$stackTrace',
      //     'showRetry': false,
      //     'showGoBack': true,
      //     'onGoBack': () => navigator.pop(),
      //   },
      // );
    }
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  // You can't show a Flutter UI here, but you can process data and schedule a notification.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling FIRST
  FlutterError.onError = (FlutterErrorDetails details) {
    handleGlobalError(
      details.exception,
      details.stack ?? StackTrace.current,
      context: 'Flutter Framework Error',
    );
  };

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    handleGlobalError(
      error,
      stack,
      context: 'Async Error',
    );
    return true;
  };

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  await StorageService.init();
  DioClientPool.instance.init();
  await setupServiceLocator();

  try {} catch (e) {
    print('Failed to connect to notification hub: $e');
  }

  // Wrap the entire app in error boundary
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageService()),
        ChangeNotifierProvider(create: (context) => ProfileSetupProvider()),
      ],
      child: ErrorBoundary(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotificationInitializationService.instance.initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SignalRService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // Reconnect when app comes to foreground
        if (!SignalRService.instance.isConnected) {
          SignalRService.instance.startConnection();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Keep connection alive but could implement logic here if needed
        break;
      case AppLifecycleState.detached:
        // Stop connection when app is terminated
        SignalRService.instance.stopConnection();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return OverlaySupport.global(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'TipMe',
        debugShowCheckedModeBanner: false,
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        initialRoute: AppRoutes.splashScreen,
        onGenerateRoute: AppRoutes.generateRoute,
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Page Not Found')),
              body: const Center(
                child: Text('The requested page was not found.'),
              ),
            ),
          );
        },
        theme: ThemeData(
          primaryColor: AppColors.secondary,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
