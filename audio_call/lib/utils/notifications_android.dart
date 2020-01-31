/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:async';

import 'package:audio_call/screens/incoming_call_screen.dart';
import 'package:audio_call/services/navigation_service.dart';
import 'package:audio_call/utils/screen_arguments.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsAndroid {

  static int _notificationId = 0;
  static String _displayName;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const _timeout = const Duration(seconds: 15);

  static showCallNotification(String displayName) async {
    print('NotificationsAndroid: showCallNotification for $displayName');
    _displayName = displayName;
    var initializationSettingsAndroid =
      AndroidInitializationSettings('ic_vox_notification');
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, null);
    _localNotifications.initialize(initializationSettings, onSelectNotification: onSelectedNotification);
    var androidChannel = AndroidNotificationDetails(
        'Incoming calls channel', 'Incoming calls', 'Receive incoming calls',
        importance: Importance.Max, priority: Priority.High);
    NotificationDetails details = NotificationDetails(androidChannel, null);
    _notificationId = 1;
    await _localNotifications.show(_notificationId, 'Incoming call',
        'from $_displayName', details);
    Timer(_timeout, () {
      cancelNotification();
    });
  }

  static Future<bool> didNotificationLaunchApp() async {
    var details = await _localNotifications.getNotificationAppLaunchDetails();
    print('NotificationsAndroid: did notification launch app: ${details.didNotificationLaunchApp}');
    return details.didNotificationLaunchApp;
  }

  static void cancelNotification() async {
    print('NotificationsAndroid: cancelNotification: $_notificationId');
    _localNotifications.cancel(_notificationId);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('displayName');
    prefs.remove('pushPayload');
  }

  static Future<dynamic> onSelectedNotification(String params) {
    print('NotificationsAndroid: onSelectedNotification: $params');
    GetIt locator = GetIt.instance;
    locator<NavigationService>().navigateTo(IncomingCallScreen.routeName,
        arguments: CallArguments.withDisplayName(
            _displayName));
    return null;
  }
}
