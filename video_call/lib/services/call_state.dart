/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:meta/meta.dart';

abstract class CallState {
  const CallState();
}

class CallStateRinging extends CallState {}

class CallStateConnected extends CallState {}

class CallStateFailed extends CallState {
  final String errorDescription;
  final String endpoint;
  const CallStateFailed(
      {@required this.errorDescription, @required this.endpoint});
}

class CallStateVideoStreamAdded extends CallState {
  final String streamId;
  final bool isLocal;
  CallStateVideoStreamAdded({@required this.streamId, @required this.isLocal});
}

class CallStateVideoStreamRemoved extends CallState {
  final String streamId;
  final bool isLocal;
  CallStateVideoStreamRemoved(
      {@required this.streamId, @required this.isLocal});
}

class CallStateDisconnected extends CallState {}
