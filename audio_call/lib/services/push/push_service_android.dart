/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:convert';

import 'package:audio_call/services/auth_service.dart';
import 'package:audio_call/utils/log.dart';
import 'package:audio_call/utils/notification_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp();
  if (message.data.isEmpty) {
    return Future.value();
  }
  if (!message.data.containsKey("voximplant")) {
    return Future.value();
  }
  PushServiceAndroid._log("Push notification is received in the background: ${message.data}");
  await AuthService().pushNotificationReceived(message.data);

  Map<String, dynamic> callDetails = jsonDecode(message.data['voximplant']);
  final String displayName = callDetails['display_name'];

  NotificationHelper().displayNotification(
    title: 'Incoming call',
    description: "from $displayName",
    payload: displayName,
  );
}

class PushServiceAndroid {

  factory PushServiceAndroid() => _cache ?? PushServiceAndroid._();
  static PushServiceAndroid? _cache;
  PushServiceAndroid._() {
    try {
      _configure();
    } catch (e) {
      _log("Failed to initialize Firebase: $e");
    }
    _cache = this;
  }

  Future<void> _configure() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log("Push notification is received in the foreground ${message.data}");
      AuthService().pushNotificationReceived(message.data);
    });
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      AuthService().voipToken = token;
    }
  }

  static void _log<T>(T message) {
    log('PushServiceAndroid: ${message.toString()}');
  }
}
