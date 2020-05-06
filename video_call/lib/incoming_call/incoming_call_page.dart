/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_call/active_call/active_call.dart';
import 'package:video_call/incoming_call/incoming_call.dart';
import 'package:video_call/services/navigation_helper.dart';
import 'package:video_call/theme/voximplant_theme.dart';
import 'package:video_call/widgets/widgets.dart';

import 'bloc/incoming_call_bloc.dart';

class IncomingCallPage extends StatefulWidget {
  static const routeName = '/incomingCall';

  final String _endpoint;

  IncomingCallPage({@required IncomingCallPageArguments arguments})
      : _endpoint = arguments.endpoint;

  @override
  State<StatefulWidget> createState() => _IncomingCallPageState(_endpoint);
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  final String _endpoint;

  IncomingCallBloc _bloc;

  @override
  void initState() {
  super.initState();
      _bloc = BlocProvider.of<IncomingCallBloc>(context);
  }
  _IncomingCallPageState(this._endpoint);

  @override
  Widget build(BuildContext context) {
    void _answerCall() => _bloc.add(IncomingCallEvent.checkPermissions);

    void _declineCall() => _bloc.add(IncomingCallEvent.declineCall);

    return BlocListener<IncomingCallBloc, IncomingCallState>(
      listener: (context, state) {
        if (state == IncomingCallState.callCancelled) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.makeCall);
        } else if (state == IncomingCallState.permissionsGranted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.activeCall,
              arguments: ActiveCallPageArguments(
                  isIncoming: true,
                  endpoint: _endpoint));
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
                    text: _endpoint,
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
