/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:meta/meta.dart';
import 'package:video_call/services/call/call_event.dart';

abstract class ActiveCallEvent { }

class ReadyToInteractCallEvent implements ActiveCallEvent {
  final bool isIncoming;
  final String endpoint;

  ReadyToInteractCallEvent(
      {@required this.isIncoming, @required this.endpoint});
}

class CallChangedEvent implements ActiveCallEvent {
  final CallEvent callEvent;

  CallChangedEvent({@required this.callEvent});
}

class SendVideoPressedEvent implements ActiveCallEvent {
  final bool send;

  SendVideoPressedEvent({@required this.send});
}

class SwitchCameraPressedEvent implements ActiveCallEvent { }

class HoldPressedEvent implements ActiveCallEvent {
  final bool hold;

  HoldPressedEvent({@required this.hold});
}

class MutePressedEvent implements ActiveCallEvent {
  final bool mute;

  MutePressedEvent({@required this.mute});
}

class HangupPressedEvent implements ActiveCallEvent { }
