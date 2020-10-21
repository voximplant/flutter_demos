/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'package:equatable/equatable.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:meta/meta.dart';

@immutable
class ActiveCallState implements Equatable {
  final String callStatus;
  final String endpointName;
  final String localVideoStreamID;
  final String remoteVideoStreamID;
  final VICameraType cameraType;
  final bool isOnHold;
  final bool isMuted;

  ActiveCallState(
      {@required this.callStatus,
      @required this.endpointName,
      @required this.localVideoStreamID,
      @required this.remoteVideoStreamID,
      @required this.cameraType,
      @required this.isOnHold,
      @required this.isMuted});

  ActiveCallState copyWith({
    String endpointName,
    String callStatus,
    String localVideoStreamID,
    String remoteVideoStreamID,
    VICameraType cameraType,
    bool isOnHold,
    bool isMuted,
  }) =>
      ActiveCallState(
        endpointName: endpointName ?? this.endpointName,
        callStatus: callStatus ?? this.callStatus,
        localVideoStreamID: localVideoStreamID ?? this.localVideoStreamID,
        remoteVideoStreamID: remoteVideoStreamID ?? this.remoteVideoStreamID,
        cameraType: cameraType ?? this.cameraType,
        isOnHold: isOnHold ?? this.isOnHold,
        isMuted: isMuted ?? this.isMuted,
      );

  ActiveCallState copyWithLocalStream(String localVideoStreamID) =>
      ActiveCallState(
        callStatus: this.callStatus,
        endpointName: this.endpointName,
        localVideoStreamID: localVideoStreamID,
        remoteVideoStreamID: this.remoteVideoStreamID,
        cameraType: this.cameraType,
        isOnHold: this.isOnHold,
        isMuted: this.isMuted,
      );

  ActiveCallState copyWithRemoteStream(String remoteVideoStreamID) =>
      ActiveCallState(
        callStatus: this.callStatus,
        endpointName: this.endpointName,
        localVideoStreamID: this.localVideoStreamID,
        remoteVideoStreamID: remoteVideoStreamID,
        cameraType: this.cameraType,
        isOnHold: this.isOnHold,
        isMuted: this.isMuted,
      );

  @override
  List<Object> get props =>
      [callStatus, localVideoStreamID, remoteVideoStreamID, isOnHold, isMuted];

  @override
  bool get stringify => true;
}

class ReadyActiveCallState extends ActiveCallState {
  ReadyActiveCallState()
      : super(
          endpointName: '',
          cameraType: VICameraType.Front,
          callStatus: '',
          localVideoStreamID: null,
          remoteVideoStreamID: null,
          isOnHold: false,
          isMuted: false,
        );
}

@immutable
class CallEndedActiveCallState extends ActiveCallState {
  final bool failed;
  final String reason;

  CallEndedActiveCallState(
      {@required this.reason,
      @required this.failed,
      @required endpointName,
      @required VICameraType cameraType})
      : super(
          callStatus: failed ? 'Failed' : 'Disconnected',
          localVideoStreamID: null,
          remoteVideoStreamID: null,
          endpointName: endpointName,
          cameraType: cameraType,
          isOnHold: false,
          isMuted: false,
        );

  @override
  List<Object> get props => [failed, failed, endpointName];
}
