// Copyright (c) 2011 - 2026, Voximplant, Inc. All rights reserved.

import 'package:flutter_voximplant/flutter_voximplant.dart';

abstract class AudioDeviceEvent { }

class OnActiveAudioDeviceChanged implements AudioDeviceEvent {
  final VIAudioDevice device;

  OnActiveAudioDeviceChanged({
    required this.device,
  });
}

class OnAvailableAudioDevicesListChanged implements AudioDeviceEvent {
  final List<VIAudioDevice> devices;

  OnAvailableAudioDevicesListChanged({
    required this.devices,
  });
}
