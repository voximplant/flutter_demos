/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:flutter/foundation.dart';

class CallFailedPageArguments {
  final String failureReason;
  final String endpoint;

  CallFailedPageArguments({
    required this.failureReason,
    required this.endpoint,
  });
}
