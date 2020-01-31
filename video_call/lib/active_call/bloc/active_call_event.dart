/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:video_call/services/call_state.dart';

abstract class ActiveCallEvent extends Equatable {
  const ActiveCallEvent();

  @override
  List<Object> get props => [];
}

class StartOutgoingCall extends ActiveCallEvent {
  final String callTo;

  StartOutgoingCall({@required this.callTo});

  @override
  List<Object> get props => [callTo];

  @override
  String toString() => 'StartOutgoingCall: callTo: $callTo';
}

class AnswerIncomingCall extends ActiveCallEvent {}

class EndCall extends ActiveCallEvent {}

class UpdateCallState extends ActiveCallEvent {
  final CallState callState;

  UpdateCallState({@required this.callState});

  @override
  List<Object> get props => [callState];

  @override
  String toString() => 'UpdateCallState: callState: $callState';
}

class HoldCall extends ActiveCallEvent {
  final bool doHold;

  HoldCall({@required this.doHold});

  @override
  List<Object> get props => [doHold];

  @override
  String toString() => 'HoldCall: doHold: $doHold';
}

class SendVideo extends ActiveCallEvent {
  final bool doSend;

  SendVideo({@required this.doSend});

  @override
  List<Object> get props => [doSend];

  @override
  String toString() => 'SendVideo: doSend: $doSend';
}

class SwitchCamera extends ActiveCallEvent {}
