// Copyright (c) 2011 - 2026, Voximplant, Inc. All rights reserved.

abstract class IncomingCallEvent {}

class CheckPermissions implements IncomingCallEvent {
  CheckPermissions();
}

class DeclineCall implements IncomingCallEvent {
  DeclineCall();
}

class CallDisconnected implements IncomingCallEvent {
  CallDisconnected();
}

