/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:audio_call/screens/call_screen.dart';
import 'package:audio_call/screens/incoming_call_screen.dart';
import 'package:audio_call/screens/login_screen.dart';
import 'package:audio_call/screens/main_screen.dart';
import 'package:audio_call/services/auth_service.dart';
import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:audio_call/utils/notifications_android.dart';
import 'package:audio_call/utils/screen_arguments.dart';
import 'package:audio_call/services/navigation_service.dart';
import 'package:audio_call/services/push_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

GetIt getIt = GetIt.instance;

void main() {
  setupLocator();

  PushService();

  runApp(MyApp());
}

void setupLocator() {
  getIt.registerLazySingleton(() => NavigationService());
}

class MyApp extends StatelessWidget {
  MyApp({Key key}) : super(key: key) {
    if (Platform.isAndroid) {
      navigateToIncomingCallIfNeeded();
    }
  }

  //android only
  navigateToIncomingCallIfNeeded() async {
    bool navigate = await NotificationsAndroid.didNotificationLaunchApp();
    if (navigate) {
      NotificationsAndroid.cancelNotification();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String displayName = prefs.getString('displayName');
      String pushPayload = prefs.getString('pushPayload');
      Map<String, dynamic> payload = Map<String, dynamic>.from(jsonDecode(pushPayload));
      AuthService().pushNotificationReceived(payload);
      prefs.remove('displayName');
      prefs.remove('pushPayload');
      GetIt locator = GetIt.instance;
      locator<NavigationService>().navigateTo(IncomingCallScreen.routeName,
          arguments: CallArguments.withDisplayName(
              displayName));
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      title: 'Audio call',
      theme: ThemeData(
        primaryColor: VoximplantColors.primary,
        primaryColorDark: VoximplantColors.primaryDark,
        accentColor: VoximplantColors.accent,
      ),
      navigatorKey: getIt<NavigationService>().navigatorKey,
      onGenerateRoute: (settings) {
        if (settings.name == CallScreen.routeName) {
          final CallArguments args = settings.arguments;
          return MaterialPageRoute(
            builder: (context) {
              return CallScreen(
                callId: args.callId,
              );
            },
          );
        } else if (settings.name == IncomingCallScreen.routeName) {
          final CallArguments args = settings.arguments;
          return MaterialPageRoute(
            builder: (context) {
              return IncomingCallScreen(displayName: args.displayName);
            },
          );
        } else if (settings.name == MainScreen.routeName) {
          return MaterialPageRoute(builder: (context) {
            return MainScreen();
          });
        } else {
          return MaterialPageRoute(builder: (context) {
            return LoginScreen();
          });
        }
      },
      initialRoute: LoginScreen.routeName,
    );
  }
}
