/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:video_call/services/call/call_event.dart';
import 'package:video_call/services/call/call_service.dart';
import 'package:video_call/services/permissions_helper.dart';
import 'incoming_call_event.dart';
import 'incoming_call_state.dart';

class IncomingCallBloc extends Bloc<IncomingCallEvent, IncomingCallState> {
  final CallService _callService = CallService();

  StreamSubscription _callStateSubscription;

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
        bool granted = await checkPermissions();
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

  void onCallEvent(CallEvent event) {
    if (event is OnDisconnectedCallEvent || event is OnFailedCallEvent) {
      add(IncomingCallEvent.callDisconnected);
    }
  }
}
