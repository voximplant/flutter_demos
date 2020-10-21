/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:async';
import 'dart:io';

import 'package:audio_call/main.dart';
import 'package:audio_call/services/call/audio_device_event.dart';
import 'package:audio_call/services/call/call_event.dart';
import 'package:audio_call/utils/log.dart';
import 'package:audio_call/utils/notification_helper.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:meta/meta.dart';

enum CallState { connecting, ringing, connected, ended }

class CallService {
  final VIClient _client;
  final VIAudioDeviceManager _audioDeviceManager;

  VICall _activeCall;
  bool get hasActiveCall => _activeCall != null;
  bool get hasNoActiveCalls => _activeCall == null;

  String get callKitUUID => _activeCall?.callKitUUID;
  set callKitUUID(String uuid) => _activeCall?.callKitUUID = uuid;

  Function onIncomingCall;

  StreamController<CallEvent> _callStreamController;
  StreamController<AudioDeviceEvent> _audioDeviceStreamController;

  CallState get callState => _callState;
  CallState _callState;

  VIEndpoint get endpoint => _endpoint;
  VIEndpoint _endpoint;

  VIAudioDevice get activeAudioDevice => __activeAudioDevice;
  VIAudioDevice __activeAudioDevice;
  set _activeAudioDevice(VIAudioDevice device) {
    _log('onAudioDeviceChanged');
    __activeAudioDevice = device;
    _audioDeviceStreamController?.add(
      OnActiveAudioDeviceChanged(
        device: device,
      ),
    );
  }

  get availableAudioDevices => __availableAudioDevices;
  List<VIAudioDevice> __availableAudioDevices;
  set _availableAudioDevices(List<VIAudioDevice> devices) {
    _log('onAudioDeviceListChanged');
    __availableAudioDevices = devices;
    _audioDeviceStreamController?.add(
      OnAvailableAudioDevicesListChanged(
        devices: devices,
      ),
    );
  }

  VIVideoFlags get _defaultFlags =>
      VIVideoFlags(sendVideo: false, receiveVideo: false);

  factory CallService() => _cache ?? CallService._();
  static CallService _cache;
  CallService._()
      : _client = Voximplant().getClient(defaultConfig),
        _audioDeviceManager = Voximplant().getAudioDeviceManager() {
    _log('initialize');
    _client.onIncomingCall = _onIncomingCall;
    _client.onPushDidExpire = _pushDidExpire;
    _configureAudioDevices();
    _cache = this;
  }

  void _configureAudioDevices() async {
    try {
      _activeAudioDevice = await _audioDeviceManager.getActiveDevice();
      _availableAudioDevices = await _audioDeviceManager.getAudioDevices();
    } catch (e) {
      _log('_configureAudioDevices, error: $e');
    }
    _audioDeviceManager.onAudioDeviceChanged = (_, device) {
      _activeAudioDevice = device;
    };
    _audioDeviceManager.onAudioDeviceListChanged = (_, list) {
      _availableAudioDevices = list;
    };
  }

  Stream<CallEvent> subscribeToCallEvents() {
    _callStreamController?.close();
    _callStreamController = StreamController.broadcast();
    return _callStreamController?.stream;
  }

  Stream<AudioDeviceEvent> subscribeToAudioDeviceEvents() {
    _audioDeviceStreamController?.close();
    _audioDeviceStreamController = StreamController.broadcast();
    return _audioDeviceStreamController?.stream;
  }

  Future<void> makeCall({@required String callTo}) async {
    if (hasActiveCall) {
      throw ('There is already an active call');
    }
    VICallSettings callSettings = VICallSettings();
    callSettings.videoFlags = _defaultFlags;
    _activeCall = await _client.call(callTo, callSettings);
    _callState = CallState.connecting;
    _listenToActiveCallEvents();
  }

  Future<void> answerCall() async {
    if (hasNoActiveCalls) {
      throw 'Tried to answer having no active call';
    }
    VICallSettings callSettings = VICallSettings();
    callSettings.videoFlags = _defaultFlags;
    await _activeCall.answer(callSettings);
  }

