/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:io';

import 'package:audio_call/screens/login/login.dart';
import 'package:audio_call/services/auth_service.dart';
import 'package:audio_call/utils/notification_helper.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService _authService = AuthService();

  LoginBloc() : super(LoginInitial()) {
    on<LoadLastUser>(_loadLastUser);
    on<LoginWithPassword>(_loginWithPassword);
  }

  Future<void> _loadLastUser(
      LoadLastUser event,
      Emitter<LoginState> emit) async {
    // TODO(yulia)
    // if (Platform.isAndroid &&
    //     await NotificationHelper().didNotificationLaunchApp()) {
    //   print('Launched from notification, skipping autologin');
    //   return;
    // }
    final lastUser = await _authService.getUsername();
    if (lastUser != null) {
      emit(LoginLastUserLoaded(lastUser: lastUser));
    }
    bool canUseAccessToken = await _authService.canUseAccessToken();
    if (canUseAccessToken) {
      emit(LoginInProgress());
      try {
        await _authService.loginWithAccessToken();
        emit(LoginSuccess());
      } on VIException catch (e) {
        emit(LoginFailure(errorCode: e.code, errorDescription: e.message ?? 'Unknown error'));
      }
    }
  }

  Future<void> _loginWithPassword(
      LoginWithPassword event,
      Emitter<LoginState> emit) async {
    emit(LoginInProgress());
    try {
      await _authService.loginWithPassword(
        '${event.username}.voximplant.com',
        event.password,
      );
      emit(LoginSuccess());
    } on VIException catch (e) {
      emit(LoginFailure(errorCode: e.code, errorDescription: e.message ?? 'Unknown error'));
    }
  }
}
