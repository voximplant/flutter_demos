/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.

import 'package:audio_call/utils/screen_arguments.dart';
import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName, {CallArguments arguments}) {
    return navigatorKey.currentState.pushReplacementNamed(routeName, arguments: arguments);
  }
}
