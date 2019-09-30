/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.

import 'dart:io';

import 'package:audio_call/screens/call_screen.dart';
import 'package:audio_call/screens/login_screen.dart';
import 'package:audio_call/services/auth_service.dart';
import 'package:audio_call/services/call_service.dart';
import 'package:audio_call/services/navigation_service.dart';
import 'package:audio_call/utils/screen_arguments.dart';
import 'package:flutter/material.dart';

import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

class MainScreen extends StatelessWidget {
  static const routeName = '/mainScreen';

  final AuthService _authService = AuthService();
  final CallService _callService = CallService();
  final TextEditingController _callToController = TextEditingController();
  String _displayName;

  MainScreen({Key key}) : super(key: key) {
    _authService.onConnectionClosed = _onConnectionClosed;
    _displayName = _authService.displayName;

  }

  void _onConnectionClosed() {
    print('MainScreen: onConnectionClosed');
    GetIt locator = GetIt.instance;
    locator<NavigationService>().navigateTo(LoginScreen.routeName);
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  Future<void> _makeAudioCall(BuildContext context, String number) async {
    if (Platform.isAndroid) {
      PermissionStatus permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.microphone);
      if (permission != PermissionStatus.granted) {
        Map<PermissionGroup,
            PermissionStatus> result = await PermissionHandler()
            .requestPermissions([PermissionGroup.microphone]);
        if (result[PermissionGroup.microphone] != PermissionStatus.granted) {
          return;
        }
      }
    }
    Call call = await _callService.makeAudioCall(number);
    Navigator.pushReplacementNamed(
        context,
        CallScreen.routeName,
        arguments: CallArguments(call));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MainScreen'),
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 1) {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 1,
                  child: Text('Log out'),
                )
              ];
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Text(
                'Logged in as $_displayName',
                style: TextStyle(
                  fontSize: 20
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'CALL TO',
                ),
                autocorrect: false,
                controller: _callToController,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: FlatButton(
                onPressed: () {
                  _makeAudioCall(context, _callToController.text);
                },
                child: Text(
                  'CALL',
                  style: TextStyle(fontSize: 20, color: VoximplantColors.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
