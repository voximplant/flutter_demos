/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:audio_call/services/call/audio_device_event.dart';
import 'package:audio_call/services/call/call_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

abstract class ActiveCallEvent { }

class ReadyToStartCallEvent implements ActiveCallEvent {
  ReadyToStartCallEvent();
}

class CallChangedEvent implements ActiveCallEvent {
  final CallEvent event;
  CallChangedEvent(this.event);
}

class AudioDevicesChanged implements ActiveCallEvent {
  final AudioDeviceEvent event;

  AudioDevicesChanged(this.event);
}

class HoldPressedEvent implements ActiveCallEvent {
  final bool hold;

  HoldPressedEvent(this.hold);
}

class SelectAudioDevicePressedEvent implements ActiveCallEvent {
  final VIAudioDevice device;

  SelectAudioDevicePressedEvent(this.device);
}

class MutePressedEvent implements ActiveCallEvent {
  final bool mute;

  MutePressedEvent(this.mute);
}

class HangupPressedEvent implements ActiveCallEvent { }
