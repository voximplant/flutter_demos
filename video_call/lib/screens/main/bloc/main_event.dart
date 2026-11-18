// Copyright (c) 2011 - 2026, Voximplant, Inc. All rights reserved.

import 'package:equatable/equatable.dart';

abstract class MainEvent extends Equatable {
  const MainEvent();

  @override
  List<Object> get props => [];
}

class CheckPermissionsForCall extends MainEvent {}

class LogOut extends MainEvent {}

class ReceivedIncomingCall extends MainEvent {
  final String displayName;

  ReceivedIncomingCall({required this.displayName});

  @override
  List<Object> get props => [displayName];
}

class ConnectionClosed extends MainEvent {}

class Reconnect extends MainEvent {}
