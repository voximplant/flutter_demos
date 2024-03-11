/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/screens/active_call/active_call.dart';
import 'package:video_call/screens/call_failed/call_failed.dart';
import 'package:video_call/screens/incoming_call/incoming_call.dart';
import 'package:video_call/screens/login/login.dart';
import 'package:video_call/screens/main/main.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call/call_service.dart';
import 'package:video_call/services/call/callkit_service.dart';
import 'package:video_call/services/push/push_service_android.dart';
import 'package:video_call/services/push/push_service_ios.dart';
import 'package:video_call/theme/voximplant_theme.dart';
import 'package:video_call/utils/log.dart';
import 'package:video_call/utils/navigation_helper.dart';
import 'package:video_call/utils/notification_helper.dart';

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

VIClientConfig get defaultConfig => VIClientConfig();

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

  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData();
    return MaterialApp(
      theme: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: VoximplantColors.primary,
          secondary: VoximplantColors.accent,
        ),
      ),
      navigatorKey: NavigationHelper.navigatorKey,
      initialRoute: AppRoutes.login,
      onGenerateRoute: (routeSettings) {
        if (routeSettings.name == AppRoutes.login) {
          return PageRouteBuilder(
            pageBuilder: (_, a1, a2) => BlocProvider<LoginBloc>(
              create: (context) => LoginBloc(),
              child: LoginPage(),
            ),
          );
        } else if (routeSettings.name == AppRoutes.main) {
          return PageRouteBuilder(
            pageBuilder: (_, a1, a2) => BlocProvider<MainBloc>(
              create: (context) => MainBloc(),
              child: MainPage(),
            ),
          );
        } else if (routeSettings.name == AppRoutes.activeCall) {
          final routingArguments =
              routeSettings.arguments as ActiveCallPageArguments;
          ActiveCallPageArguments arguments = routingArguments;
          return PageRouteBuilder(
            pageBuilder: (_, a1, a2) => BlocProvider<ActiveCallBloc>(
              create: (context) =>
                  ActiveCallBloc(arguments.isIncoming, arguments.endpoint),
              child: ActiveCallPage(),
            ),
          );
        } else if (routeSettings.name == AppRoutes.incomingCall) {
          return PageRouteBuilder(
            pageBuilder: (context, a1, a2) => BlocProvider<IncomingCallBloc>(
              create: (context) => IncomingCallBloc(),
              child: IncomingCallPage(
                arguments: routeSettings.arguments as IncomingCallPageArguments,
              ),
            ),
          );
        } else if (routeSettings.name == AppRoutes.callFailed) {
          return MaterialPageRoute(
            builder: (context) => CallFailedPage(
              routeSettings.arguments as CallFailedPageArguments,
            ),
          );
        }
        return null;
      },
    );
  }
}
