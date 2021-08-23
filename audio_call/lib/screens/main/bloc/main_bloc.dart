/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:async';
import 'dart:io';

import 'package:audio_call/screens/main/main.dart';
import 'package:audio_call/services/auth_service.dart';
import 'package:audio_call/services/call/call_event.dart';
import 'package:audio_call/services/call/call_service.dart';
import 'package:audio_call/services/call/callkit_service.dart';
import 'package:audio_call/utils/permissions_helper.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  final AuthService _authService = AuthService();
  final CallService _callService = CallService();
  final CallKitService? _callKitService =
      Platform.isIOS ? CallKitService() : null;

  StreamSubscription? _callStateSubscription;

  MainBloc() : super(MainInitial(myDisplayName: AuthService().displayName)) {
    _authService.onDisconnected = () => add(ConnectionClosed());
    _callStateSubscription =
        _callService.subscribeToCallEvents().listen(onCallEvent);
  }

  @override
  Future<void> close() {
    _callStateSubscription?.cancel();
    return super.close();
  }

  @override
  Stream<MainState> mapEventToState(MainEvent event) async* {
    if (event is CheckPermissionsForCall) {
      yield await checkPermissions()
          ? PermissionCheckSuccess(myDisplayName: _authService.displayName)
          : PermissionCheckFail(myDisplayName: _authService.displayName);
    }
    if (event is LogOut) {
      await _authService.logout();
      yield LoggedOut(networkIssues: false);
    }
    if (event is ReceivedIncomingCall) {
      yield IncomingCall(
        caller: event.displayName,
        myDisplayName: _authService.displayName,
      );
    }
    if (event is ConnectionClosed) {
      yield LoggedOut(networkIssues: true);
    }
    if (event is Reconnect) {
      try {
        String? displayName = await _authService.loginWithAccessToken();
        if (displayName == null) {
          return;
        }
        yield ReconnectSuccess(myDisplayName: displayName);
      } on VIException {
        _authService.onDisconnected = null;
        yield ReconnectFailed();
      }
    }
  }

  Future<void> onCallEvent(CallEvent event) async {
    if (event is OnDisconnectedCallEvent) {
      await _callKitService?.reportCallEnded(
        reason: FCXCallEndedReason.remoteEnded,
      );
    } else if (event is OnIncomingCallEvent) {
      if (Platform.isIOS) {
        await _callKitService?.createIncomingCall(
          _callService.callKitUUID,
          event.username,
          event.displayName,
        );
      } else if (Platform.isAndroid) {
        add(
          ReceivedIncomingCall(
            displayName: event.displayName ?? event.username ?? 'Unknown',
          ),
        );
      }
    }
  }
}
