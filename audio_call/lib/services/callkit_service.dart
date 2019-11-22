/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.

import 'package:audio_call/screens/call_screen.dart';
import 'package:audio_call/utils/screen_arguments.dart';
import 'package:flutter_call_kit/flutter_call_kit.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'call_service.dart';
import 'navigation_service.dart';

class CallServiceIOS extends CallService {
  String _callKitUUID;

  final Uuid _uuid = Uuid();

  final FlutterCallKit _callKit = FlutterCallKit();
  final AudioDeviceManager _audioDeviceManager = Voximplant().getAudioDeviceManager();

  CallServiceIOS() : super.ctr();

  @override
  Future<void> configure() {
    _callKit.configure(
      IOSOptions('Voximplant Audio Call',
          supportsVideo: false,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1),
      didDisplayIncomingCall: _didDisplayIncomingCall,
      didActivateAudioSession: _didActivateAudioSession,
      didDeactivateAudioSession: _didDeactivateAudioSession,
      didReceiveStartCallAction: _didReceiveStartCallAction,
      didPerformDTMFAction: _didPerformDTMFAction,
      didPerformSetMutedCallAction: _didPerformSetMutedCallAction,
      didToggleHoldAction: _didToggleHoldAction,
      performAnswerCallAction: _performAnswerCallAction,
      performEndCallAction: _performEndCallAction,
    );

    return super.configure();
  }

  @override
  onIncomingCall(Call call, Map<String, String> headers) async {
    if (this.call != null) {
      await call.decline();
      return;
    }
    registerCall(call);
    print('onIncomingCall($call)');
    if (_callKitUUID == null) {
      _callKitUUID = call.callKitUUID;
      _callKit.displayIncomingCall(call.callKitUUID,
          call.endpoints?.first?.displayName,
          call.endpoints?.first?.displayName,
          handleType: HandleType.generic);
    }
  }

  @override
  Future<void> sendAudio(bool sendAudio) async {
    await super.sendAudio(sendAudio);
    _callKit.setMutedCall(_callKitUUID, !sendAudio);
  }

  @override
  Future<void> hold(bool hold) async {
    await super.hold(hold);
    _callKit.setOnHold(_callKitUUID, hold);
  }

  @override
  Future<String> makeAudioCall(String number) async {
    String callId = await super.makeAudioCall(number);
    _callKitUUID = _uuid.v4();
    this.call.callKitUUID = _callKitUUID;

    await _callKit.startCall(_callKitUUID, callId, number,
        handleType: HandleType.generic, video: false);

    return callId;
  }

  @override
  onCallConnected(Map<String, String> headers) {
    super.onCallConnected(headers);
    print('CallServiceIOS: onCallConnected($headers)');

    _callKit.updateDisplay(_callKitUUID, call.callId,
        call.endpoints.first?.userName ?? 'Unknown',
        handleType: HandleType.generic);
  }

  @override
  onCallDisconnected(Map<String, String> headers, bool answeredElsewhere) {
    print('CallServiceIOS: onCallDisconnected($headers)');
    _audioDeviceManager.callKitReleaseAudioSession();
    _callKit.reportEndCallWithUUID(_callKitUUID, EndReason.remoteEnded);
    _callKitUUID = null;
    super.onCallDisconnected(headers, answeredElsewhere);
  }

  @override
  onCallFailed(int code, String description, Map<String, String> headers) {
    print('CallServiceIOS: onCallFailed($description)');
    _audioDeviceManager.callKitReleaseAudioSession();
    _callKit.endCall(_callKitUUID);
    _callKitUUID = null;
    super.onCallFailed(code, description, headers);
  }

  @override
  onEndpointUpdated(Endpoint endpoint) {
    super.onEndpointUpdated(endpoint);
    print('CallServiceIOS: onEndpointUpdated($endpoint)');
    _callKit.updateDisplay(_callKitUUID, call.callId,
        call.endpoints.first?.userName ?? 'Unknown',
        handleType: HandleType.generic);
  }

  //#region CallKit

  Future<void> _didDisplayIncomingCall(String error, String uuid, String handle,
      String localizedCallerName, bool fromPushKit) async {
    print('CallServiceIOS: didDisplayIncomingCall(error: $error, uuid: $uuid, '
        'handle: $handle, callerName: $localizedCallerName)');
    if (this.call == null && _callKitUUID == null) {
      _callKitUUID = uuid;
    }
    if (call != null && _callKitUUID != null && call.callKitUUID != _callKitUUID) {
      await _callKit.endCall(uuid);
    }
  }

  Future<void> _didActivateAudioSession() async {
    print('CallServiceIOS: didActivateAudioSession');
    await _audioDeviceManager.callKitStartAudio();
  }

  Future<void> _didDeactivateAudioSession() async {
    print('CallServiceIOS: didDeactivateAudioSession');
    await _audioDeviceManager.callKitStopAudio();
  }

  Future<void> _didReceiveStartCallAction(String uuid, String handle) async {
    print('CallServiceIOS: didReceiveStartCallAction(uuid: $uuid, handle: $handle)');
    await _audioDeviceManager.callKitConfigureAudioSession();
  }

  Future<void> _didPerformDTMFAction(String digit, String uuid) async {
    // Called when the system or user performs a DTMF action
    print('CallServiceIOS: didPerformDTMFAction(digit: $digit, uuid: $uuid)');
  }

  Future<void> _didPerformSetMutedCallAction(bool mute, String uuid) async {
    // Called when the system or user mutes a call
    print('CallServiceIOS: didPerformSetMutedCallAction(mute: $mute, uuid: $uuid)');
    await super.sendAudio(!mute);
    if (onCallMutedEvent != null) {
      onCallMutedEvent(mute);
    }
  }

  Future<void> _didToggleHoldAction(bool enable, String uuid) async {
    // Called when the system or user holds a call
    print('CallServiceIOS: didToggleHoldAction(hold: $enable, uuid: $uuid)');
    await super.hold(enable);
    if (onCallPutOnHoldEvent != null) {
      onCallPutOnHoldEvent(enable);
    }
  }

  Future<void> _performAnswerCallAction(String uuid) async {
    print('CallServiceIOS: performAnswerCallAction(uuid: $uuid)');
    if (call != null) {
      GetIt locator = GetIt.instance;
      locator<NavigationService>().navigateTo(CallScreen.routeName,
          arguments: CallArguments.withCallId(call.callId));
      await _audioDeviceManager.callKitConfigureAudioSession();
      await super.answer();
    }
  }

  Future<void> _performEndCallAction(String uuid) async {
    print('CallServiceIOS: performEndCallAction(uuid: $uuid)');
    await hangup();
  }

//#endregion
}
