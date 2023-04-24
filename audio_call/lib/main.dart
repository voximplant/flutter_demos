/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:io';

import 'package:audio_call/screens/active_call/active_call.dart';
import 'package:audio_call/screens/call_failed/call_failed.dart';
import 'package:audio_call/screens/incoming_call/incoming_call.dart';
import 'package:audio_call/screens/login/login.dart';
import 'package:audio_call/screens/main/main.dart';
import 'package:audio_call/services/auth_service.dart';
import 'package:audio_call/services/call/call_service.dart';
import 'package:audio_call/services/call/callkit_service.dart';
import 'package:audio_call/services/push/push_service_android.dart';
import 'package:audio_call/services/push/push_service_ios.dart';
import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:audio_call/utils/log.dart';
import 'package:audio_call/utils/navigation_helper.dart';
import 'package:audio_call/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

class SimpleBlocDelegate extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    log(event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    log(transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    log(error);
  }
}

VIClientConfig get defaultConfig => VIClientConfig(bundleId: 'com.voximplant.flutter.audioCall');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = SimpleBlocDelegate();

  AuthService();
  CallService();
  if (Platform.isIOS) {
    PushServiceIOS();
    CallKitService();
  } else if (Platform.isAndroid) {
    PushServiceAndroid();
    NotificationHelper();
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: VoximplantColors.primary,
        primaryColorDark: VoximplantColors.primaryDark,
        accentColor: VoximplantColors.accent,
      ),
      navigatorKey: NavigationHelper.navigatorKey,
      initialRoute: AppRoutes.login,
      onGenerateRoute: (routeSettings) {
        if (routeSettings.name == AppRoutes.login) {
          return PageRouteBuilder(
            pageBuilder: (_, a1, a2) => BlocProvider<LoginBloc>(
              create: (_) => LoginBloc(),
              child: LoginPage(),
            ),
          );
        } else if (routeSettings.name == AppRoutes.main) {
          return PageRouteBuilder(
            pageBuilder: (_, a1, a2) => BlocProvider<MainBloc>(
              create: (_) => MainBloc(),
              child: MainPage(),
            ),
          );
        } else if (routeSettings.name == AppRoutes.activeCall) {
          final routingArguments = routeSettings.arguments as ActiveCallPageArguments;
          ActiveCallPageArguments arguments = routingArguments;
          return PageRouteBuilder(
            pageBuilder: (_, a1, a2) =>
                BlocProvider<ActiveCallBloc>(
                  create: (_) =>
                      ActiveCallBloc(
                          arguments.isIncoming, arguments.endpoint),
                  child: ActiveCallPage(),
                ),
          );
        } else if (routeSettings.name == AppRoutes.incomingCall) {
          return PageRouteBuilder(
            pageBuilder: (_, a1, a2) => BlocProvider<IncomingCallBloc>(
              create: (_) => IncomingCallBloc(),
              child: IncomingCallPage(
                arguments: routeSettings.arguments as IncomingCallPageArguments,
              ),
            ),
          );
        } else if (routeSettings.name == AppRoutes.callFailed) {
          return MaterialPageRoute(
            builder: (_) => CallFailedPage(
              routeSettings.arguments as CallFailedPageArguments,
            ),
          );
        }
        return null;
      },
    );
  }
}
