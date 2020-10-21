/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:audio_call/screens/call_failed/call_failed_page_arguments.dart';
import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:audio_call/utils/navigation_helper.dart';
import 'package:audio_call/widgets/widgets.dart';
import 'package:flutter/material.dart';

class CallFailedPage extends StatelessWidget {
  static const routeName = '/callFailed';

  final String _failureReason;
  final String _endpoint;

  CallFailedPage(CallFailedPageArguments arguments)
      : _failureReason = arguments.failureReason,
        _endpoint = arguments.endpoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoximplantColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                child: Column(
                  children: <Widget>[
                    Widgets.textWithPadding(
                      text: 'Call failed',
                      textColor: VoximplantColors.white,
                      fontSize: 40,
                    ),
                    Widgets.textWithPadding(
                      text: _endpoint,
                      textColor: VoximplantColors.white,
                      fontSize: 30,
                      verticalPadding: 30,
                    ),
                    Widgets.textWithPadding(
                      text: _failureReason,
                      textColor: VoximplantColors.white,
                      fontSize: 25,
                    ),
                  ],
                ),
              ),
              Widgets.iconButton(
                icon: Icons.close,
                color: VoximplantColors.button,
                tooltip: 'Close',
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.main);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
