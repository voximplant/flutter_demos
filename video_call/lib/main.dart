/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/active_call/active_call.dart';
import 'package:video_call/incoming_call/incoming_call.dart';
import 'package:video_call/login/login.dart';
import 'package:video_call/make_call/make_call.dart';
import 'package:video_call/routes.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call_service.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BlocSupervisor.delegate = SimpleBlocDelegate();

  VIClientConfig clientConfig = VIClientConfig();
  VIClient client = Voximplant().getClient(clientConfig);
  final AuthService authService = AuthService(client);
  final CallService callService = CallService(client);

  runApp(
    App(authService: authService, callService: callService),
  );
}

class App extends StatelessWidget {
  final AuthService authService;
  final CallService callService;

  App({Key key, @required this.authService, @required this.callService})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primaryColor: VoximplantColors.primary,
          primaryColorDark: VoximplantColors.primaryDark,
          accentColor: VoximplantColors.accent,
        ),
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (context) {
            return BlocProvider<LoginBloc>(
              create: (context) => LoginBloc(authService: authService),
              child: LoginPage(),
            );
          },
          AppRoutes.makeCall: (context) {
            return BlocProvider<MakeCallBloc>(
              create: (context) => MakeCallBloc(
                  authService: authService, callService: callService),
              child: MakeCallPage(),
            );
          },
          AppRoutes.activeCall: (context) {
            return BlocProvider<ActiveCallBloc>(
              create: (context) => ActiveCallBloc(
                  authService: authService, callService: callService),
              child: ActiveCallPage(),
            );
          },
          AppRoutes.incomingCall: (context) {
            return BlocProvider<IncomingCallBloc>(
              create: (context) => IncomingCallBloc(
                  authService: authService, callService: callService)
                ..add(Load()),
              child: IncomingCallPage(),
            );
          },
          AppRoutes.callFailed: (context) => CallFailedPage(),
        });
  }
}
