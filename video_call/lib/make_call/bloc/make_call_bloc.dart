/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
///
import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_call/make_call/make_call.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call/call_event.dart';
import 'package:video_call/services/call/call_service.dart';
import 'package:video_call/services/call/callkit_service.dart';

class MakeCallBloc extends Bloc<MakeCallEvent, MakeCallState> {
  final AuthService _authService;
  final CallService _callService;
  final CallKitService _callKitService;

  StreamSubscription _callStateSubscription;

  MakeCallBloc()
      : _authService = AuthService(),
        _callService = CallService(),
        _callKitService = Platform.isIOS ? CallKitService() : null {
    _callService.onIncomingCall = onIncomingCall;
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
      MakeCallInitial(displayName: _authService.displayName);

  Future<void> onIncomingCall(String callId, String caller, String displayName,
      bool withVideo) async =>
      Platform.isIOS
          ? await _callKitService.createIncomingCall(
          _callService.callKitUUID, caller, displayName, withVideo)
          : add(ReceivedIncomingCall(callId: callId, caller: caller));

  void onConnectionClosed() => add(ConnectionClosed());

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
        yield PermissionCheckSuccess(displayName: _authService.displayName);
      } else {
        Map<PermissionGroup, PermissionStatus> result =
        await PermissionHandler().requestPermissions(requestPermissions);
        if (result[PermissionGroup.microphone] != PermissionStatus.granted ||
            result[PermissionGroup.camera] != PermissionStatus.granted) {
          yield PermissionCheckFail(displayName: _authService.displayName);
        } else {
          yield PermissionCheckSuccess(displayName: _authService.displayName);
        }
      }
    } else if (Platform.isIOS) {
      yield PermissionCheckSuccess(displayName: _authService.displayName);
    } else {
      //not supported platforms
      yield PermissionCheckFail(displayName: _authService.displayName);
    }
  }

  @override
  Stream<MakeCallState> mapEventToState(MakeCallEvent event) async* {
    if (event is CheckPermissionsForCall) {
      yield* _checkPermissions();
    }
    if (event is LogOut) {
      await _authService.logout();
      yield LoggedOut(networkIssues: false);
    }
    if (event is ReceivedIncomingCall) {
      yield IncomingCall(
          caller: event.caller, displayName: _authService.displayName);
    }
    if (event is ConnectionClosed) {
      yield LoggedOut(networkIssues: true);
    }
    if (event is Reconnect) {
      try {
        String displayName = await _authService.loginWithAccessToken();
        if (displayName == null) { return; }
        yield ReconnectSuccess(displayName: displayName);
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
    }
  }
}
