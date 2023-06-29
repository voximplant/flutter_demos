/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;
}

class LoginInitial extends LoginState {}

class LoginLastUserLoaded extends LoginState {
  final String lastUser;
  const LoginLastUserLoaded({required this.lastUser});

  @override
  List<Object> get props => [lastUser];
}

class LoginInProgress extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginFailure extends LoginState {
  final String errorCode;
  final String errorDescription;

  const LoginFailure({
    required this.errorCode,
    required this.errorDescription,
  });

  @override
  List<Object> get props => [errorCode, errorDescription];
}
