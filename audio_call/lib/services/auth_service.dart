/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:io';
import 'dart:convert';

import 'package:audio_call/services/call_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef void ConnectionClosed();

class AuthService {
  VIClient _client;
  String _displayName;

  String get displayName => _displayName;
  ConnectionClosed onConnectionClosed;

  String _voipToken;

  set pushToken(String newToken) {
    if (newToken == null || newToken == "") {
      print('AuthService: token is cleared');
      _client.unregisterFromPushNotifications(_voipToken);
    } else {
      print('AuthService: token is set');
      _client.registerForPushNotifications(newToken);
    }
    _voipToken = newToken;
  }

  static final AuthService _singleton = AuthService._();

  factory AuthService() {
    return _singleton;
  }

  AuthService._() {
    _client = Voximplant().getClient();
    CallService().client = _client;
    _client.clientStateStream.listen((state) {
      print('AuthService: client state is changed: $state');
      if (state == VIClientState.Disconnected && onConnectionClosed != null) {
        onConnectionClosed();
      }
    });
  }

  Future<String> loginWithPassword(String username, String password) async {
    print('AuthService: loginWithPassword');
    VIClientState clientState = await _client.getClientState();
    if (clientState == VIClientState.LoggedIn) {
      return _displayName;
    }
    if (clientState == VIClientState.Disconnected) {
      await _client.connect();
    }
    VIAuthResult authResult = await _client.login(username, password);
    await _saveAuthDetails(username, authResult.loginTokens);
    _displayName = authResult.displayName;
    return _displayName;
  }

  Future<String> loginWithAccessToken([String username]) async {
    print('AuthService: loginWithAccessToken');
    VIClientState clientState = await _client.getClientState();
    if (clientState == VIClientState.LoggedIn) {
      return _displayName;
    }
    if (clientState == VIClientState.Disconnected) {
      await _client.connect();
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    VILoginTokens loginTokens = _getAuthDetails(prefs);
    String user = username ?? prefs.getString('username');

    VIAuthResult authResult =
        await _client.loginWithAccessToken(user, loginTokens.accessToken);
    await _saveAuthDetails(user, authResult.loginTokens);
    _displayName = authResult.displayName;
    return _displayName;
  }

  Future<void> logout() async {
    return await _client.disconnect();
  }

  Future<String> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username')?.replaceAll('.voximplant.com', '');
  }

  Future<void> _saveAuthDetails(String username,
      VILoginTokens loginTokens) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    prefs.setString('accessToken', loginTokens.accessToken);
    prefs.setString('refreshToken', loginTokens.refreshToken);
    prefs.setInt('accessExpire', loginTokens.accessExpire);
    prefs.setInt('refreshExpire', loginTokens.refreshExpire);
  }

  VILoginTokens _getAuthDetails(SharedPreferences prefs) {
    VILoginTokens loginTokens = VILoginTokens();
    loginTokens.accessToken = prefs.getString('accessToken');
    loginTokens.accessExpire = prefs.getInt('accessExpire');
    loginTokens.refreshExpire = prefs.getInt('refreshExpire');
    loginTokens.refreshToken = prefs.getString('refreshToken');

    return loginTokens;
  }

  Future<void> pushNotificationReceived(Map<String, dynamic> payload) async {
    await loginWithAccessToken();
    await _client.handlePushNotification(payload);
  }
}
