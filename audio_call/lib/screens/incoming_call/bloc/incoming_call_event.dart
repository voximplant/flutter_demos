/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

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

