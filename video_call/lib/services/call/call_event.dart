abstract class CallEvent { }

class OnRingingCallEvent implements CallEvent { }
class OnConnectedCallEvent implements CallEvent {
  final String username;
  final String displayName;
  OnConnectedCallEvent(this.username, this.displayName);
}
class OnDisconnectedCallEvent implements CallEvent {
  final bool answeredElsewhere;
  OnDisconnectedCallEvent(this.answeredElsewhere);
}
class OnFailedCallEvent implements CallEvent {
  final String reason;
  OnFailedCallEvent(this.reason);
}
class OnChangedLocalVideoCallEvent implements CallEvent {
  final String id;
  OnChangedLocalVideoCallEvent(this.id);
}
class OnChangedRemoteVideoCallEvent implements CallEvent {
  final String id;
  OnChangedRemoteVideoCallEvent(this.id);
}

class OnHoldCallEvent implements CallEvent {
  final bool isOnHold;
  OnHoldCallEvent(this.isOnHold);
}

class OnMuteCallEvent implements CallEvent {
  final bool isMuted;
  OnMuteCallEvent(this.isMuted);
}