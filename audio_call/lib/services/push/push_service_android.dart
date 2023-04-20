/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:convert';

import 'package:audio_call/services/auth_service.dart';
import 'package:audio_call/utils/log.dart';
import 'package:audio_call/utils/notification_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  print('PushServiceAndroid: _onBackgroundMessage data: ${message.data}');
  await Firebase.initializeApp();
  Map<String, dynamic> callDetails = jsonDecode(message.data['voximplant']);
  final String displayName = callDetails['display_name'];

  NotificationHelper().displayNotification(
    title: 'Incoming call',
    description: "from $displayName",
    payload: displayName,
  );
}

class PushServiceAndroid {
  late FirebaseMessaging _firebaseMessaging;
  static final PushServiceAndroid _instance = PushServiceAndroid._();

  factory PushServiceAndroid() {
    return _instance;
  }
  PushServiceAndroid._() {
    _configure();
  }

  Future<void> _configure() async {
    _log('configure');
    await Firebase.initializeApp();
    _firebaseMessaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
    _firebaseMessaging.onTokenRefresh.listen(_onToken);
    String? token = await _firebaseMessaging.getToken();
    _onToken(token);
  }

  // static Future<void> backgroundMessageHandler(
  //   Map<String, dynamic> message,
  // ) async {
  //   _log('onBackgroundMessage: $message');
  //   if (!message.containsKey('data')) {
  //     return Future.value();
  //   }
  //
  //   final Map<String, dynamic> data =
  //       Map<String, dynamic>.from(message['data']);
  //
  //   if (!data.containsKey('voximplant')) {
  //     return Future.value();
  //   }
  //
  //   await AuthService().pushNotificationReceived(data);
  //
  //   Map<String, dynamic> callDetails = jsonDecode(data['voximplant']);
  //   final String displayName = callDetails['display_name'];
  //
  //   NotificationHelper().displayNotification(
  //     title: 'Incoming call',
  //     description: "from $displayName",
  //     payload: displayName,
  //   );
  // }

  Future<void> _onMessage(RemoteMessage message) async {
    _log('PushServiceAndroid: onMessage data: ${message.data}');
    Map<String, dynamic> callDetails = jsonDecode(message.data['voximplant']);
    final String displayName = callDetails['display_name'];

    NotificationHelper().displayNotification(
      title: 'Incoming call',
      description: "from $displayName",
      payload: displayName,
    );
  }

  Future<void> _onToken(String? token) async {
    _log("onToken: $token");
    AuthService().voipToken = token;
  }

  static void _log<T>(T message) {
    log('PushServiceAndroid: ${message.toString()}');
  }
}
