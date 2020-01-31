/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

abstract class MakeCallEvent extends Equatable {
  const MakeCallEvent();

  @override
  List<Object> get props => [];
}

class CheckPermissionsForCall extends MakeCallEvent {}

class LogOut extends MakeCallEvent {}

class ReceivedIncomingCall extends MakeCallEvent {
  final String callId;
  final String caller;

  ReceivedIncomingCall({@required this.callId, @required this.caller});

  @override
  List<Object> get props => [callId, caller];
}

class ConnectionClosed extends MakeCallEvent {}

class Reconnect extends MakeCallEvent {}
