/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.

import 'package:audio_call/screens/call_screen.dart';
import 'package:audio_call/screens/incoming_call_screen.dart';
import 'package:audio_call/screens/login_screen.dart';
import 'package:audio_call/screens/main_screen.dart';
import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:audio_call/utils/screen_arguments.dart';
import 'package:audio_call/services/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

void main() {
  setupLocator();
  runApp(MyApp());
}

void setupLocator() {
  getIt.registerLazySingleton(() => NavigationService());
}

class MyApp extends StatelessWidget {
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
                call: args.call,
              );
            },
          );
        } else if (settings.name == IncomingCallScreen.routeName) {
          final CallArguments args = settings.arguments;
          return MaterialPageRoute(
            builder: (context) {
              return IncomingCallScreen(
                call: args.call
              );
            },
          );
        } else if (settings.name == MainScreen.routeName) {
          return MaterialPageRoute(
            builder: (context) {
              return MainScreen();
            }
          );
        } else {
          return MaterialPageRoute(
            builder: (context) {
              return LoginScreen();
            }
          );
        }
      },
      initialRoute: LoginScreen.routeName,
    );
  }
}
