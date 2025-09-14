import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tipme_app/core/storage/storage_service.dart';
import 'package:tipme_app/dtos/fcmTokenDto.dart';
import 'package:tipme_app/services/tipReceiverService.dart';
import 'package:tipme_app/services/notificationPopupService.dart';
import 'package:tipme_app/viewModels/notificationDataModel.dart';
import 'package:tipme_app/di/gitIt.dart';

class NotificationInitializationService {
  static final NotificationInitializationService _instance = 
      NotificationInitializationService._internal();
  
  factory NotificationInitializationService() => _instance;
  
  NotificationInitializationService._internal();

  static NotificationInitializationService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialize notifications - can be called from app startup or after login
  Future<void> initializeNotifications() async {
    try {
      print('Starting notification initialization...');
      
      // Request permission for notifications
      await _requestPermission();
      
      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token == null) {
        print('Failed to get FCM token');
        return;
      }

      // Save token to storage
      await StorageService.save('fcm_token', token);
      print('FCM token saved to storage');

      // Setup foreground listener
      _setupForegroundListener();
      
      // Setup interaction handlers
      await _setupInteractedMessage();

      // Register device with backend if user is logged in
      await _registerDeviceWithBackend(token);
      
      print('Notification initialization completed successfully');
    } catch (e) {
      print('Error during notification initialization: $e');
    }
  }

  /// Request permission for notifications (especially important for iOS/web)
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  /// Handle messages when the app is in the foreground
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        
        // Create notification data model from Firebase message
        final notificationData = NotificationDataModel(
          title: message.notification?.title ?? 'New Notification',
          subtitle: message.notification?.body ?? 'You have a new notification',
          createdAt: DateTime.now(),
        );
        
        // Show notification using your existing popup service
        if (message.data['type'] == 'tip_received') {
          NotificationPopupService.instance.showTipReceivedPopup(notificationData);
        } else {
          NotificationPopupService.instance.showNotificationPopup(notificationData);
        }
      }
    });
  }

  /// Handle user tapping on a notification when the app is in the background/terminated
  Future<void> _setupInteractedMessage() async {
    // Get any messages which caused the application to open from a terminated state.
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle when a notification is opened while the app is in the background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    // You can navigate to a specific screen based on the message data
    // Navigator.pushNamed(context, '/message', arguments: MessageArguments(message));
    print('Message opened from notification: ${message.messageId}');
    print('Message data: ${message.data}');
  }

  /// Register device with backend
  Future<void> _registerDeviceWithBackend(String token) async {
    try {
      // Check if user is logged in
      String? userId = await StorageService.get('user_id');
      String? userToken = await StorageService.get('user_token');
      
      if (userId == null || userToken == null) {
        print('User not logged in, skipping device registration');
        return;
      }

      final tipReceiverService = getIt<TipReceiverService>();
      final firebaseTokenDto = FcmTokenDto(token: token);
      
      print('Registering device with backend for user: $userId');
      await tipReceiverService.registerDevice(firebaseTokenDto);
      
      print('Device registered successfully with backend');
    } catch (e) {
      print('Error registering device with backend: $e');
    }
  }

  /// Reinitialize notifications after user login
  Future<void> reinitializeAfterLogin() async {
    try {
      print('Reinitializing notifications after login...');
      await initializeNotifications();
    } catch (e) {
      print('Error reinitializing notifications after login: $e');
    }
  }
}
