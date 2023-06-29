/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:video_call/services/call/call_event.dart';
import 'package:video_call/services/call/call_service.dart';
import 'package:video_call/utils/permissions_helper.dart';

import 'incoming_call_event.dart';
import 'incoming_call_state.dart';

class IncomingCallBloc extends Bloc<IncomingCallEvent, IncomingCallState> {
  final CallService _callService = CallService();

  StreamSubscription? _callStateSubscription;

  IncomingCallBloc() : super(IncomingCallState.callIncoming) {
    _callStateSubscription =
        _callService.subscribeToCallEvents().listen(onCallEvent);
    on<CheckPermissions>(_checkPermissions);
    on<DeclineCall>(_declineCall);
    on<CallDisconnected>(_callDisconnected);
  }

  @override
  Future<void> close() {
    _callStateSubscription?.cancel();
    return super.close();
  }

  Future<void> _checkPermissions(
      CheckPermissions event, Emitter<IncomingCallState> emit) async {
    bool granted = await checkPermissions();
    if (granted) {
      emit(IncomingCallState.permissionsGranted);
    }
  }

  Future<void> _declineCall(
      DeclineCall event, Emitter<IncomingCallState> emit) async {
    await _callService.decline();
    emit(IncomingCallState.callCancelled);
  }

  Future<void> _callDisconnected(
      CallDisconnected event, Emitter<IncomingCallState> emit) async {
    emit(IncomingCallState.callCancelled);
  }

  void onCallEvent(CallEvent event) {
    if (event is OnDisconnectedCallEvent || event is OnFailedCallEvent) {
      add(CallDisconnected());
    }
  }
}
