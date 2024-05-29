/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/screens/main/main.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call/call_event.dart';
import 'package:video_call/services/call/call_service.dart';
import 'package:video_call/services/call/callkit_service.dart';
import 'package:video_call/utils/permissions_helper.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  final AuthService _authService = AuthService();
  final CallService _callService = CallService();
  final CallKitService? _callKitService =
      Platform.isIOS ? CallKitService() : null;

  bool _logoutRequested = false;
  late StreamSubscription _callStateSubscription;

  MainBloc()
      : super(MainInitial(
            myDisplayName: AuthService().displayName ?? 'Unknown user')) {
    _authService.onDisconnected = () => add(ConnectionClosed());
    _callStateSubscription =
        _callService.subscribeToCallEvents().listen(onCallEvent);
    on<CheckPermissionsForCall>(_checkPermissions);
    on<LogOut>(_logout);
    on<ConnectionClosed>(_connectionClosed);
    on<Reconnect>(_reconnect);
    on<ReceivedIncomingCall>(_receivedIncomingCall);
  }

  @override
  Future<void> close() {
    _callStateSubscription.cancel();
    return super.close();
  }

  Future<void> _checkPermissions(
      CheckPermissionsForCall event, Emitter<MainState> emit) async {
    bool permissionsGranted = await checkPermissions();
    if (permissionsGranted) {
      emit(PermissionCheckSuccess(
          myDisplayName: _authService.displayName ?? 'Unknown user'));
    } else {
      emit(PermissionCheckFail(
          myDisplayName: _authService.displayName ?? 'Unknown user'));
    }
  }

  Future<void> _logout(LogOut event, Emitter<MainState> emit) async {
    _logoutRequested = true;
    await _authService.logout();
    emit(const LoggedOut(networkIssues: false));
  }

  Future<void> _connectionClosed(
      ConnectionClosed event, Emitter<MainState> emit) async {
    if (!_logoutRequested) {
      emit(const LoggedOut(networkIssues: true));
    }
  }

  void _receivedIncomingCall(
      ReceivedIncomingCall event, Emitter<MainState> emit) {
    emit(IncomingCall(
      caller: event.displayName,
      myDisplayName: _authService.displayName ?? 'Unknown user',
    ));
  }

  Future<void> _reconnect(Reconnect event, Emitter<MainState> emit) async {
    try {
      final displayName = await _authService.loginWithAccessToken();
      if (displayName == null) {
        return;
      }
      emit(ReconnectSuccess(myDisplayName: displayName));
    } on VIException {
      _authService.onDisconnected = null;
      emit(const ReconnectFailed());
    }
  }

  Future<void> onCallEvent(CallEvent event) async {
    if (event is OnDisconnectedCallEvent) {
      await _callKitService?.reportCallEnded(
        reason: FCXCallEndedReason.remoteEnded,
      );
    } else if (event is OnIncomingCallEvent) {
      if (Platform.isIOS) {
        final callKitUUID = _callService.callKitUUID;
        if (callKitUUID != null) {
          await _callKitService?.createIncomingCall(
            callKitUUID,
            event.username,
            event.displayName,
          );
        }
      } else if (Platform.isAndroid) {
        add(
          ReceivedIncomingCall(
            displayName: event.displayName,
          ),
        );
      }
    }
  }
}
