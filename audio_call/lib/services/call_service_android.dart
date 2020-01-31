/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:audio_call/screens/incoming_call_screen.dart';
import 'package:audio_call/services/call_service.dart';
import 'package:audio_call/utils/app_state_helper.dart';
import 'package:audio_call/utils/notifications_android.dart';
import 'package:audio_call/utils/screen_arguments.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:get_it/get_it.dart';

import 'navigation_service.dart';

class CallServiceAndroid extends CallService {
  CallServiceAndroid() : super.ctr();

  @override
  onIncomingCall(VIClient client, VICall call, bool video,
      Map<String, String> headers) async {
    print('CallServiceAndroid: onIncomingCall(${call.callId})');
    super.onIncomingCall(client, call, video, headers);

    if (AppStateHelper().appState == AppState.Foreground) {
      print(
          'CallServiceAndroid: onIncomingCall: navifate to Incoming call screen');
      GetIt locator = GetIt.instance;
      locator<NavigationService>().navigateTo(IncomingCallScreen.routeName,
          arguments: CallArguments.withDisplayName(
              this.call.endpoints.first.displayName));
    } else {
      print('CallServiceAndroid: onIncomingCall: show call notification');
      NotificationsAndroid.showCallNotification(
          this.call.endpoints.first.displayName);
    }
  }
}
