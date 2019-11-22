/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.

import 'dart:convert';
import 'dart:io';
import 'package:audio_call/utils/app_state_helper.dart';
import 'package:audio_call/utils/notifications_android.dart';
import 'package:flutter_voip_push_notification/flutter_voip_push_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audio_call/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PushService {
  static PushService _singleton;

  factory PushService() {
    if (_singleton == null) {
      if (Platform.isIOS) {
        _singleton = PushServiceIOS._();
      } else if (Platform.isAndroid) {
        _singleton = PushServiceAndroid._();
      }
    }
    return _singleton;
  }

  PushService._() {
    _configure();
  }

  Future<void> _configure();

  void _onToken(String token) {
    print("onToken: " + token);
    AuthService().pushToken = token;
  }
}

class PushServiceIOS extends PushService {
  final FlutterVoipPushNotification _voipPushNotification =
      FlutterVoipPushNotification();

  PushServiceIOS._() : super._();

  @override
  Future<void> _configure() async {
    await _voipPushNotification.requestNotificationPermissions();

    // listen to voip device token changes
    _voipPushNotification.onTokenRefresh.listen(_onToken);

    // do configure voip push
    _voipPushNotification.configure(onMessage: onMessage, onResume: onResume);
  }

  /// Called to receive notification when app is in foreground
  ///
  /// [isLocal] is true if its a local notification or false otherwise (remote notification)
  /// [payload] the notification payload to be processed. use this to present a local notification
  Future<dynamic> onMessage(bool isLocal, Map<String, dynamic> payload) {
    // handle foreground notification
    print("received on foreground payload: $payload, isLocal=$isLocal");
    AuthService().pushNotificationReceived(payload);

    return null;
  }

  /// Called to receive notification when app is resuming from background
  ///
  /// [isLocal] is true if its a local notification or false otherwise (remote notification)
  /// [payload] the notification payload to be processed. use this to present a local notification
  Future<dynamic> onResume(bool isLocal, Map<String, dynamic> payload) {
    // handle background notification
    print("received on background payload: $payload, isLocal=$isLocal");
    return null;
  }
}

class PushServiceAndroid extends PushService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  PushServiceAndroid._() : super._();

  @override
  Future<void> _configure() async {
    _firebaseMessaging.configure(
      onBackgroundMessage: notificationMessageHandler,
    );

    _firebaseMessaging.onTokenRefresh.listen(_onToken);

    String token = await _firebaseMessaging.getToken();
    _onToken(token);

    return null;
  }

  static Future<void> notificationMessageHandler(
      Map<String, dynamic> message) async {
    print('PushServiceAndroid: notificationMessageHandler($message)');

    if (AppStateHelper().appState == AppState.NotLaunched) {
      Map<String, dynamic> payload = message.containsKey('data') ?
      Map<String, dynamic>.from(message['data']) : null;

      if (payload != null) {
        Map<String, dynamic> callDetails = jsonDecode(payload['voximplant']);
        String displayName = callDetails['display_name'];
        print('PushServiceAndroid: push for call from $displayName');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('displayName', displayName);
        prefs.setString('pushPayload', jsonEncode(payload));

        print('PushServiceAndroid: show call notification');
        NotificationsAndroid.showCallNotification(displayName);
      }
    }

    return null;
  }
}
