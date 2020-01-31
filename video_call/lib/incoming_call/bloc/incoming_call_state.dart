/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:equatable/equatable.dart';

abstract class IncomingCallState extends Equatable {
  const IncomingCallState();

  @override
  List<Object> get props => [];
}

class IncomingCallInitial extends IncomingCallState {}

class PermissionCheckFailed extends IncomingCallState {}

class PermissionCheckPass extends IncomingCallState {}

class CallHasEnded extends IncomingCallState {}
