/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/foundation.dart';
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
