/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:video_call/services/auth_service.dart';
import 'package:video_call/utils/log.dart';
import 'package:video_call/utils/notification_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

final ReceivePort backgroundMessagePort = ReceivePort();
const String backgroundMessageIsolateName = 'fcm_background_msg_isolate';

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  print('PushServiceAndroid: _onBackgroundMessage data: ${message.data}');
  await Firebase.initializeApp();

  final port = IsolateNameServer.lookupPortByName(backgroundMessageIsolateName);
  if (port != null) {
    port.send(message.data);
  } else {
    Map<String, dynamic> callDetails = jsonDecode(message.data['voximplant']);
    final String displayName = callDetails['display_name'];
    NotificationHelper().displayNotification(
      title: 'Incoming call',
      description: "from $displayName",
      payload: displayName,
    );
    await AuthService().pushNotificationReceived(message.data);
  }
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

    IsolateNameServer.registerPortWithName(
      backgroundMessagePort.sendPort,
      backgroundMessageIsolateName,
    );

    backgroundMessagePort.listen(backgroundMessagePortHandler);
  }

  void backgroundMessagePortHandler(message) async {
    _log('firebase message received on main isolate $message');
    await AuthService().pushNotificationReceived(message);
    Map<String, dynamic> callDetails = jsonDecode(message['voximplant']);
    final String displayName = callDetails['display_name'];
    NotificationHelper().displayNotification(
      title: 'Incoming call',
      description: "from $displayName",
      payload: displayName,
    );
  }

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
