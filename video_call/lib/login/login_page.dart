/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:video_call/login/login.dart';
import 'package:video_call/theme/voximplant_theme.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoximplantColors.primary,
      body:  SafeArea(
        child: LoginForm(),
      ),
    );
  }
}
