/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
///
import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/make_call/make_call.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call/call_event.dart';
import 'package:video_call/services/call/call_service.dart';
import 'package:video_call/services/call/callkit_service.dart';
import 'package:video_call/services/permissions_helper.dart';

class MakeCallBloc extends Bloc<MakeCallEvent, MakeCallState> {
  final AuthService _authService;
  final CallService _callService;
  final CallKitService _callKitService;

  StreamSubscription _callStateSubscription;

  MakeCallBloc()
      : _authService = AuthService(),
        _callService = CallService(),
        _callKitService = Platform.isIOS ? CallKitService() : null {
    _authService.onDisconnected = onConnectionClosed;
    _callStateSubscription =
        _callService.subscribeToCallEvents().listen(onCallEvent);
  }

  @override
  Future<void> close() {
    if (_callStateSubscription != null) {
      _callStateSubscription.cancel();
    }
    return super.close();
  }

  @override
  MakeCallState get initialState =>
      MakeCallInitial(myDisplayName: _authService.displayName);

  void onConnectionClosed() => add(ConnectionClosed());

  @override
  Stream<MakeCallState> mapEventToState(MakeCallEvent event) async* {
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
      yield IncomingCall(caller: event.displayName,
          myDisplayName: _authService.displayName);
    }
    if (event is ConnectionClosed) {
      yield LoggedOut(networkIssues: true);
    }
    if (event is Reconnect) {
      try {
        String displayName = await _authService.loginWithAccessToken();
        if (displayName == null) { return; }
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
          reason: FCXCallEndedReason.remoteEnded);
    } else if (event is OnIncomingCallEvent) {
      Platform.isIOS
          ? await _callKitService.createIncomingCall(_callService.callKitUUID,
              event.username, event.displayName, event.video)
          : add(ReceivedIncomingCall(
              displayName: event.displayName ?? event.username));
    }
  }
}
