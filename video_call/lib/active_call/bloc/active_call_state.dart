/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

class ActiveCallState implements Equatable {
  final String description;
  final String localVideoStreamID;
  final String remoteVideoStreamID;
  final bool isOnHold;
  final bool isMuted;

  ActiveCallState(
      {@required this.description,
      @required this.localVideoStreamID,
      @required this.remoteVideoStreamID,
      @required this.isOnHold,
      @required this.isMuted});

  @override
  List<Object> get props =>
      [description, localVideoStreamID, remoteVideoStreamID, isOnHold, isMuted];
}

class CallEndedActiveCallState extends ActiveCallState {
  @override
  List<Object> get props => [description, failed, displayName];

  final bool failed;
  final String displayName;

  CallEndedActiveCallState(
      {@required reason, @required this.failed, @required this.displayName})
      : super(
            description: reason,
            localVideoStreamID: null,
            remoteVideoStreamID: null,
            isOnHold: false,
            isMuted: false);
}