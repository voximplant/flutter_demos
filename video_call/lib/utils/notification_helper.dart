/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:video_call/utils/log.dart';

import 'navigation_helper.dart';

// Used in Android only
// On iOS CallKit is used to notify user about calls
class NotificationHelper {
  int _notificationId = 100;
  final FlutterLocalNotificationsPlugin _plugin;

  static final NotificationHelper _instance = NotificationHelper._();

  factory NotificationHelper() {
    return _instance;
  }

  NotificationHelper._() : _plugin = FlutterLocalNotificationsPlugin() {
    _configure();
  }

  Future<void> _configure() async {
    print('NotificationHelper: _configure');
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (notificationResponse) async {
        _log('NotificationHelper onSelect $notificationResponse');
        await NavigationHelper.pushToIncomingCall(caller: notificationResponse.payload);
        return Future.value();
      },
    );
  }

  Future<void> displayNotification({
    required String title,
    required String description,
    required String payload,
  }) async {
    _log('displayNotification title: $title, description: $description');
    await _plugin.show(
      _notificationId,
      title,
      description,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'VoximplantChannelIncomingCalls',
          'CallChannel',
          channelDescription: 'Incoming calls notifications',
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'incoming call',
        ),
      ),
      payload: payload,
    );
    Timer(const Duration(seconds: 15), () {
      cancelNotification();
    });
  }

  Future<void> cancelNotification() async {
    await _plugin.cancelAll();
  }

  Future<bool?> didNotificationLaunchApp() async {
    var details = await _plugin.getNotificationAppLaunchDetails();
    _log('didNotificationLaunchApp: ${details?.didNotificationLaunchApp}');
    return details?.didNotificationLaunchApp;
  }

  void _log<T>(T message) {
    log('NotificationHelper($hashCode): ${message.toString()}');
  }
}

