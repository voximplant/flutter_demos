/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:io';

import 'package:audio_call/screens/active_call/active_call.dart';
import 'package:audio_call/screens/incoming_call/incoming_call_page_arguments.dart';
import 'package:audio_call/utils/navigation_helper.dart';
import 'package:audio_call/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/main_bloc.dart';
import 'bloc/main_event.dart';
import 'bloc/main_state.dart';

class MainPage extends StatefulWidget {
  static const routeName = '/main';

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  late MainBloc _bloc;

  final _callToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<MainBloc>(context);
    //TODO(yulia): check force unwrap
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    _callToController.dispose();
    //TODO(yulia): check force unwrap
    WidgetsBinding.instance!.removeObserver(this);
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
    void _makeCall() {
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
            content:
                Text('Please give "record audio" permissions to make calls'),
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

    return BlocListener<MainBloc, MainState>(
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
              endpoint: _callToController.text,
            ),
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
      child: BlocBuilder<MainBloc, MainState>(
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
                            text: 'Call',
                            onPressed: _makeCall,
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
                        state.myDisplayName != null &&
                                state.myDisplayName!.isNotEmpty
                            ? 'Logged in as ${state.myDisplayName}'
                            : '',
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
