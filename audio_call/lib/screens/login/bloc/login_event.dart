// Copyright (c) 2011 - 2026, Voximplant, Inc. All rights reserved.

import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();
  @override
  List<Object> get props => [];
}

class LoadLastUser extends LoginEvent {}

class LoginWithPassword extends LoginEvent {
  final String username;
  final String password;
  final String node;

  const LoginWithPassword(
      {required this.username, required this.password, required this.node});

  @override
  List<Object> get props => [username, password, node];

  @override
  String toString() => 'LoginWithPassword: '
      'username: $username, password: *****';
}

class Dispose extends LoginEvent {}
