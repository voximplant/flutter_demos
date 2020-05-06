/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class MakeCallState extends Equatable {
  final String myDisplayName;

  const MakeCallState(this.myDisplayName);

  @override
  List<Object> get props => [myDisplayName];
}

class MakeCallInitial extends MakeCallState {
  const MakeCallInitial({@required String myDisplayName}) : super(myDisplayName);

  @override
  String toString() => 'OutgoingCallInitial: displayName: $myDisplayName';
}

class PermissionCheckFail extends MakeCallState {
  const PermissionCheckFail({@required String myDisplayName})
      : super(myDisplayName);
}

class PermissionCheckSuccess extends MakeCallState {
  const PermissionCheckSuccess({@required String myDisplayName})
      : super(myDisplayName);
}

class LoggedOut extends MakeCallState {
  final bool networkIssues;
  const LoggedOut({@required this.networkIssues}) : super(null);
}

class IncomingCall extends MakeCallState {
  final String caller;

  const IncomingCall({@required this.caller, @required String myDisplayName})
      : super(myDisplayName);
}

class ReconnectSuccess extends MakeCallState {
  const ReconnectSuccess({@required String myDisplayName}) : super(myDisplayName);
}

class ReconnectFailed extends MakeCallState {
  const ReconnectFailed() : super(null);
}