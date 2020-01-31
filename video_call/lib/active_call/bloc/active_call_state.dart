/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

abstract class ActiveCallState extends Equatable {
  const ActiveCallState();
  @override
  List<Object> get props => [];
}

class ActiveCallConnecting extends ActiveCallState {}

class ActiveCallRinging extends ActiveCallState {}

class ActiveCallConnected extends ActiveCallState {}

class ActiveCallDisconnected extends ActiveCallState {}

class ActiveCallVideoStreamAdded extends ActiveCallState {
  final String streamId;
  final bool isLocal;
  ActiveCallVideoStreamAdded({@required this.streamId, @required this.isLocal});

  @override
  List<Object> get props => [streamId, isLocal];

  @override
  String toString() =>
      'ActiveCallVideoStreamAdded: streamId: $streamId, isLocal: $isLocal';
}

class ActiveCallVideoStreamRemoved extends ActiveCallState {
  final String streamId;
  final bool isLocal;
  ActiveCallVideoStreamRemoved(
      {@required this.streamId, @required this.isLocal});

  @override
  List<Object> get props => [streamId, isLocal];

  @override
  String toString() =>
      'ActiveCallVideoStreamRemoved: streamId: $streamId, isLocal: $isLocal';
}

class ActiveCallFailed extends ActiveCallState {
  final String errorDescription;
  final String endpoint;

  ActiveCallFailed({@required this.errorDescription, @required this.endpoint});

  @override
  List<Object> get props => [errorDescription, endpoint];

  @override
  String toString() => 'CallFailed: errorDescription: $errorDescription';
}

class ActiveCallHold extends ActiveCallState {
  final bool isHeld;
  final String errorDescription;

  ActiveCallHold({@required this.isHeld, @required this.errorDescription});

  @override
  List<Object> get props => [isHeld, errorDescription];

  @override
  String toString() =>
      'ActiveCallHold: isHeld: $isHeld, errorDescription: $errorDescription';
}

class ActiveCallSendVideo extends ActiveCallState {
  final bool isSendingVideo;
  final String errorDescription;

  ActiveCallSendVideo(
      {@required this.isSendingVideo, @required this.errorDescription});

  @override
  List<Object> get props => [isSendingVideo, errorDescription];

  @override
  String toString() => 'ActiveCallSendVideo: isSendingVideo: $isSendingVideo,'
      ' errorDescription: $errorDescription';
}
