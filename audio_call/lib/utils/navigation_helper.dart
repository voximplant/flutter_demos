/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:audio_call/screens/active_call/active_call.dart';
import 'package:audio_call/screens/call_failed/call_failed_page.dart';
import 'package:audio_call/screens/incoming_call/incoming_call.dart';
import 'package:audio_call/screens/incoming_call/incoming_call_page.dart';
import 'package:audio_call/screens/login/login.dart';
import 'package:audio_call/screens/main/main_page.dart';
import 'package:flutter/material.dart';

class NavigationHelper {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> pushToIncomingCall({
    String? caller,
  }) =>
      navigatorKey.currentState!.pushReplacementNamed(
        AppRoutes.incomingCall,
        arguments: IncomingCallPageArguments(endpoint: caller ?? "User"),
      );

  static Future<void> pushToActiveCall({
    required bool isIncoming,
    required String callTo,
  }) =>
      navigatorKey.currentState!.pushReplacementNamed(
        AppRoutes.activeCall,
        arguments: ActiveCallPageArguments(
          isIncoming: isIncoming,
          endpoint: callTo,
        ),
      );

  static Future<void> pop() => navigatorKey.currentState!.maybePop();
}

class AppRoutes {
  static const String login = LoginPage.routeName;
  static const String main = MainPage.routeName;
  static const String incomingCall = IncomingCallPage.routeName;
  static const String activeCall = ActiveCallPage.routeName;
  static const String callFailed = CallFailedPage.routeName;
}
