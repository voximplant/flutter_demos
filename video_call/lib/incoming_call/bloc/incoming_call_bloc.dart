/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call_service.dart';
import 'package:video_call/services/call_state.dart';

import 'incoming_call_event.dart';
import 'incoming_call_state.dart';

class IncomingCallBloc extends Bloc<IncomingCallEvent, IncomingCallState> {
  final AuthService authService;
  final CallService callService;

  String _callId;
  StreamSubscription _callStateSubscription;

  IncomingCallBloc({@required this.authService, this.callService});

  @override
  IncomingCallState get initialState => IncomingCallInitial();

  @override
  Stream<IncomingCallState> mapEventToState(IncomingCallEvent event) async* {
    if (event is Load) {
      _callId = callService.activeCallId;
      _callStateSubscription = callService
          .subscribeToCallStateChanges(_callId)
          .listen(onCallStateChanged);
    }
    if (event is CheckPermissions) {
      yield* _checkPermissions();
    }
    if (event is DeclineCall) {
      await callService.declineCall(_callId);
    }
    if (event is IncomingCallDisconnected) {
      yield CallHasEnded();
    }
  }

  @override
  Future<void> close() {
    if (_callStateSubscription != null) {
      _callStateSubscription.cancel();
    }
    return super.close();
  }

  Stream<IncomingCallState> _checkPermissions() async* {
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
        yield PermissionCheckPass();
      } else {
        Map<PermissionGroup, PermissionStatus> result =
            await PermissionHandler().requestPermissions(requestPermissions);
        if (result[PermissionGroup.microphone] != PermissionStatus.granted ||
            result[PermissionGroup.camera] != PermissionStatus.granted) {
          yield PermissionCheckFailed();
        } else {
          yield PermissionCheckPass();
        }
      }
    } else if (Platform.isIOS) {
      yield PermissionCheckPass();
    } else {
      //not supported platforms
      yield PermissionCheckFailed();
    }
  }

  void onCallStateChanged(CallState state) {
    if (state is CallStateDisconnected) {
      add(IncomingCallDisconnected());
    }
  }
}
