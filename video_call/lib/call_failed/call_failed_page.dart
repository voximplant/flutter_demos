/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:video_call/routes.dart';
import 'package:video_call/theme/voximplant_theme.dart';
import 'package:video_call/widgets/widgets.dart';

import 'call_failed_page_arguments.dart';

class CallFailedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CallFailedPageArguments _arguments =
        ModalRoute.of(context).settings.arguments;

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
                      text: '${_arguments.endpoint}',
                      textColor: VoximplantColors.white,
                      fontSize: 30,
                      verticalPadding: 30,
                    ),
                    Widgets.textWithPadding(
                      text: '${_arguments.failureReason}',
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
                    Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.makeCall);
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
