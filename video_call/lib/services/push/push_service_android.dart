/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/notification_service.dart';

class PushServiceAndroid {
  final FirebaseMessaging _firebaseMessaging;

  factory PushServiceAndroid() => _cache ?? PushServiceAndroid._();
  static PushServiceAndroid _cache;
  PushServiceAndroid._() : _firebaseMessaging = FirebaseMessaging() {
    _configure();
    _cache = this;
  }

  static Future<void> backgroundMessageHandler(
      Map<String, dynamic> message) async {

    if (!message.containsKey('data')) {
      return null;
    }

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(message['data']);

    if (!data.containsKey('voximplant')) {
      return null;
    }

    AuthService().pushNotificationReceived(data);

    Map<String, dynamic> callDetails = jsonDecode(data['voximplant']);
    final String displayName = callDetails['display_name'];

    NotificationService().displayNotification(
      title: 'Incoming call',
      description: "from $displayName",
      payload: displayName,
    );

    return null;
  }

  Future<void> _configure() async {
    _firebaseMessaging.configure(onBackgroundMessage: backgroundMessageHandler);

    _firebaseMessaging.onTokenRefresh.listen(_onToken);

    String token = await _firebaseMessaging.getToken();
    _onToken(token);

    return null;
  }

  Future<void> _onToken(String token) async {
    print("onToken: " + token);
    AuthService().voipToken = token;
  }
}