/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

// import 'package:flutter_voip_push_notification/flutter_voip_push_notification.dart';
import 'package:audio_call/services/auth_service.dart';
import 'package:audio_call/utils/log.dart';

class PushServiceIOS {
  // final FlutterVoipPushNotification _voipPushNotification =
  // FlutterVoipPushNotification();
  //
  // factory PushServiceIOS() => _cache ?? PushServiceIOS._();
  // static PushServiceIOS _cache;
  // PushServiceIOS._() {
  //   _configure();
  //   _cache = this;
  // }
  //
  // Future<void> _configure() async {
  //   _log('configure');
  //   await _voipPushNotification.requestNotificationPermissions();
  //   // listen to voip device token changes
  //   _voipPushNotification.onTokenRefresh.listen(_onToken);
  //   // do configure voip push
  //   _voipPushNotification.configure(onMessage: onMessage, onResume: onResume);
  // }
  //
  // Future<void> onMessage(bool isLocal, Map<String, dynamic> payload) {
  //   // handle foreground notification
  //   _log('onMessage: $payload');
  //   AuthService().pushNotificationReceived(payload);
  //   return Future.value();
  // }
  //
  // Future<void> onResume(bool isLocal, Map<String, dynamic> payload) {
  //   // handle background notification
  //   _log('onResume: $payload');
  //   return Future.value();
  // }
  //
  // Future<void> _onToken(String token) async {
  //   _log('onToken: $token');
  //   AuthService().voipToken = token;
  // }
  //
  // void _log<T>(T message) {
  //   log('PushServiceiOS($hashCode): ${message.toString()}');
  // }
}
