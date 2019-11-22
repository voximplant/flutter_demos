/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.

import 'dart:io';
import 'package:audio_call/services/call_service_android.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

import 'callkit_service.dart';

typedef void CallMuted(bool muted);
typedef void CallPutOnHold(bool onHold);



class CallService {
  static CallService _singleton;


  bool navigateToIncomingCallScreen = false;

  Client _client;
  set client(Client client) {
    print('CallService: setClient');
    _client = client;
    configure();
    _client.onIncomingCall = onIncomingCall;
  }

  Call call;
  String get callId => call?.callId;

  CallDisconnected onCallDisconnectedEvent;
  CallFailed onCallFailedEvent;
  CallConnected onCallConnectedEvent;
  CallRinging onCallRingingEvent;
  CallAudioStarted onCallAudioStartedEvent;
  SIPInfoReceived onSIPInfoReceivedEvent;
  MessageReceived onMessageReceivedEvent;
  ICECompleted onICECompletedEvent;
  ICETimeout onICETimeoutEvent;
  EndpointAdded onEndpointAddedEvent;

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
    Call call = await _client.call(number);
    registerCall(call);
    print('CallService: created call: ${call.callId}');
    return call.callId;
  }

  onIncomingCall(Call call, Map<String, String> headers) async {
    print('CallService: onIncomingCall(${call.callId})');
    if (this.call != null) {
      await call.decline();
      return;
    }
    registerCall(call);
  }

//#region Call events
  registerCall(Call call) {
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
    CallDisconnected onCallDisconnected,
    CallFailed onCallFailed,
    CallConnected onCallConnected,
    CallRinging onCallRinging,
    CallAudioStarted onCallAudioStarted,
    SIPInfoReceived onSIPInfoReceived,
    MessageReceived onMessageReceived,
    ICECompleted onICECompleted,
    ICETimeout onICETimeout,
    EndpointAdded onEndpointAdded,
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

  onCallDisconnected(Map<String, String> headers, bool answeredElsewhere) {
    print('CallService: onCallDisconnected($headers, $answeredElsewhere)');
    call = null;
    if (onCallDisconnectedEvent != null) {
      onCallDisconnectedEvent(headers, answeredElsewhere);
    }
  }

  onCallFailed(int code, String description, Map<String, String> headers) {
    print('CallService: onCallFailed($code, $description, $headers)');
    call = null;
    if (onCallFailedEvent != null) {
      onCallFailedEvent(code, description, headers);
    }
  }

  onCallConnected(Map<String, String> headers) {
    print('CallService: onCallConnected($headers)');
    if (onCallConnectedEvent != null) {
      onCallConnectedEvent(headers);
    }
  }

  onCallRinging(Map<String, String> headers) {
    print('CallService: onCallRinging($headers)');
    if (onCallRingingEvent != null) {
      onCallRingingEvent(headers);
    }
  }

  onCallAudioStarted() {
    print('CallService: onCallAudioStarted()');
    if (onCallAudioStartedEvent != null) {
      onCallAudioStartedEvent();
    }
  }

  onSIPInfoReceived(String type, String content, Map<String, String> headers) {
    print('CallService: onSIPInfoReceived($type, $content, $headers)');
    if (onSIPInfoReceivedEvent != null) {
      onSIPInfoReceivedEvent(type, content, headers);
    }
  }

  onMessageReceived(String message) {
    print('CallScreen: onMessageReceived($message)');
    if (onMessageReceivedEvent != null) {
      onMessageReceivedEvent(message);
    }
  }

  onICETimeout() {
    print('CallService: onICETimeout()');
    if (onICETimeoutEvent != null) {
      onICETimeoutEvent();
    }
  }

  onICECompleted() {
    print('CallService: onICECompleted()');
    if (onICECompletedEvent != null) {
      onICECompletedEvent();
    }
  }

  onEndpointAdded(Endpoint endpoint) {
    print('CallService: onEndpointAdded($endpoint)');
    endpoint.onEndpointUpdated = onEndpointUpdated;
  }

  onEndpointUpdated(Endpoint endpoint) {
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

