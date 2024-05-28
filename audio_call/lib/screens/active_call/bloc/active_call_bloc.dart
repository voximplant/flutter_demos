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
import 'package:flutter_voximplant/flutter_voximplant.dart';

class ActiveCallBloc extends Bloc<ActiveCallEvent, ActiveCallState> {
  final CallService _callService = CallService();
  final CallKitService? _callKitService =
      Platform.isIOS ? CallKitService() : null;

  StreamSubscription? _callStateSubscription;
  StreamSubscription? _audioDeviceSubscription;

  bool _isIncoming;
  String _endpoint;

  ActiveCallBloc(this._isIncoming, this._endpoint)
      : super(const ActiveCallState(
          isOnHold: false,
          isMuted: false,
          activeAudioDevice: VIAudioDevice.Earpiece,
          availableAudioDevices: [],
          endpointName: '',
          callStatus: '',
        )) {
    on<ReadyToStartCallEvent>(_readyToStartCall);
    on<CallChangedEvent>(_handleCallChanged);
    on<HoldPressedEvent>(_holdCall);
    on<MutePressedEvent>(_muteAudio);
    on<HangupPressedEvent>(_hangupCall);
    on<SelectAudioDevicePressedEvent>(_selectAudioDevice);
    on<AudioDevicesChanged>(_handleAudioDevicesChanged);
  }

  @override
  Future<void> close() {
    _callStateSubscription?.cancel();
    _audioDeviceSubscription?.cancel();
    return super.close();
  }

  Future<void> _readyToStartCall(
      ReadyToStartCallEvent event, Emitter<ActiveCallState> emit) async {
    _callStateSubscription = _callService.subscribeToCallEvents().listen(
      (event) {
        add(CallChangedEvent(event));
      },
    );
    _audioDeviceSubscription =
        _callService.subscribeToAudioDeviceEvents().listen(
      (event) {
        add(AudioDevicesChanged(event));
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
            _endpoint ??
            '',
        availableAudioDevices: _callService.availableAudioDevices,
        activeAudioDevice: _callService.activeAudioDevice,
      ));
    } catch (e) {
      add(CallChangedEvent(OnFailedCallEvent(reason: e.toString())));
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
        activeAudioDevice: state.activeAudioDevice,
      ));
    } else if (callEvent is OnDisconnectedCallEvent) {
      _log('onDisconnected event');
      await _callKitService?.reportCallEnded(
        reason: FCXCallEndedReason.remoteEnded,
      );
      emit(CallEndedActiveCallState(
        reason: 'Disconnected',
        failed: false,
        endpointName: state.endpointName,
        activeAudioDevice: state.activeAudioDevice,
      ));
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
      String name = callEvent.displayName ?? callEvent.username ?? '';
      emit(state.copyWith(callStatus: 'Connected', endpointName: name));
      await _callKitService?.reportConnected(
        callEvent.username,
        callEvent.displayName,
      );
    } else if (callEvent is OnRingingCallEvent) {
      _log('onRinging event');
      emit(state.copyWith(callStatus: 'Ringing'));
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

  Future<void> _selectAudioDevice(SelectAudioDevicePressedEvent event,
      Emitter<ActiveCallState> emit) async {
    await _callService.selectAudioDevice(device: event.device);
  }

  Future<void> _handleAudioDevicesChanged(
      AudioDevicesChanged event, Emitter<ActiveCallState> emit) async {
    AudioDeviceEvent audioEvent = event.event;
    if (audioEvent is OnActiveAudioDeviceChanged) {
      emit(state.copyWith(activeAudioDevice: audioEvent.device));
    } else if (audioEvent is OnAvailableAudioDevicesListChanged) {
      emit(state.copyWith(availableAudioDevices: audioEvent.devices));
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
