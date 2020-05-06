/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/active_call/active_call.dart';
import 'package:video_call/call_failed/call_failed.dart';
import 'package:video_call/incoming_call/incoming_call.dart';
import 'package:video_call/login/login.dart';
import 'package:video_call/make_call/make_call.dart';
import 'package:video_call/services/navigation_helper.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call/call_service.dart';
import 'package:video_call/services/call/callkit_service.dart';
import 'package:video_call/services/notification_service.dart';
import 'package:video_call/services/push/push_service_ios.dart';
import 'package:video_call/services/push/push_service_android.dart';
import 'package:video_call/theme/voximplant_theme.dart';
import 'call_failed/call_failed_page.dart';

class SimpleBlocDelegate extends BlocDelegate {
  @override
  void onEvent(Bloc bloc, Object event) {
    super.onEvent(bloc, event);
    print(event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print(transition);
  }

  @override
  void onError(Bloc bloc, Object error, StackTrace stacktrace) {
    super.onError(bloc, error, stacktrace);
    print(error);
  }
}

VIClientConfig get defaultConfig => VIClientConfig();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BlocSupervisor.delegate = SimpleBlocDelegate();

  AuthService();
  CallService();
  Platform.isIOS ? PushServiceIOS() : PushServiceAndroid();
  /// callKit for ios
  if (Platform.isIOS) {
    CallKitService();
  }
  /// local notifications for android
  if (Platform.isAndroid) {
    NotificationService();
  }

  runApp(App());
}

class App extends StatelessWidget {
  App({Key key}) : super(key: key);

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
                create: (context) => LoginBloc()..add(LoadLastUser()),
                child: LoginPage(),
              ),
            );

          } else if (routeSettings.name == AppRoutes.makeCall) {
            return PageRouteBuilder(
              pageBuilder: (_, a1, a2) => BlocProvider<MakeCallBloc>(
                create: (context) => MakeCallBloc(),
                child: MakeCallPage(),
              ),
            );

          } else if (routeSettings.name == AppRoutes.activeCall) {
            ActiveCallPageArguments arguments = routeSettings.arguments;
            return PageRouteBuilder(
              pageBuilder: (_, a1, a2) => BlocProvider<ActiveCallBloc>(
                create: (context) => ActiveCallBloc()
                  ..add(ReadyToInteractCallEvent(
                      isIncoming: arguments.isIncoming,
                      endpoint: arguments.endpoint)),
                child: ActiveCallPage(),
              ),
            );

          } else if (routeSettings.name == AppRoutes.incomingCall) {
            return PageRouteBuilder(
              pageBuilder: (context, a1, a2) => BlocProvider<IncomingCallBloc>(
                create: (context) =>
                    IncomingCallBloc()..add(IncomingCallEvent.readyToSubscribe),
                child: IncomingCallPage(arguments:
                    routeSettings.arguments as IncomingCallPageArguments),
              ),
            );

          } else if (routeSettings.name == AppRoutes.callFailed) {
            return MaterialPageRoute(
              builder: (context) => CallFailedPage(
                  routeSettings.arguments as CallFailedPageArguments),
            );
          }
          return null;
        });
  }
}
