/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

import 'call_state.dart';

typedef void OnIncomingCall(String callId, String caller);

class CallService {
  final VIClient _client;
  VICall _activeCall;
  StreamController<CallState> _activeStreamController;
  OnIncomingCall onIncomingCall;

  String get activeCallId => _activeCall?.callId;

  CallService(this._client) {
    _client.onIncomingCall = _onIncomingCall;
  }

  Stream<CallState> subscribeToCallStateChanges(String callId) {
    if (_activeCall.callId == callId) {
      _activeStreamController?.close();
      _activeStreamController = StreamController.broadcast();
      return _activeStreamController.stream;
    }
    return null;
  }

  Future<String> makeVideoCall({@required String callTo}) async {
    if (_activeCall != null) {
      throw 'There is already an active call';
    }
    VICallSettings callSettings = VICallSettings();
    callSettings.videoFlags = VIVideoFlags(receiveVideo: true, sendVideo: true);
    callSettings.preferredVideoCodec = VIVideoCodec.VP8;
    _activeCall = await _client.call(callTo, callSettings);
    _listenToActiveCallEvents();
    return _activeCall.callId;
  }

  Future<String> answerVideoCall() async {
    if (_activeCall == null) {
      throw 'No active call';
    }
    VICallSettings callSettings = VICallSettings();
    callSettings.videoFlags = VIVideoFlags(receiveVideo: true, sendVideo: true);
    callSettings.preferredVideoCodec = VIVideoCodec.VP8;
    await _activeCall.answer(callSettings);
    return _activeCall.callId;
  }

  Future<void> endCall(String callId) async {
    if (_activeCall.callId == callId) {
      await _activeCall.hangup();
    }
  }

  Future<void> declineCall(String callId) async {
    if (_activeCall.callId == callId) {
      await _activeCall.decline();
    }
  }

  Future<void> holdCall(String callId, bool doHold) async {
    if (_activeCall.callId == callId) {
      return _activeCall.hold(doHold);
    } else {
      throw 'No active call';
    }
  }

  Future<void> sendVideo(String callId, bool doSendVideo) async {
    if (_activeCall.callId == callId) {
      await _activeCall.sendVideo(doSendVideo);
    } else {
      throw 'No active call';
    }
  }

  void _onIncomingCall(VIClient client, VICall call, bool video,
      Map<String, String> headers) async {
    if (_activeCall != null) {
      await call.decline();
      return;
    }
    if (onIncomingCall != null) {
      _activeCall = call;
      _listenToActiveCallEvents();
      onIncomingCall(
          _activeCall.callId, _activeCall.endpoints?.first?.displayName);
    }
  }

  void _listenToActiveCallEvents() {
    _activeCall.onCallRinging = _onCallRinging;
    _activeCall.onCallConnected = _onCallConnected;
    _activeCall.onCallDisconnected = _onCallDisconnected;
    _activeCall.onCallFailed = _onCallFailed;
    _activeCall.onLocalVideoStreamAdded = _onLocalVideoStreamAdded;
    _activeCall.onLocalVideoStreamRemoved = _onLocalVideoStreamRemoved;
    _activeCall.onEndpointAdded = _onEndpointAdded;
  }

  void _listenToEndpointEvents() {
    _activeCall.endpoints?.first?.onRemoteVideoStreamAdded =
        _onRemoteVideoStreamAdded;
    _activeCall.endpoints?.first?.onRemoteVideoStreamRemoved =
        _onRemoteVideoStreamRemoved;
  }

  void _onCallDisconnected(
      VICall call, Map<String, String> headers, bool answeredElsewhere) {
    if (call.callId == _activeCall.callId) {
      print('CallService: onCallDisconnected($headers, $answeredElsewhere)');
      _activeStreamController.add(CallStateDisconnected());
      _activeCall = null;
    }
  }

  void _onCallFailed(
      VICall call, int code, String description, Map<String, String> headers) {
    if (call.callId == _activeCall.callId) {
      print('CallService: onCallFailed($code, $description, $headers)');
      _activeStreamController.add(CallStateFailed(
          errorDescription: description,
          endpoint: _activeCall.endpoints?.first?.displayName));
      _activeCall = null;
    }
  }

  void _onCallConnected(VICall call, Map<String, String> headers) {
    if (call.callId == _activeCall.callId) {
      print('CallService: onCallConnected($headers)');
      _activeStreamController.add(CallStateConnected());
    }
  }

  void _onCallRinging(VICall call, Map<String, String> headers) {
    if (call.callId == _activeCall.callId) {
      print('CallService: onCallRinging($headers)');
      _activeStreamController.add(CallStateRinging());
    }
  }

  void _onEndpointAdded(VICall call, VIEndpoint endpoint) {
    if (call.callId == _activeCall.callId) {
      print('CallService: onEndpointAdded($endpoint)');
      _listenToEndpointEvents();
    }
  }

  void _onLocalVideoStreamAdded(VICall call, VIVideoStream videoStream) {
    if (call.callId == _activeCall.callId) {
      print(
          'CallService: onLocalVideoStreamAdded: ${videoStream.streamId}');
      _activeStreamController.add(CallStateVideoStreamAdded(
          streamId: videoStream.streamId, isLocal: true));
    }
  }

  void _onLocalVideoStreamRemoved(VICall call, VIVideoStream videoStream) {
    if (call.callId == _activeCall.callId) {
      print(
          'CallService: onLocalVideoStreamRemoved: ${videoStream.streamId}');
      _activeStreamController.add(CallStateVideoStreamRemoved(
          streamId: videoStream.streamId, isLocal: true));
    }
  }

  void _onRemoteVideoStreamAdded(
      VIEndpoint endpoint, VIVideoStream videoStream) {
    print(
        'CallService: onRemoteVideoStreamAdded: ${videoStream.streamId}');
    _activeStreamController.add(CallStateVideoStreamAdded(
        streamId: videoStream.streamId, isLocal: false));
  }

  void _onRemoteVideoStreamRemoved(
      VIEndpoint endpoint, VIVideoStream videoStream) {
    print(
        'CallService: onRemoteVideoStreamRemoved: ${videoStream.streamId}');
    _activeStreamController.add(CallStateVideoStreamRemoved(
        streamId: videoStream.streamId, isLocal: false));
  }
}
