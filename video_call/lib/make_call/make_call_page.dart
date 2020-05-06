/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_call/active_call/active_call.dart';
import 'package:video_call/incoming_call/incoming_call.dart';
import 'package:video_call/services/navigation_helper.dart';
import 'package:video_call/widgets/widgets.dart';

import 'bloc/make_call_bloc.dart';
import 'bloc/make_call_event.dart';
import 'bloc/make_call_state.dart';

class MakeCallPage extends StatefulWidget {
  static const routeName = '/makeCall';

  @override
  State<StatefulWidget> createState() => _MakeCallPageState();
}

class _MakeCallPageState extends State<MakeCallPage>
    with WidgetsBindingObserver {
  MakeCallBloc _bloc;

  final _callToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<MakeCallBloc>(context);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _callToController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isInactive = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused && Platform.isIOS) {
      _isInactive = true;
    }

    if (state == AppLifecycleState.resumed && Platform.isIOS) {
      if (_isInactive) {
        _bloc.add(Reconnect());
        _isInactive = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    void _makeVideoCall() {
      if (_callToController.text == '') {
        return;
      }
      _bloc.add(CheckPermissionsForCall());
    }

    void _logout() => _bloc.add(LogOut());

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
            if (!_isInactive) {
              _bloc.add(Reconnect());
            }
          } else {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          }
        }
        if (state is PermissionCheckSuccess) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.activeCall,
            arguments: ActiveCallPageArguments(
                isIncoming: false,
                endpoint: _callToController.text),
          );
        }
        if (state is PermissionCheckFail) {
          _showPermissionCheckError();
        }
        if (state is IncomingCall) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.incomingCall,
            arguments: IncomingCallPageArguments(endpoint: state.caller),
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
                        'Logged in as ${state.myDisplayName}',
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
