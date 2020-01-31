/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class MakeCallState extends Equatable {
  final String displayName;

  const MakeCallState(this.displayName);

  @override
  List<Object> get props => [displayName];
}

class MakeCallInitial extends MakeCallState {
  const MakeCallInitial({@required String displayName}) : super(displayName);

  @override
  String toString() => 'OutgoingCallInitial: displayName: $displayName';
}

class PermissionCheckFail extends MakeCallState {
  const PermissionCheckFail({@required String displayName})
      : super(displayName);
}

class PermissionCheckSuccess extends MakeCallState {
  const PermissionCheckSuccess({@required String displayName})
      : super(displayName);
}

class LoggedOut extends MakeCallState {
  final bool networkIssues;
  const LoggedOut({@required this.networkIssues}) : super(null);
}

class IncomingCall extends MakeCallState {
  final String caller;
  const IncomingCall({@required this.caller}) : super(null);
}

class ReconnectSuccess extends MakeCallState {
  const ReconnectSuccess({@required String displayName}) : super(displayName);
}

class ReconnectFailed extends MakeCallState {
  const ReconnectFailed() : super(null);
}
