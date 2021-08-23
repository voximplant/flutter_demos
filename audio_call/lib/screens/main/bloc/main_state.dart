/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class MainState extends Equatable {
  final String? myDisplayName;

  const MainState(this.myDisplayName);

  @override
  List<Object?> get props => [myDisplayName];

  @override
  bool get stringify => true;
}

class MainInitial extends MainState {
  const MainInitial({required String? myDisplayName}) : super(myDisplayName);
}

class PermissionCheckFail extends MainState {
  const PermissionCheckFail({required String? myDisplayName})
      : super(myDisplayName);
}

class PermissionCheckSuccess extends MainState {
  const PermissionCheckSuccess({required String? myDisplayName})
      : super(myDisplayName);
}

class LoggedOut extends MainState {
  final bool networkIssues;
  const LoggedOut({required this.networkIssues}) : super(null);
}

class IncomingCall extends MainState {
  final String caller;

  const IncomingCall({required this.caller, required String? myDisplayName})
      : super(myDisplayName);
}

class ReconnectSuccess extends MainState {
  const ReconnectSuccess({required String? myDisplayName})
      : super(myDisplayName);
}

class ReconnectFailed extends MainState {
  const ReconnectFailed() : super(null);
}
