/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/screens/active_call/bloc/active_call_event.dart';
import 'package:video_call/screens/active_call/bloc/active_call_state.dart';
import 'package:video_call/services/call/call_event.dart';
import 'package:video_call/services/call/call_service.dart';
import 'package:video_call/services/call/callkit_service.dart';
import 'package:video_call/utils/log.dart';

class ActiveCallBloc extends Bloc<ActiveCallEvent, ActiveCallState> {
  final CallService _callService = CallService();
  final CallKitService? _callKitService =
      Platform.isIOS ? CallKitService() : null;

  StreamSubscription? _callStateSubscription;

  bool _isIncoming;
  String _endpoint;

  ActiveCallBloc(this._isIncoming, this._endpoint)
      : super(ActiveCallState(
          callStatus: 'Connecting',
          localVideoStreamID: null,
          remoteVideoStreamID: null,
          cameraType: VICameraType.Front,
          isOnHold: false,
          isMuted: false,
          endpointName: '',
        )) {
    on<ReadyToStartCallEvent>(_readyToStartCall);
    on<CallChangedEvent>(_handleCallChanged);
    on<HoldPressedEvent>(_holdCall);
    on<MutePressedEvent>(_muteAudio);
    on<HangupPressedEvent>(_hangupCall);
    on<SendVideoPressedEvent>(_sendVideo);
    on<SwitchCameraPressedEvent>(_switchCamera);
  }

  @override
  Future<void> close() {
    _callStateSubscription?.cancel();
    return super.close();
  }

  Future<void> _readyToStartCall(
      ReadyToStartCallEvent event, Emitter<ActiveCallState> emit) async {
    _callStateSubscription = _callService.subscribeToCallEvents().listen(
      (event) {
        add(CallChangedEvent(event: event));
      },
    );
    try {
      if (_isIncoming) {
        if (Platform.isAndroid) {
          if (_callService.hasActiveCall) {
            await _callService.answerCall();
          } else {
            _callService.onIncomingCall = (_) async {
              await _callService.answerCall();
            };
          }
        }
      } else /* if (direction == outgoing) */ {
        if (Platform.isAndroid) {
          await _callService.makeCall(callTo: _endpoint);
        } else if (Platform.isIOS) {
          await _callKitService?.startOutgoingCall(_endpoint);
        }
      }
      emit(state.copyWith(
        callStatus: _makeStringFromCallState(_callService.callState),
        endpointName: _callService.endpoint?.displayName ??
            _callService.endpoint?.userName ??
            _endpoint,
      ));
    } catch (e) {
      add(CallChangedEvent(event: OnFailedCallEvent(reason: e.toString())));
    }
  }

  Future<void> _handleCallChanged(
      CallChangedEvent event, Emitter<ActiveCallState> emit) async {
    CallEvent callEvent = event.event;

    if (callEvent is OnFailedCallEvent) {
      _log('onFailed event');
      await _callKitService?.reportCallEnded(
        reason: FCXCallEndedReason.failed,
      );
      emit(CallEndedActiveCallState(
          reason: callEvent.reason,
          failed: true,
          endpointName: state.endpointName,
          cameraType: state.cameraType));
    } else if (callEvent is OnDisconnectedCallEvent) {
      _log('onDisconnected event');
      await _callKitService?.reportCallEnded(
        reason: FCXCallEndedReason.remoteEnded,
      );
      emit(CallEndedActiveCallState(
          reason: 'Disconnected',
          failed: false,
          endpointName: state.endpointName,
          cameraType: state.cameraType));
    } else if (callEvent is OnHoldCallEvent) {
      _log('onHold event');
      bool isOnHold = callEvent.hold;
      String status = isOnHold ? 'Is on hold' : 'Connected';
      emit(state.copyWith(isOnHold: isOnHold, callStatus: status));
    } else if (callEvent is OnMuteCallEvent) {
      _log('onMute event');
      emit(state.copyWith(isMuted: callEvent.muted));
    } else if (callEvent is OnConnectedCallEvent) {
      _log('onConnected event');
      String name = callEvent.displayName;
      emit(state.copyWith(callStatus: 'Connected', endpointName: name));
      await _callKitService?.reportConnected(
        callEvent.username,
        callEvent.displayName,
      );
    } else if (callEvent is OnRingingCallEvent) {
      _log('onRinging event');
      emit(state.copyWith(callStatus: 'Ringing'));
    } else if (callEvent is OnChangedLocalVideoCallEvent) {
      _log('onChangedLocalVideo event');
      emit(state.copyWithLocalStream(callEvent.streamId));
    } else if (callEvent is OnChangedRemoteVideoCallEvent) {
      _log('onChangedRemoteVideo event');
      emit(state.copyWithRemoteStream(callEvent.streamId));
    }
  }

  Future<void> _holdCall(
      HoldPressedEvent event, Emitter<ActiveCallState> emit) async {
    Platform.isIOS
        ? await _callKitService?.holdCall(event.hold)
        : await _callService.holdCall(hold: event.hold);
  }

  Future<void> _muteAudio(
      MutePressedEvent event, Emitter<ActiveCallState> emit) async {
    Platform.isIOS
        ? await _callKitService?.muteCall(event.mute)
        : await _callService.muteCall(mute: event.mute);
  }

  Future<void> _hangupCall(
      HangupPressedEvent event, Emitter<ActiveCallState> emit) async {
    Platform.isIOS
        ? await _callKitService?.endCall()
        : await _callService.hangup();
  }

  Future<void> _sendVideo(
      SendVideoPressedEvent event, Emitter<ActiveCallState> emit) async {
    Platform.isIOS
        ? await _callKitService?.sendVideo(event.send)
        : await _callService.sendVideo(send: event.send);
  }

  Future<void> _switchCamera(
      SwitchCameraPressedEvent event, Emitter<ActiveCallState> emit) async {
    VICameraType cameraToSwitch = state.cameraType == VICameraType.Front
        ? VICameraType.Back
        : VICameraType.Front;
    await Voximplant().cameraManager.selectCamera(cameraToSwitch);
    emit(state.copyWith(cameraType: cameraToSwitch));
  }

  String _makeStringFromCallState(CallState state) {
    switch (state) {
      case CallState.connecting:
        return 'Connecting';
      case CallState.ringing:
        return 'Ringing';
      case CallState.connected:
        return 'Call is in progress';
      default:
        return '';
    }
  }

  void _log<T>(T message) {
    log('ActiveCallBloc($hashCode): ${message.toString()}');
  }
}
