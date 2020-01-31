/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:io';
import 'package:audio_call/services/call_service_android.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

import 'callkit_service.dart';

typedef void CallMuted(bool muted);
typedef void CallPutOnHold(bool onHold);

class CallService {
  static CallService _singleton;

  bool navigateToIncomingCallScreen = false;

  VIClient _client;
  set client(VIClient client) {
    print('CallService: setClient');
    _client = client;
    configure();
    _client.onIncomingCall = onIncomingCall;
  }

  VICall call;
  String get callId => call?.callId;

  VICallDisconnected onCallDisconnectedEvent;
  VICallFailed onCallFailedEvent;
  VICallConnected onCallConnectedEvent;
  VICallRinging onCallRingingEvent;
  VICallAudioStarted onCallAudioStartedEvent;
  VISIPInfoReceived onSIPInfoReceivedEvent;
  VIMessageReceived onMessageReceivedEvent;
  VIICECompleted onICECompletedEvent;
  VIICETimeout onICETimeoutEvent;
  VIEndpointAdded onEndpointAddedEvent;

  CallMuted onCallMutedEvent;
  CallPutOnHold onCallPutOnHoldEvent;

  factory CallService() {
    if (_singleton == null) {
      print('CallService: singletone is null');
      if (Platform.isIOS) {
        _singleton = CallServiceIOS();
      } else if (Platform.isAndroid) {
        _singleton = CallServiceAndroid();
      }
    }
    return _singleton;
  }

  CallService.ctr() {
    print('CallService: ctr');
  }

  String getEndpointNameForCall(String callId) {
    if (call?.callId == callId) {
      return call?.endpoints?.first?.userName;
    }
    return null;
  }

  Future<void> configure() async {}

  Future<String> makeAudioCall(String number) async {
    VICall call = await _client.call(number);
    registerCall(call);
    print('CallService: created call: ${call.callId}');
    return call.callId;
  }

  onIncomingCall(VIClient client, VICall call, bool video,
      Map<String, String> headers) async {
    print('CallService: onIncomingCall(${call.callId})');
    if (this.call != null) {
      await call.decline();
      return;
    }
    registerCall(call);
  }

//#region Call events
  registerCall(VICall call) {
    this.call = call;
    this.call.onCallDisconnected = onCallDisconnected;
    this.call.onCallFailed = onCallFailed;
    this.call.onCallConnected = onCallConnected;
    this.call.onCallRinging = onCallRinging;
    this.call.onCallAudioStarted = onCallAudioStarted;
    this.call.onSIPInfoReceived = onSIPInfoReceived;
    this.call.onMessageReceived = onMessageReceived;
    this.call.onICECompleted = onICECompleted;
    this.call.onICETimeout = onICETimeout;
    this.call.onEndpointAdded = onEndpointAdded;
  }

  void bind({
    VICallDisconnected onCallDisconnected,
    VICallFailed onCallFailed,
    VICallConnected onCallConnected,
    VICallRinging onCallRinging,
    VICallAudioStarted onCallAudioStarted,
    VISIPInfoReceived onSIPInfoReceived,
    VIMessageReceived onMessageReceived,
    VIICECompleted onICECompleted,
    VIICETimeout onICETimeout,
    VIEndpointAdded onEndpointAdded,
    CallMuted onCallMuted,
    CallPutOnHold onCallPutOnHold,
  }) {
    onCallDisconnectedEvent = onCallDisconnected;
    onCallFailedEvent = onCallFailed;
    onCallConnectedEvent = onCallConnected;
    onCallRingingEvent = onCallRinging;
    onCallAudioStartedEvent = onCallAudioStarted;
    onSIPInfoReceivedEvent = onSIPInfoReceived;
    onMessageReceivedEvent = onMessageReceived;
    onICECompletedEvent = onICECompleted;
    onICETimeoutEvent = onICETimeout;
    onEndpointAddedEvent = onEndpointAdded;
    onCallMutedEvent = onCallMuted;
    onCallPutOnHoldEvent = onCallPutOnHold;
  }

  onCallDisconnected(
      VICall call, Map<String, String> headers, bool answeredElsewhere) {
    print('CallService: onCallDisconnected($headers, $answeredElsewhere)');
    this.call = null;
    if (onCallDisconnectedEvent != null) {
      onCallDisconnectedEvent(call, headers, answeredElsewhere);
    }
  }

  onCallFailed(
      VICall call, int code, String description, Map<String, String> headers) {
    print('CallService: onCallFailed($code, $description, $headers)');
    this.call = null;
    if (onCallFailedEvent != null) {
      onCallFailedEvent(call, code, description, headers);
    }
  }

  onCallConnected(VICall call, Map<String, String> headers) {
    print('CallService: onCallConnected($headers)');
    if (onCallConnectedEvent != null) {
      onCallConnectedEvent(call, headers);
    }
  }

  onCallRinging(VICall call, Map<String, String> headers) {
    print('CallService: onCallRinging($headers)');
    if (onCallRingingEvent != null) {
      onCallRingingEvent(call, headers);
    }
  }

  onCallAudioStarted(VICall call) {
    print('CallService: onCallAudioStarted()');
    if (onCallAudioStartedEvent != null) {
      onCallAudioStartedEvent(call);
    }
  }

  onSIPInfoReceived(
      VICall call, String type, String content, Map<String, String> headers) {
    print('CallService: onSIPInfoReceived($type, $content, $headers)');
    if (onSIPInfoReceivedEvent != null) {
      onSIPInfoReceivedEvent(call, type, content, headers);
    }
  }

  onMessageReceived(VICall call, String message) {
    print('CallScreen: onMessageReceived($message)');
    if (onMessageReceivedEvent != null) {
      onMessageReceivedEvent(call, message);
    }
  }

  onICETimeout(VICall call) {
    print('CallService: onICETimeout()');
    if (onICETimeoutEvent != null) {
      onICETimeoutEvent(call);
    }
  }

  onICECompleted(VICall call) {
    print('CallService: onICECompleted()');
    if (onICECompletedEvent != null) {
      onICECompletedEvent(call);
    }
  }

  onEndpointAdded(VICall call, VIEndpoint endpoint) {
    print('CallService: onEndpointAdded($endpoint)');
    endpoint.onEndpointUpdated = onEndpointUpdated;
  }

  onEndpointUpdated(VIEndpoint endpoint) {
    print('CallService: onEndpointUpdated($endpoint)');
  }

//#endregion

//#region Call management
  Future<void> answer() async {
    return await call?.answer();
  }

  Future<void> sendAudio(bool sendAudio) async {
    return await call?.sendAudio(sendAudio);
  }

  Future<void> hold(bool hold) async {
    return await call?.hold(hold);
  }

  Future<void> hangup() async {
    return await call?.hangup();
  }

  Future<void> decline() async {
    await call?.decline();
  }
//#endregion
}
