/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/active_call/bloc/active_call_event.dart';
import 'package:video_call/active_call/bloc/active_call_state.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/services/call_service.dart';
import 'package:video_call/services/call_state.dart';

class ActiveCallBloc extends Bloc<ActiveCallEvent, ActiveCallState> {
  final AuthService authService;
  final CallService callService;
  String _callId;
  VICameraType _cameraType = VICameraType.Front;

  StreamSubscription _callStateSubscription;

  ActiveCallBloc({@required this.authService, this.callService});

  @override
  ActiveCallState get initialState => ActiveCallConnecting();

  @override
  Stream<ActiveCallState> mapEventToState(ActiveCallEvent event) async* {
    if (event is StartOutgoingCall) {
      try {
        _callId = await callService.makeVideoCall(callTo: event.callTo);
        _callStateSubscription = callService
            .subscribeToCallStateChanges(_callId)
            .listen(onCallStateChanged);
      } catch (e) {
         yield ActiveCallFailed(errorDescription: e, endpoint: event.callTo);
      }
    }
    if (event is AnswerIncomingCall) {
      try {
        _callId = await callService.answerVideoCall();
        _callStateSubscription = callService
            .subscribeToCallStateChanges(_callId)
            .listen(onCallStateChanged);
      } catch (e) {
        yield ActiveCallFailed(errorDescription: e, endpoint: null);
      }
    }
    if (event is EndCall) {
      await callService.endCall(_callId);
    }
    if (event is HoldCall) {
      try {
        await callService.holdCall(_callId, event.doHold);
        yield ActiveCallHold(isHeld: event.doHold, errorDescription: null);
      } on VIException catch (e) {
        yield ActiveCallHold(
            isHeld: !event.doHold, errorDescription: e.message);
      }
    }
    if (event is SendVideo) {
      try {
        await callService.sendVideo(_callId, event.doSend);
        yield ActiveCallSendVideo(
            isSendingVideo: event.doSend, errorDescription: null);
      } on VIException catch (e) {
        yield ActiveCallSendVideo(
            isSendingVideo: !event.doSend, errorDescription: e.message);
      }
    }
    if (event is SwitchCamera) {
      VICameraType cameraToSwitch = _cameraType == VICameraType.Front ?
          VICameraType.Back :  VICameraType.Front;
      await Voximplant().getCameraManager().selectCamera(cameraToSwitch);
      _cameraType = cameraToSwitch;
    }
    if (event is UpdateCallState) {
      CallState callState = event.callState;
      if (callState is CallStateRinging) {
        yield ActiveCallRinging();
      }
      if (callState is CallStateConnected) {
        yield ActiveCallConnected();
      }
      if (callState is CallStateDisconnected) {
        yield ActiveCallDisconnected();
      }
      if (callState is CallStateFailed) {
        yield ActiveCallFailed(
            errorDescription: callState.errorDescription,
            endpoint: callState.endpoint);
      }
      if (callState is CallStateVideoStreamAdded) {
        yield ActiveCallVideoStreamAdded(
            streamId: callState.streamId, isLocal: callState.isLocal);
      }
      if (callState is CallStateVideoStreamRemoved) {
        yield ActiveCallVideoStreamRemoved(
            streamId: callState.streamId, isLocal: callState.isLocal);
      }
    }
  }

  @override
  Future<void> close() {
    if (_callStateSubscription != null) {
      _callStateSubscription.cancel();
    }
    return super.close();
  }

  void onCallStateChanged(CallState state) {
    add(UpdateCallState(callState: state));
  }
}
