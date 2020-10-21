/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class MainEvent extends Equatable {
  const MainEvent();

  @override
  List<Object> get props => [];
}

class CheckPermissionsForCall extends MainEvent {}

class LogOut extends MainEvent {}

class ReceivedIncomingCall extends MainEvent {
  final String displayName;

  ReceivedIncomingCall({@required this.displayName});

  @override
  List<Object> get props => [displayName];
}

class ConnectionClosed extends MainEvent {}

class Reconnect extends MainEvent {}