  Future<void> hangup() async {
    if (hasNoActiveCalls) {
      throw 'Tried to hangup having no active call';
    }
    await _activeCall.hangup();
  }

  Future<void> decline() async {
    if (hasNoActiveCalls) {
      throw 'Tried to decline having no active call';
    }
    await _activeCall.decline();
  }

  Future<void> muteCall({@required bool mute}) async {
    if (hasNoActiveCalls) {
      throw 'Tried to mute having no active call';
    }
    await _activeCall.sendAudio(!mute);
    _callStreamController?.add(OnMuteCallEvent(muted: mute));
  }

  Future<void> holdCall({@required bool hold}) async {
    if (hasNoActiveCalls) {
      throw 'Tried to hold having no active call';
    }
    await _activeCall.hold(hold);
    _callStreamController?.add(OnHoldCallEvent(hold: hold));
  }

  Future<void> selectAudioDevice({@required VIAudioDevice device}) async =>
      await _audioDeviceManager.selectAudioDevice(device);

  Future<void> _onIncomingCall(
    VIClient client,
    VICall call,
    bool video,
    Map<String, String> headers,
  ) async {
    _log('_onIncomingCall');
    if (hasActiveCall && _activeCall.callId != call.callId) {
      await call.reject();
      return;
    }
    _activeCall = call;
    _callState = CallState.connecting;
    _endpoint = call.endpoints.first;
    _listenToActiveCallEvents();
    _callStreamController?.add(
      OnIncomingCallEvent(
        username: call?.endpoints?.first?.userName,
        displayName: call?.endpoints?.first?.displayName,
      ),
    );
    if (onIncomingCall != null) {
      onIncomingCall();
      onIncomingCall = null;
    }
  }

  void _listenToActiveCallEvents() {
    _activeCall?.onCallRinging = _onCallRinging;
    _activeCall?.onCallConnected = _onCallConnected;
    _activeCall?.onCallDisconnected = _onCallDisconnected;
    _activeCall?.onCallFailed = _onCallFailed;
  }

  void _pushDidExpire(VIClient client, String callKitUUID) {
    _callStreamController?.add(
      OnDisconnectedCallEvent(answeredElsewhere: false),
    );
  }

  void _onCallDisconnected(
    VICall call,
    Map<String, String> headers,
    bool answeredElsewhere,
  ) {
    _log('onCallDisconnected');
    if (call.callId == _activeCall.callId) {
      _activeCall = null;
      _callState = CallState.ended;
      _endpoint = null;
      if (Platform.isAndroid) {
        NotificationHelper().cancelNotification();
      }
      _callStreamController?.add(
        OnDisconnectedCallEvent(answeredElsewhere: answeredElsewhere),
      );
    }
  }

  void _onCallFailed(
    VICall call,
    int code,
    String description,
    Map<String, String> headers,
  ) {
    _log('onCallFailed($code, $description)');
    if (call.callId == _activeCall?.callId) {
      _activeCall = null;
      _callState = CallState.ended;
      _endpoint = null;
      _callStreamController?.add(OnFailedCallEvent(reason: description));
    }
  }

  void _onCallConnected(VICall call, Map<String, String> headers) async {
    _log('_onCallConnected');
    if (call.callId == _activeCall?.callId) {
      _activeCall = call;
      _callState = CallState.connected;
      _endpoint = call.endpoints.first;
      _callStreamController?.add(
        OnConnectedCallEvent(
          username: call.endpoints?.first?.userName,
          displayName: call.endpoints?.first?.displayName,
        ),
      );
    }
  }

  void _onCallRinging(VICall call, Map<String, String> headers) {
    _log('_onCallRinging');
    if (call.callId == _activeCall.callId) {
      _callState = CallState.ringing;
      _callStreamController?.add(OnRingingCallEvent());
    }
  }

  void _log<T>(T message) {
    log('CallService($hashCode): ${message.toString()}');
  }
}
