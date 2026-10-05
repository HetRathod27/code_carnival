import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/client.dart';

class PushNotificationPayload {
  final String title;
  final String body;
  final String? type;
  final String? tokenId;
  final Map<String, dynamic> data;

  PushNotificationPayload({
    required this.title,
    required this.body,
    this.type,
    this.tokenId,
    this.data = const {},
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _client = ApiClient();
  final StreamController<PushNotificationPayload> _notificationStream =
      StreamController<PushNotificationPayload>.broadcast();

  Stream<PushNotificationPayload> get onNotification => _notificationStream.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize({
    Function(PushNotificationPayload)? onSelectNotification,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _fcmToken = prefs.getString('ql_fcm_token');

    if (_fcmToken == null) {
      // In development mode or until Firebase project is configured, generate a stable mock FCM token
      _fcmToken = 'mock_fcm_${DateTime.now().millisecondsSinceEpoch}_${prefs.getString('ql_phone') ?? 'device'}';
      await prefs.setString('ql_fcm_token', _fcmToken!);
    }

    final authToken = prefs.getString('ql_token');
    final lang = prefs.getString('ql_language') ?? 'en';

    if (authToken != null && authToken.isNotEmpty) {
      await registerWithBackend(authToken: authToken, language: lang);
    }
  }

  Future<void> registerWithBackend({
    required String authToken,
    String language = 'en',
  }) async {
    if (_fcmToken == null) return;

    try {
      await _client.registerDevice(
        token: authToken,
        fcmToken: _fcmToken!,
        platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        language: language,
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to register device: $e');
    }
  }

  /// Simulate receiving a push notification (used in dev/test/demo)
  void simulateNotification({
    required String title,
    required String body,
    String? type,
    String? tokenId,
  }) {
    final payload = PushNotificationPayload(
      title: title,
      body: body,
      type: type,
      tokenId: tokenId,
    );
    _notificationStream.add(payload);
  }

  void dispose() {
    _notificationStream.close();
  }
}
