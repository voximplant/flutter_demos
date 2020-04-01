/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/active_call/bloc/active_call_event.dart';
import 'package:video_call/active_call/bloc/active_call_state.dart';
import 'package:video_call/services/call/call_event.dart';
import 'package:video_call/services/call/call_service.dart';
import 'package:video_call/services/call/callkit_service.dart';

class ActiveCallBloc extends Bloc<ActiveCallEvent, ActiveCallState> {
  final CallService _callService;
  final CallKitService _callKitService;

  StreamSubscription _callStateSubscription;

  VICameraType _cameraType;
  String _latestDescription = '';
  String _latestLocalStreamId;
  String _latestRemoteStreamId;
  bool _latestOnHold = false;
  bool _latestIsMuted = false;
  String _displayName;

  ActiveCallBloc()
      : _callService = CallService(),
        _callKitService = Platform.isIOS ? CallKitService() : null,
        _cameraType = VICameraType.Front;

  @override
  ActiveCallState get initialState => ActiveCallState(
      description: 'Connecting',
      localVideoStreamID: _callService.localVideoStreamID,
      remoteVideoStreamID: _callService.remoteVideoStreamID,
      isOnHold: false,
      isMuted: false);

  @override
  void onTransition(Transition<ActiveCallEvent, ActiveCallState> transition) {
    super.onTransition(transition);
    _latestDescription = transition.nextState.description;
    _latestLocalStreamId = transition.nextState.localVideoStreamID;
    _latestRemoteStreamId = transition.nextState.remoteVideoStreamID;
    _latestIsMuted = transition.nextState.isMuted;
    _latestOnHold = transition.nextState.isOnHold;
  }

  @override
  Stream<ActiveCallState> mapEventToState(ActiveCallEvent event) async* {
    if (event is StartOutgoingCallEvent) {
      try {
        Platform.isIOS
            ? await _callKitService.startOutgoingCall(event.username)
            : await _callService.makeVideoCall(callTo: event.username);
        _displayName = event.username;
        _callStateSubscription = _callService
            .subscribeToCallEvents()
            .listen(onCallEvent);
      } catch (e) {
        yield CallEndedActiveCallState(
            reason: e,
            failed: true,
            displayName: event.username);
        _displayName = null;
      }

    } else if (event is AnswerCallEvent) {
      try {
        _displayName = event.username ?? '';
        if (Platform.isIOS) {
          _callStateSubscription = _callService
              .subscribeToCallEvents()
              .listen(onCallEvent);
          _latestDescription = 'Connecting';
          _latestLocalStreamId = _callService.localVideoStreamID;
          _latestRemoteStreamId = _callService.remoteVideoStreamID;
          yield _makeState();
        } else if (Platform.isAndroid) {
          if (_callService.hasActiveCall) {
            await _callService.answerVideoCall();
            _callStateSubscription = _callService
                .subscribeToCallEvents()
                .listen(onCallEvent);
          } else {
            _callService.answerOnceReady = () async {
              await _callService.answerVideoCall();
              _callStateSubscription = _callService
                  .subscribeToCallEvents()
                  .listen(onCallEvent);
            };
          }
        }
      } catch (e) {
        yield CallEndedActiveCallState(
            reason: e,
            failed: true,
            displayName: _displayName);
        _displayName = null;
      }

    } else if (event is CallChangedEvent) {

      if (event.callEvent is OnFailedCallEvent) {
        await _callKitService?.reportCallEnded(
            reason: FCXCallEndedReason.failed);
        yield CallEndedActiveCallState(
            reason: (event.callEvent as OnFailedCallEvent).reason,
            displayName: _displayName,
            failed: true
        );
        _displayName = null;

      } else if (event.callEvent is OnDisconnectedCallEvent) {
        if (Platform.isIOS) {
          if (_callKitService.hasActiveCall) {
            await _callKitService?.reportCallEnded(
                reason: FCXCallEndedReason.remoteEnded);
          }
        }
        yield CallEndedActiveCallState(
          reason: 'Disconnected',
          failed: false,
          displayName: _displayName,
        );
        _displayName = null;

      } else if (event.callEvent is OnChangedLocalVideoCallEvent) {
        _latestLocalStreamId =
            (event.callEvent as OnChangedLocalVideoCallEvent).id;
        yield _makeState();

      } else if (event.callEvent is OnChangedRemoteVideoCallEvent) {
        _latestRemoteStreamId =
            (event.callEvent as OnChangedRemoteVideoCallEvent).id;
        yield _makeState();

      } else if (event.callEvent is OnHoldCallEvent) {
        _latestOnHold = (event.callEvent as OnHoldCallEvent).isOnHold;
        _latestDescription = _latestOnHold ? 'Is on hold' : 'Connected';
        yield _makeState();

      } else if (event.callEvent is OnMuteCallEvent) {
        _latestIsMuted = (event.callEvent as OnMuteCallEvent).isMuted;
        yield _makeState();

      } else if (event.callEvent is OnConnectedCallEvent) {
        _latestDescription = 'Connected';
        _displayName = (event.callEvent as OnConnectedCallEvent).displayName;
        yield _makeState();
        await _callKitService?.reportConnected(
            (event.callEvent as OnConnectedCallEvent).username,
            (event.callEvent as OnConnectedCallEvent).displayName,
            _latestLocalStreamId != null || _latestRemoteStreamId != null);

      } else if (event.callEvent is OnRingingCallEvent) {
        _latestDescription = 'Ringing';
        yield _makeState();
      }

    } else if (event is SendVideoPressedEvent) {
      Platform.isIOS
          ? await _callKitService.sendVideo(event.send)
          : await _callService.sendVideo(send: event.send);

    } else if (event is SwitchCameraPressedEvent) {
      VICameraType cameraToSwitch = _cameraType == VICameraType.Front
          ? VICameraType.Back
          : VICameraType.Front;
      await Voximplant().getCameraManager().selectCamera(cameraToSwitch);
      _cameraType = cameraToSwitch;

    } else if (event is HoldPressedEvent) {
      Platform.isIOS
          ? await _callKitService.holdCall(event.hold)
          : await _callService.holdCall(hold:event.hold);

    } else if (event is MutePressedEvent) {
      Platform.isIOS
          ? await _callKitService.muteCall(event.mute)
          : await _callService.muteCall(mute: event.mute);

    } else if (event is HangupPressedEvent) {
      Platform.isIOS
          ? await _callKitService.endCall()
          : await _callService.hangup();
    }
  }

  @override
  Future<void> close() {
    if (_callStateSubscription != null) {
      _callStateSubscription.cancel();
    }
    return super.close();
  }

  Future<void> onCallEvent(CallEvent event) async =>
      add(CallChangedEvent(callEvent: event));

  ActiveCallState _makeState() => ActiveCallState(
      description: _latestDescription,
      localVideoStreamID: _latestLocalStreamId,
      remoteVideoStreamID: _latestRemoteStreamId,
      isOnHold: _latestOnHold,
      isMuted: _latestIsMuted);
}
