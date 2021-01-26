/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:async';
import 'dart:io';

import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:meta/meta.dart';
import 'package:video_call/main.dart';
import 'package:video_call/services/call/call_event.dart';
import 'package:video_call/utils/log.dart';
import 'package:video_call/utils/notification_helper.dart';

enum CallState { connecting, ringing, connected, ended }

class CallService {
  final VIClient _client;

  VICall _activeCall;
  bool get hasActiveCall => _activeCall != null;
  bool get hasNoActiveCalls => _activeCall == null;

  String get callKitUUID => _activeCall?.callKitUUID;
  set callKitUUID(String uuid) => _activeCall?.callKitUUID = uuid;

  String get localVideoStreamId => _activeCall?.localVideoStream?.streamId;
  String remoteVideoStreamId;

  CallState get callState => _callState;
  CallState _callState;

  VIEndpoint get endpoint => _endpoint;
  VIEndpoint _endpoint;

  Function onIncomingCall;

  StreamController<CallEvent> _activeStreamController;

  factory CallService() => _cache ?? CallService._();
  static CallService _cache;
  CallService._() : _client = Voximplant().getClient(defaultConfig) {
    _client.onIncomingCall = _onIncomingCall;
    _client.onPushDidExpire = _pushDidExpire;
    _cache = this;
  }

  Stream<CallEvent> subscribeToCallEvents() {
    _activeStreamController?.close();
    _activeStreamController = StreamController.broadcast();
    return _activeStreamController?.stream;
  }

  Future<void> makeCall({@required String callTo}) async {
    if (hasActiveCall) {
      throw ('There is already an active call');
    }
    VICallSettings callSettings = VICallSettings();
    callSettings.videoFlags = VIVideoFlags(receiveVideo: true, sendVideo: true);
    callSettings.preferredVideoCodec = VIVideoCodec.VP8;
    _activeCall = await _client.call(callTo, callSettings);
    _callState = CallState.connecting;
    _listenToActiveCallEvents();
  }

  Future<void> answerCall() async {
    if (hasNoActiveCalls) {
      throw 'Tried to answer having no active call';
    }
    VICallSettings callSettings = VICallSettings();
    callSettings.videoFlags = VIVideoFlags(receiveVideo: true, sendVideo: true);
    callSettings.preferredVideoCodec = VIVideoCodec.VP8;
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
    _activeStreamController?.add(OnMuteCallEvent(muted: mute));
  }

  Future<void> holdCall({@required bool hold}) async {
    if (hasNoActiveCalls) {
      throw 'Tried to hold having no active call';
    }
    await _activeCall.hold(hold);
    _activeStreamController?.add(OnHoldCallEvent(hold: hold));
  }

  Future<void> sendVideo({@required bool send}) async {
    if (hasNoActiveCalls) {
      throw 'Tried to change sendVideo pref having no active call';
    }
    await _activeCall.sendVideo(send);
  }

  Future<void> _onIncomingCall(
    VIClient client,
    VICall call,
    bool video,
    Map<String, String> headers,
  ) async {
    if (hasActiveCall && _activeCall.callId != call.callId) {
      await call.reject();
      return;
    }

    _activeCall = call;
    _callState = CallState.connecting;
    _endpoint = call.endpoints.first;
    _listenToActiveCallEvents();
    _activeStreamController?.add(OnIncomingCallEvent(
        username: _activeCall?.endpoints?.first?.userName,
        displayName: _activeCall?.endpoints?.first?.displayName,
        video: video));
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
    _activeCall?.onLocalVideoStreamAdded = _onLocalVideoStreamAdded;
    _activeCall?.onLocalVideoStreamRemoved = _onLocalVideoStreamRemoved;
    _activeCall?.onEndpointAdded = _onEndpointAdded;
  }

