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
  final CallKitService _callKitService =
      Platform.isIOS ? CallKitService() : null;

  StreamSubscription _callStateSubscription;

  ActiveCallBloc(bool isIncoming, String endpoint)
      : super(ActiveCallState(
          callStatus: 'Connecting',
          localVideoStreamID: null,
          remoteVideoStreamID: null,
          cameraType: VICameraType.Front,
          isOnHold: false,
          isMuted: false,
          endpointName: '',
        )) {
    add(ReadyToStartCallEvent(isIncoming: isIncoming, endpoint: endpoint));
  }

  @override
  Future<void> close() {
    if (_callStateSubscription != null) {
      _callStateSubscription.cancel();
    }
    return super.close();
  }

  @override
  Stream<ActiveCallState> mapEventToState(ActiveCallEvent event) async* {
    if (event is ReadyToStartCallEvent) {
      _callStateSubscription = _callService.subscribeToCallEvents().listen(
        (event) {
          add(CallChangedEvent(event: event));
        },
      );

      try {
        if (event.isIncoming) {
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
            await _callService.makeCall(callTo: event.endpoint);
          } else if (Platform.isIOS) {
            await _callKitService.startOutgoingCall(event.endpoint);
          }
        }
        yield state.copyWith(
          callStatus: _makeStringFromCallState(_callService.callState),
          endpointName: _callService?.endpoint?.displayName ??
              _callService?.endpoint?.userName ??
              event.endpoint ??
              '',
          localVideoStreamID: _callService.localVideoStreamId,
          remoteVideoStreamID: _callService.remoteVideoStreamId,
        );
      } catch (e) {
        add(CallChangedEvent(event: OnFailedCallEvent(reason: e.toString())));
      }
    } else if (event is CallChangedEvent) {
      CallEvent callEvent = event.event;

      if (callEvent is OnFailedCallEvent) {
        _log('onFailed event');
        await _callKitService?.reportCallEnded(
          reason: FCXCallEndedReason.failed,
        );
        yield CallEndedActiveCallState(
          reason: callEvent.reason,
          endpointName: state.endpointName,
          cameraType: state.cameraType,
          failed: true,
        );
      } else if (callEvent is OnDisconnectedCallEvent) {
        _log('onDisconnected event');
        if (Platform.isIOS) {
          await _callKitService?.reportCallEnded(
            reason: FCXCallEndedReason.remoteEnded,
          );
        }
        yield CallEndedActiveCallState(
          reason: 'Disconnected',
          failed: false,
          endpointName: state.endpointName,
          cameraType: state.cameraType,
        );
      } else if (callEvent is OnChangedLocalVideoCallEvent) {
        _log('onChangedLocalVideo event');
        yield state.copyWithLocalStream(callEvent.streamId);
      } else if (callEvent is OnChangedRemoteVideoCallEvent) {
        _log('onChangedRemoteVideo event');
        yield state.copyWithRemoteStream(callEvent.streamId);
      } else if (callEvent is OnHoldCallEvent) {
        _log('onHold event');
        bool isOnHold = callEvent.hold;
        String status = isOnHold ? 'Is on hold' : 'Connected';
        yield state.copyWith(isOnHold: isOnHold, callStatus: status);
      } else if (callEvent is OnMuteCallEvent) {
        _log('onMute event');
        yield state.copyWith(isMuted: callEvent.muted);
      } else if (callEvent is OnConnectedCallEvent) {
        _log('onConnected event');
        String name = callEvent.displayName ?? callEvent.username ?? '';
        yield state.copyWith(callStatus: 'Connected', endpointName: name);
        await _callKitService?.reportConnected(
            callEvent.username,
            callEvent.displayName,
            state.localVideoStreamID != null ||
                state.remoteVideoStreamID != null);
      } else if (callEvent is OnRingingCallEvent) {
        _log('onRinging event');
        yield state.copyWith(callStatus: 'Ringing');
      }
    } else if (event is SendVideoPressedEvent) {
      Platform.isIOS
          ? await _callKitService.sendVideo(event.send)
          : await _callService.sendVideo(send: event.send);
    } else if (event is SwitchCameraPressedEvent) {
      VICameraType cameraToSwitch = state.cameraType == VICameraType.Front
          ? VICameraType.Back
          : VICameraType.Front;
      await Voximplant().getCameraManager().selectCamera(cameraToSwitch);
      yield state.copyWith(cameraType: cameraToSwitch);
    } else if (event is HoldPressedEvent) {
      Platform.isIOS
          ? await _callKitService.holdCall(event.hold)
          : await _callService.holdCall(hold: event.hold);
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
