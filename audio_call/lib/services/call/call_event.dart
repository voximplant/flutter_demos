/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/foundation.dart';

abstract class CallEvent { }

class OnIncomingCallEvent implements CallEvent {
  final String username;
  final String displayName;

  OnIncomingCallEvent({
    required this.username,
    required this.displayName,
  });
}

class OnRingingCallEvent implements CallEvent { }

class OnConnectedCallEvent implements CallEvent {
  final String username;
  final String displayName;

  OnConnectedCallEvent({
    required this.username,
    required this.displayName,
  });
}

class OnDisconnectedCallEvent implements CallEvent {
  final bool answeredElsewhere;

  OnDisconnectedCallEvent({
    required this.answeredElsewhere,
  });
}

class OnFailedCallEvent implements CallEvent {
  final String reason;

  OnFailedCallEvent({
    required this.reason,
  });
}

class OnHoldCallEvent implements CallEvent {
  final bool hold;

  OnHoldCallEvent({
    required this.hold,
  });
}

class OnMuteCallEvent implements CallEvent {
  final bool muted;

  OnMuteCallEvent({
    required this.muted,
  });
}
