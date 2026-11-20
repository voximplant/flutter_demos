// Copyright (c) 2011 - 2026, Voximplant, Inc. All rights reserved.

import 'package:audio_call/screens/active_call/active_call.dart';
import 'package:audio_call/screens/incoming_call/incoming_call.dart';
import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:audio_call/utils/navigation_helper.dart';
import 'package:audio_call/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IncomingCallPage extends StatefulWidget {
  static const routeName = '/incomingCall';

  final String _endpoint;

  IncomingCallPage({
    required IncomingCallPageArguments arguments,
    super.key,
  }) : _endpoint = arguments.endpoint;

  @override
  State<StatefulWidget> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  late IncomingCallBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<IncomingCallBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    void answerCall() => _bloc.add(CheckPermissions());

    void declineCall() => _bloc.add(DeclineCall());

    return BlocListener<IncomingCallBloc, IncomingCallState>(
      listener: (context, state) {
        if (state == IncomingCallState.callCancelled) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.main);
        } else if (state == IncomingCallState.permissionsGranted) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.activeCall,
            arguments: ActiveCallPageArguments(
              isIncoming: true,
              endpoint: widget._endpoint,
            ),
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
                    verticalPadding: 20,
                  ),
                  Widgets.textWithPadding(
                    text: widget._endpoint,
                    textColor: VoximplantColors.white,
                    fontSize: 25,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Widgets.iconButton(
                          icon: Icons.call,
                          color: VoximplantColors.button,
                          tooltip: 'Answer',
                          onPressed: answerCall,
                        ),
                        Widgets.iconButton(
                          icon: Icons.call_end,
                          color: VoximplantColors.red,
                          tooltip: 'Decline',
                          onPressed: declineCall,
                        )
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
