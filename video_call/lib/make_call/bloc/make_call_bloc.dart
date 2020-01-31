/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_call/make_call/make_call.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call_service.dart';

class MakeCallBloc extends Bloc<MakeCallEvent, MakeCallState> {
  final AuthService authService;
  final CallService callService;

  MakeCallBloc({@required this.authService, @required this.callService}) {
    callService.onIncomingCall = onIncomingCall;
    authService.onDisconnected = onConnectionClosed;
  }

  @override
  MakeCallState get initialState =>
      MakeCallInitial(displayName: authService.displayName);

  void onIncomingCall(String callId, String caller) {
    add(ReceivedIncomingCall(callId: callId, caller: caller));
  }

  void onConnectionClosed() {
    add(ConnectionClosed());
  }

  Stream<MakeCallState> _checkPermissions() async* {
    if (Platform.isAndroid) {
      PermissionStatus recordAudio = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.microphone);
      PermissionStatus camera = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.camera);
      List<PermissionGroup> requestPermissions = List();
      if (recordAudio != PermissionStatus.granted) {
        requestPermissions.add(PermissionGroup.microphone);
      }
      if (camera != PermissionStatus.granted) {
        requestPermissions.add(PermissionGroup.camera);
      }
      if (requestPermissions.isEmpty) {
        yield PermissionCheckSuccess(displayName: authService.displayName);
      } else {
        Map<PermissionGroup, PermissionStatus> result =
        await PermissionHandler().requestPermissions(requestPermissions);
        if (result[PermissionGroup.microphone] != PermissionStatus.granted ||
            result[PermissionGroup.camera] != PermissionStatus.granted) {
          yield PermissionCheckFail(displayName: authService.displayName);
        } else {
          yield PermissionCheckSuccess(displayName: authService.displayName);
        }
      }
    } else if (Platform.isIOS) {
      yield PermissionCheckSuccess(displayName: authService.displayName);
    } else {
      //not supported platforms
      yield PermissionCheckFail(displayName: authService.displayName);
    }
  }

  @override
  Stream<MakeCallState> mapEventToState(MakeCallEvent event) async* {
    if (event is CheckPermissionsForCall) {
      yield* _checkPermissions();
    }
    if (event is LogOut) {
      await authService.logout();
      yield LoggedOut(networkIssues: false);
    }
    if (event is ReceivedIncomingCall) {
      yield IncomingCall(caller: event.caller);
    }
    if (event is ConnectionClosed) {
      yield LoggedOut(networkIssues: true);
    }
    if (event is Reconnect) {
      try {
        await authService.loginWithAccessToken();
        yield ReconnectSuccess(displayName: authService.displayName);
      } on VIException {
        authService.onDisconnected = null;
        yield ReconnectFailed();
      }
    }
  }
}
