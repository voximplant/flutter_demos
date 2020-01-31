/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.


import 'package:flutter_voximplant/flutter_voximplant.dart';

class CallArguments {
  VICall call;
  String displayName;
  String callId;

  CallArguments.withCall(this.call);
  CallArguments.withDisplayName(this.displayName);
  CallArguments.withCallId(this.callId);
}
