/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

enum AppState {
  NotLaunched,
  Background,
  Foreground
}

class AppStateHelper {
  static final AppStateHelper _instance = AppStateHelper._();

  factory AppStateHelper() {
    return _instance;
  }

  AppStateHelper._();

  AppState _appState = AppState.NotLaunched;

  AppState get appState => _appState;
  set appState(AppState state) {
    print('AppStateHelper: application is active: $state');
    _appState = state;
  }

}
