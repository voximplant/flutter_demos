/// Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.


import 'package:flutter_voximplant/flutter_voximplant.dart';

class CallArguments {
  Call call;
  String displayName;
  String callId;

  CallArguments.withCall(this.call);
  CallArguments.withDisplayName(this.displayName);
  CallArguments.withCallId(this.callId);
}
