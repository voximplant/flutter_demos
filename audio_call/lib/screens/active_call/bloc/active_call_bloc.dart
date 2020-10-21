/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:async';
import 'dart:io';

import 'package:audio_call/screens/active_call/bloc/active_call_event.dart';
import 'package:audio_call/screens/active_call/bloc/active_call_state.dart';
import 'package:audio_call/services/call/audio_device_event.dart';
import 'package:audio_call/services/call/call_event.dart';
import 'package:audio_call/services/call/call_service.dart';
import 'package:audio_call/services/call/callkit_service.dart';
import 'package:audio_call/utils/log.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';

class ActiveCallBloc extends Bloc<ActiveCallEvent, ActiveCallState> {
  final CallService _callService = CallService();
  final CallKitService _callKitService =
      Platform.isIOS ? CallKitService() : null;

  StreamSubscription _callStateSubscription;
  StreamSubscription _audioDeviceSubscription;

  ActiveCallBloc(bool isIncoming, String endpoint)
      : super(ActiveCallState(
          isOnHold: false,
          isMuted: false,
          activeAudioDevice: null,
          availableAudioDevices: [],
          endpointName: '',
          callStatus: '',
        )) {
    add(ReadyToStartCallEvent(
      isIncoming: isIncoming,
      endpoint: endpoint,
    ));
  }

  @override
  Future<void> close() {
    if (_callStateSubscription != null) {
      _callStateSubscription.cancel();
    }
    if (_audioDeviceSubscription != null) {
      _audioDeviceSubscription.cancel();
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
      _audioDeviceSubscription =
          _callService.subscribeToAudioDeviceEvents().listen(
        (event) {
          add(AudioDevicesChanged(event: event));
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
          availableAudioDevices: _callService.availableAudioDevices,
          activeAudioDevice: _callService.activeAudioDevice,
        );
      } catch (e) {
        add(CallChangedEvent(event: OnFailedCallEvent(reason: e)));
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
          failed: true,
          endpointName: state.endpointName,
          activeAudioDevice: state.activeAudioDevice,
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
          activeAudioDevice: state.activeAudioDevice,
        );
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
        );
      } else if (callEvent is OnRingingCallEvent) {
        _log('onRinging event');
        yield state.copyWith(callStatus: 'Ringing');
      }
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
    } else if (event is SelectAudioDevicePressedEvent) {
      await _callService.selectAudioDevice(device: event.device);
    } else if (event is AudioDevicesChanged) {
      AudioDeviceEvent audioEvent = event.event;
      if (audioEvent is OnActiveAudioDeviceChanged) {
        yield state.copyWith(activeAudioDevice: audioEvent.device);
      } else if (audioEvent is OnAvailableAudioDevicesListChanged) {
        yield state.copyWith(availableAudioDevices: audioEvent.devices);
      }
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
