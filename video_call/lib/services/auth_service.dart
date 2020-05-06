/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_call/main.dart';

typedef void Disconnected();

class AuthService {
  VIClient _client;
  String _displayName;

  String get displayName => _displayName;
  Disconnected onDisconnected;

  String _voipToken;
  set voipToken(token) {
    if (token == null || token == '') {
      print('AuthService: token is cleared');
      _client.unregisterFromPushNotifications(_voipToken);
    }
    _voipToken = token;
  }

  VIClientState clientState;

  factory AuthService() => _cache ?? AuthService._();
  static AuthService _cache;
  AuthService._() : _client = Voximplant().getClient(defaultConfig) {
    _client.clientStateStream.listen((state) {
      clientState = state;
      print('AuthService: client state is changed: $state');

      if (state == VIClientState.Disconnected && onDisconnected != null) {
        onDisconnected();
      }
    });
    _cache = this;
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
    if (_voipToken != null) {
      await _client.registerForPushNotifications(_voipToken);
    }
    await _saveAuthDetails(username, authResult.loginTokens);
    _displayName = authResult.displayName;
    return _displayName;
  }

  Future<String> loginWithAccessToken([String username]) async {
    VIClientState clientState = await _client.getClientState();
    if (clientState == VIClientState.LoggedIn) {
      return _displayName;
    } else if (clientState == VIClientState.Connecting
        || clientState == VIClientState.LoggingIn) {
      return null;
    } else if (clientState == VIClientState.Disconnected) {
      await _client.connect();
    }
    print('AuthService: loginWithAccessToken');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    VILoginTokens loginTokens = _getAuthDetails(prefs);
    String user = username ?? prefs.getString('username');

    VIAuthResult authResult =
      await _client.loginWithAccessToken(user, loginTokens.accessToken);
    if (_voipToken != null) {
      await _client.registerForPushNotifications(_voipToken);
    }
    await _saveAuthDetails(user, authResult.loginTokens);
    _displayName = authResult.displayName;
    return _displayName;
  }

  Future<void> logout() async {
    await _client.disconnect();
    VILoginTokens loginTokens = VILoginTokens();
    _saveAuthDetails(null, loginTokens);
  }

  Future<String> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username')?.replaceAll('.voximplant.com', '');
  }

  Future<bool> canUseAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken') != null;
  }

  Future<void> _saveAuthDetails(
      String username, VILoginTokens loginTokens) async {
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
    await _client.handlePushNotification(payload);
  }
}