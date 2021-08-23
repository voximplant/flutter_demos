/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:audio_call/services/call/audio_device_event.dart';
import 'package:audio_call/services/call/call_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

abstract class ActiveCallEvent { }

class ReadyToStartCallEvent implements ActiveCallEvent {
  final bool isIncoming;
  final String? endpoint;

  ReadyToStartCallEvent({
    required this.isIncoming,
    required this.endpoint,
  });
}

class CallChangedEvent implements ActiveCallEvent {
  final CallEvent event;

  CallChangedEvent({
    required this.event,
  });
}

class AudioDevicesChanged implements ActiveCallEvent {
  final AudioDeviceEvent event;

  AudioDevicesChanged({
    required this.event,
  });
}

class HoldPressedEvent implements ActiveCallEvent {
  final bool hold;

  HoldPressedEvent({
    required this.hold,
  });
}

class SelectAudioDevicePressedEvent implements ActiveCallEvent {
  final VIAudioDevice device;

  SelectAudioDevicePressedEvent({
    required this.device,
  });
}

class MutePressedEvent implements ActiveCallEvent {
  final bool mute;

  MutePressedEvent({
    required this.mute,
  });
}

class HangupPressedEvent implements ActiveCallEvent { }
