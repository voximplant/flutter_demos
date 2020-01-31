/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_call/active_call/active_call.dart';
import 'package:video_call/incoming_call/incoming_call.dart';
import 'package:video_call/routes.dart';
import 'package:video_call/widgets/widgets.dart';

import 'bloc/make_call_bloc.dart';
import 'bloc/make_call_event.dart';
import 'bloc/make_call_state.dart';

class MakeCallPage extends StatefulWidget {
  MakeCallPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MakeCallPageState();
  }
}

class _MakeCallPageState extends State<MakeCallPage> {
  final _callToController = TextEditingController();

  @override
  void dispose() {
    _callToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void _makeVideoCall() {
      BlocProvider.of<MakeCallBloc>(context).add(CheckPermissionsForCall());
    }

    void _logout() {
      BlocProvider.of<MakeCallBloc>(context).add(LogOut());
    }

    void _showPermissionCheckError() {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Permissions missing'),
            content: Text(
                'Please give "record audio" and "camera" permissions to make calls'),
            actions: <Widget>[
              FlatButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    }

    return BlocListener<MakeCallBloc, MakeCallState>(
      listener: (context, state) {
        if (state is LoggedOut) {
          if (state.networkIssues) {
            BlocProvider.of<MakeCallBloc>(context).add(Reconnect());
          } else {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          }
        }
        if (state is PermissionCheckSuccess) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.activeCall,
            arguments: ActiveCallPageArguments(
                isIncoming: false, callTo: _callToController.text),
          );
        }
        if (state is PermissionCheckFailed) {
          _showPermissionCheckError();
        }
        if (state is IncomingCall) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.incomingCall,
            arguments: IncomingCallPageArguments(caller: state.caller),
          );
        }
        if (state is ReconnectFailed) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      },
      child: BlocBuilder<MakeCallBloc, MakeCallState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Voximplant'),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.exit_to_app),
                  onPressed: _logout,
                )
              ],
            ),
            body: SafeArea(
              child: Stack(
                children: <Widget>[
                  Center(
                    child: Form(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Widgets.textFormField(
                              controller: _callToController,
                              darkBackground: false,
                              labelText: 'user or number'),
                          Widgets.maxWidthRaisedButton(
                            text: 'Video call',
                            onPressed: _makeVideoCall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Logged in as ${state.displayName}',
                      ),
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
