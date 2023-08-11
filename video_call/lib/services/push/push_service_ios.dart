// /// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
//
// import 'package:video_call/services/auth_service.dart';
// import 'package:video_call/utils/log.dart';
// import 'package:flutter/services.dart';
//
// class PushServiceIOS {
//   final MethodChannel _channel = const MethodChannel('plugins.voximplant.com/pushkit');
//   final EventChannel _pushKitEventChannel = const EventChannel('plugins.voximplant.com/pushkitevents');
//
//   factory PushServiceIOS() {
//     return _instance;
//   }
//   static final PushServiceIOS _instance = PushServiceIOS._();
//   PushServiceIOS._() {
//     _log('configure');
//     _pushKitEventChannel.receiveBroadcastStream('pushkit').listen(_pushKitEventListener);
//     _configure();
//   }
//
//   Future<void> _configure() async {
//     final token = await _channel.invokeMethod("voipToken");
//     if (token != null) {
//       _log('configure: token $token}');
//       AuthService().voipToken = token;
//     }
//   }
//
//   void _pushKitEventListener(dynamic event) {
//     final Map<dynamic, dynamic> map = event;
//     if (map['event'] == 'didUpdatePushCredentials') {
//       final token = map["token"];
//       if (token != null) {
//         _log('didUpdatePushCredentials: token $token}');
//         AuthService().voipToken = token;
//       }
//     }
//     if (map['event'] == 'didReceiveIncomingPushWithPayload') {
//       final payload = map['payload'];
//       if (payload != null) {
//         _log('didReceiveIncomingPushWithPayload: payload $payload}');
//         Map<String, dynamic> pushPayload = Map<String, dynamic>.from(payload);
//         AuthService().pushNotificationReceived(pushPayload);
//       }
//     }
//   }
//
//   void _log<T>(T message) {
//     log('PushServiceiOS($hashCode): ${message.toString()}');
//   }
// }
