/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

@immutable
class ActiveCallState implements Equatable {
  final String endpointName;
  final String callStatus;
  final VIAudioDevice activeAudioDevice;
  final List<VIAudioDevice> availableAudioDevices;
  final bool isOnHold;
  final bool isMuted;

  ActiveCallState({
    @required this.endpointName,
    @required this.callStatus,
    @required this.activeAudioDevice,
    @required this.availableAudioDevices,
    @required this.isOnHold,
    @required this.isMuted,
  });

  ActiveCallState copyWith({
    String endpointName,
    String callStatus,
    VIAudioDevice activeAudioDevice,
    List<VIAudioDevice> availableAudioDevices,
    bool isOnHold,
    bool isMuted,
  }) =>
      ActiveCallState(
        endpointName: endpointName ?? this.endpointName,
        callStatus: callStatus ?? this.callStatus,
        activeAudioDevice: activeAudioDevice ?? this.activeAudioDevice,
        availableAudioDevices:
            availableAudioDevices ?? this.availableAudioDevices,
        isOnHold: isOnHold ?? this.isOnHold,
        isMuted: isMuted ?? this.isMuted,
      );

  @override
  List<Object> get props => [
        callStatus,
        endpointName,
        activeAudioDevice,
        availableAudioDevices,
        isOnHold,
        isMuted,
      ];

  @override
  bool get stringify => true;
}

@immutable
class CallEndedActiveCallState extends ActiveCallState {
  final bool failed;
  final String reason;

  CallEndedActiveCallState({
    @required this.reason,
    @required this.failed,
    @required endpointName,
    @required activeAudioDevice,
  }) : super(
          endpointName: endpointName,
          callStatus: failed ? 'Failed' : 'Disconnected',
          activeAudioDevice: activeAudioDevice,
          availableAudioDevices: List.empty(),
          isOnHold: false,
          isMuted: false,
        );

  @override
  List<Object> get props => [failed, failed, endpointName];
}
