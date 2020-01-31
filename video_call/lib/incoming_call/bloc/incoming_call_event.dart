/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:equatable/equatable.dart';

abstract class IncomingCallEvent extends Equatable {
  const IncomingCallEvent();

  @override
  List<Object> get props => [];
}

class Load extends IncomingCallEvent {}

class CheckPermissions extends IncomingCallEvent {}

class DeclineCall extends IncomingCallEvent {}

class IncomingCallDisconnected extends IncomingCallEvent {}