  void _listenToEndpointEvents() {
    _activeCall?.endpoints?.first?.onRemoteVideoStreamAdded =
        _onRemoteVideoStreamAdded;
    _activeCall?.endpoints?.first?.onRemoteVideoStreamRemoved =
        _onRemoteVideoStreamRemoved;
  }

  void _pushDidExpire(VIClient client, String callKitUUID) {
    _activeStreamController
        ?.add(OnDisconnectedCallEvent(answeredElsewhere: false));
  }

  void _onCallDisconnected(
    VICall call,
    Map<String, String> headers,
    bool answeredElsewhere,
  ) {
    if (call.callId == _activeCall.callId) {
      _activeCall = null;
      _callState = CallState.ended;
      _endpoint = null;
      _log('CallService: onCallDisconnected($headers, $answeredElsewhere)');
      if (Platform.isAndroid) {
        NotificationHelper().cancelNotification();
      }
      _activeStreamController
          ?.add(OnDisconnectedCallEvent(answeredElsewhere: answeredElsewhere));
    }
  }

  void _onCallFailed(
    VICall call,
    int code,
    String description,
    Map<String, String> headers,
  ) {
    if (call.callId == _activeCall?.callId) {
      _activeCall = null;
      _callState = CallState.ended;
      _endpoint = null;
      _log('CallService: onCallFailed($code, $description, $headers)');
      _activeStreamController?.add(OnFailedCallEvent(reason: description));
    }
  }

  void _onCallConnected(VICall call, Map<String, String> headers) async {
    if (call.callId == _activeCall?.callId) {
      _activeCall = call;
      _callState = CallState.connected;
      _endpoint = call.endpoints.first;
      _log('CallService: onCallConnected($headers)');
      _activeStreamController?.add(OnConnectedCallEvent(
        username: _activeCall.endpoints?.first?.userName,
        displayName: _activeCall.endpoints?.first?.displayName,
      ));
    }
  }

  void _onCallRinging(VICall call, Map<String, String> headers) {
    if (call.callId == _activeCall.callId) {
      _log('CallService: onCallRinging($headers)');
      _callState = CallState.ringing;
      _activeStreamController?.add(OnRingingCallEvent());
    }
  }

  void _onEndpointAdded(VICall call, VIEndpoint endpoint) {
    if (call.callId == _activeCall.callId) {
      _activeCall = call;
      _log('CallService: onEndpointAdded($endpoint)');
      _listenToEndpointEvents();
    }
  }

  void _onLocalVideoStreamAdded(VICall call, VIVideoStream videoStream) {
    if (call.callId == _activeCall.callId) {
      _activeCall = call;
      _log('CallService: onLocalVideoStreamAdded: ${videoStream.streamId}');
      _activeStreamController
          ?.add(OnChangedLocalVideoCallEvent(streamId: videoStream.streamId));
    }
  }

  void _onLocalVideoStreamRemoved(VICall call, VIVideoStream videoStream) {
    if (call.callId == _activeCall.callId) {
      _activeCall = call;
      _log('CallService: onLocalVideoStreamRemoved: ${videoStream.streamId}');
      _activeStreamController
          ?.add(OnChangedLocalVideoCallEvent(streamId: null));
    }
  }

  void _onRemoteVideoStreamAdded(
      VIEndpoint endpoint, VIVideoStream videoStream) {
    _log('CallService: onRemoteVideoStreamAdded: ${videoStream.streamId}');
    remoteVideoStreamId = videoStream.streamId;
    _activeStreamController
        ?.add(OnChangedRemoteVideoCallEvent(streamId: videoStream.streamId));
  }

  void _onRemoteVideoStreamRemoved(
      VIEndpoint endpoint, VIVideoStream videoStream) {
    _log('CallService: onRemoteVideoStreamRemoved: ${videoStream.streamId}');
    remoteVideoStreamId = null;
    _activeStreamController?.add(OnChangedRemoteVideoCallEvent(streamId: null));
  }

  void _log<T>(T message) {
    log('CallService($hashCode): ${message.toString()}');
  }
}
