/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_call/active_call/active_call.dart';
import 'package:video_call/incoming_call/incoming_call.dart';
import 'package:video_call/routes.dart';
import 'package:video_call/theme/voximplant_theme.dart';
import 'package:video_call/widgets/widgets.dart';

import 'bloc/incoming_call_bloc.dart';

class IncomingCallPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _IncomingCallPageState();
  }
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  void _answerCall() {
    BlocProvider.of<IncomingCallBloc>(context).add(CheckPermissions());
  }

  void _declineCall() {
    BlocProvider.of<IncomingCallBloc>(context).add(DeclineCall());
  }

  @override
  Widget build(BuildContext context) {
    final IncomingCallPageArguments _arguments =
        ModalRoute.of(context).settings.arguments;

    return BlocListener<IncomingCallBloc, IncomingCallState>(
      listener: (context, state) {
        if (state is CallHasEnded) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.makeCall);
        }
        if (state is PermissionCheckPass) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.activeCall,
            arguments: ActiveCallPageArguments(isIncoming: true),
          );
        }
      },
      child: BlocBuilder<IncomingCallBloc, IncomingCallState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: VoximplantColors.primaryDark,
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Widgets.textWithPadding(
                    text: 'Incoming call from',
                    textColor: VoximplantColors.white,
                    fontSize: 30,
                    verticalPadding: 20,
                  ),
                  Widgets.textWithPadding(
                    text: '${_arguments.caller}',
                    textColor: VoximplantColors.white,
                    fontSize: 25,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Widgets.iconButton(
                            icon: Icons.call,
                            color: VoximplantColors.button,
                            tooltip: 'Answer',
                            onPressed: _answerCall),
                        Widgets.iconButton(
                            icon: Icons.call_end,
                            color: VoximplantColors.red,
                            tooltip: 'Decline',
                            onPressed: _declineCall)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
