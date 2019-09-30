/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.

import 'package:audio_call/screens/incoming_call_screen.dart';
import 'package:audio_call/services/navigation_service.dart';
import 'package:audio_call/utils/screen_arguments.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:get_it/get_it.dart';

class CallService {
  Client _client;
  Call _call;

  static final CallService _singleton = CallService._();
  factory CallService() {
    return _singleton;
  }

  CallService._() {
    _client = Voximplant().getClient();
    _client.onIncomingCall = _onIncomingCall;
  }

  void notifyCallIsEnded(String callId) {
    if (_call?.callId == callId) {
      _call = null;
    }
  }

  Future<Call> makeAudioCall(String number) async {
     _call = await _client.call(number);
     print('CallService: created call: ${_call.callId}');
     return _call;
  }

  _onIncomingCall(Call call, Map<String, String> headers) async {
    if (_call != null) {
      await call.decline();
      return;
    }
    _call = call;
    GetIt locator = GetIt.instance;
    locator<NavigationService>().navigateTo(IncomingCallScreen.routeName,
        arguments: CallArguments(_call));
  }
}
