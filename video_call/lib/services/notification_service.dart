/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:video_call/services/navigation_helper.dart';

// Used in android only
class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  factory NotificationService() => _cache ?? NotificationService._();
  static NotificationService _cache;
  NotificationService._() {
    _configure();
    _cache = this;
  }

  Future<void> _configure() async {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    var initializationSettings =
        InitializationSettings(initializationSettingsAndroid, null);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future<void> displayNotification(
      {@required String title, @required String description, String payload}) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'VoximplantChannelIncomingCalls',
      'CallChannel',
      'Incoming calls notifications',
      importance: Importance.High,
      priority: Priority.High,
      ticker: 'incoming call',
    );
    var platformChannelSpecifics =
        NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        100, title, description, platformChannelSpecifics,
        payload: payload);
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<bool> didNotificationLaunchApp() async {
    var details = await flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    print('NotificationsAndroid: did notification launch app: ${details
        .didNotificationLaunchApp}');
    return details.didNotificationLaunchApp;
  }

  Future<void> onSelectNotification(String payload) async {
    print('NotificationService onSelect $payload');

    NavigationHelper.pushToIncomingCall(caller: payload);
  }
}