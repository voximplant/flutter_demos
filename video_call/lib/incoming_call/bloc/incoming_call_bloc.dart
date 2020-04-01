/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_call/services/call/call_event.dart';
import 'package:video_call/services/call/call_service.dart';
import 'incoming_call_event.dart';
import 'incoming_call_state.dart';

class IncomingCallBloc extends Bloc<IncomingCallEvent, IncomingCallState> {
  final CallService _callService;

  StreamSubscription _callStateSubscription;

  IncomingCallBloc() : _callService = CallService();

  @override
  IncomingCallState get initialState => IncomingCallState.callIncoming;

  @override
  Stream<IncomingCallState> mapEventToState(IncomingCallEvent event) async* {
    switch (event) {
      case IncomingCallEvent.readyToSubscribe:
        _callStateSubscription = _callService
            .subscribeToCallEvents()
            .listen(onCallEvent);
        break;
      case IncomingCallEvent.checkPermissions:
        bool granted = await _checkPermissions();
        if (granted) { yield IncomingCallState.permissionsGranted; }
        break;
      case IncomingCallEvent.declineCall:
        await _callService.decline();
        yield IncomingCallState.callCancelled;
        break;
      case IncomingCallEvent.callDisconnected:
        yield IncomingCallState.callCancelled;
        break;
    }
  }

  @override
  Future<void> close() {
    if (_callStateSubscription != null) {
      _callStateSubscription.cancel();
    }
    return super.close();
  }

  Future<bool> _checkPermissions() async {
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
        return true;
      } else {
        Map<PermissionGroup, PermissionStatus> result =
            await PermissionHandler().requestPermissions(requestPermissions);
        if (result[PermissionGroup.microphone] != PermissionStatus.granted ||
            result[PermissionGroup.camera] != PermissionStatus.granted) {
          return false;
        } else {
          return true;
        }
      }
    } else if (Platform.isIOS) {
      return true;
    } else {
      //not supported platforms
      return false;
    }
  }

  void onCallEvent(CallEvent event) {
    if (event is OnDisconnectedCallEvent || event is OnFailedCallEvent) {
      add(IncomingCallEvent.callDisconnected);
    }
  }
}
