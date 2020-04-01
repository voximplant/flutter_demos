/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter_voip_push_notification/flutter_voip_push_notification.dart';
import 'package:video_call/services/auth_service.dart';

class PushServiceIOS {
  final FlutterVoipPushNotification _voipPushNotification =
      FlutterVoipPushNotification();

  factory PushServiceIOS() => _cache ?? PushServiceIOS._();
  static PushServiceIOS _cache;
  PushServiceIOS._() {
    _configure();
    _cache = this;
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

  Future<void> _onToken(String token) async {
    print("onToken: " + token);
    await AuthService().setVoipToken(token);
  }

  Future<void> _configure() async {
    await _voipPushNotification.requestNotificationPermissions();

    // listen to voip device token changes
    _voipPushNotification.onTokenRefresh.listen(_onToken);

    // do configure voip push
    _voipPushNotification.configure(onMessage: onMessage, onResume: onResume);
  }
}
