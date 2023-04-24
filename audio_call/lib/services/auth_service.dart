/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'package:audio_call/main.dart';
import 'package:audio_call/utils/log.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Disconnected = void Function();

class AuthService {
  VIClient _client;
  String? _displayName;

  String? get displayName => _displayName;
  Disconnected? onDisconnected;

  String? _voipToken;
  set voipToken(token) {
    if (token == null || token == '') {
      _log('voip token cleared');
      final voipToken = _voipToken;
      if (voipToken != null) {
        _client.unregisterFromPushNotifications(voipToken);
      }
    }
    _voipToken = token;
  }

  VIClientState clientState = VIClientState.Disconnected;

  factory AuthService() {
    return _instance;
  }
  static final AuthService _instance = AuthService._();
  AuthService._() : _client = Voximplant().getClient(defaultConfig) {
    _log('initialize');
    _client.clientStateStream.listen((state) {
      clientState = state;
      _log('client state is changed to: $state');
      if (state == VIClientState.Disconnected && onDisconnected != null) {
        onDisconnected?.call();
      }
    });
  }

  Future<String> loginWithPassword(String username, String password) async {
    _log('loginWithPassword');
    VIClientState clientState = await _client.getClientState();
    if (clientState == VIClientState.LoggedIn) {
      final displayName = _displayName;
      if (displayName != null) {
        return displayName;
      }
    }
    if (clientState == VIClientState.Disconnected) {
      await _client.connect();
    }
    VIAuthResult authResult = await _client.login(username, password);
    if (_voipToken != null) {
      final voipToken = _voipToken;
      if (voipToken != null) {
        await _client.registerForPushNotifications(voipToken);
      }
    }
    await _saveAuthDetails(username, authResult.loginTokens);
    _displayName = authResult.displayName;
    return _displayName ?? "Unknown user";
  }

  Future<String?> loginWithAccessToken() async {
    VIClientState clientState = await _client.getClientState();
    if (clientState == VIClientState.LoggedIn) {
      return _displayName;
    } else if (clientState == VIClientState.Connecting ||
        clientState == VIClientState.LoggingIn) {
      return null;
    } else if (clientState == VIClientState.Disconnected) {
      await _client.connect();
    }
    _log('loginWithAccessToken');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final loginTokens = _getAuthDetails(prefs);
    String? user = prefs.getString('username');
    if (user != null && loginTokens != null) {
      VIAuthResult authResult = await _client.loginWithAccessToken(user, loginTokens.accessToken);
      await _saveAuthDetails(user, authResult.loginTokens);
      _displayName = authResult.displayName;
    }
    final voipToken = _voipToken;
    if (voipToken != null) {
      await _client.registerForPushNotifications(voipToken);
    }
    return _displayName;
  }

  Future<void> logout() async {
    _log('logout');
    await _client.disconnect();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    prefs.remove('accessToken');
    prefs.remove('refreshToken');
    prefs.remove('accessExpire');
    prefs.remove('refreshExpire');
  }

  Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username')?.replaceAll('.voximplant.com', '');
  }

  Future<bool> canUseAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken') != null;
  }

  Future<void> _saveAuthDetails(
      String username, VILoginTokens? loginTokens) async {
    if (loginTokens == null) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    prefs.setString('accessToken', loginTokens.accessToken);
    prefs.setString('refreshToken', loginTokens.refreshToken);
    prefs.setInt('accessExpire', loginTokens.accessExpire);
    prefs.setInt('refreshExpire', loginTokens.refreshExpire);
  }

  VILoginTokens? _getAuthDetails(SharedPreferences prefs) {
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');
    final refreshExpire = prefs.getInt('refreshExpire');
    final accessExpire = prefs.getInt('accessExpire');
    if (accessToken != null && refreshToken != null && refreshExpire != null && accessExpire != null) {
      VILoginTokens loginTokens = VILoginTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessExpire: accessExpire,
        refreshExpire: refreshExpire
      );
      return loginTokens;
    }
    return null;
  }

  Future<void> pushNotificationReceived(Map<String, dynamic> payload) async {
    _log('pushNotificationReceived');
    await _client.handlePushNotification(payload);
  }

  void _log<T>(T message) {
    log('AuthService($hashCode): ${message.toString()}');
  }
}
