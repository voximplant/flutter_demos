/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'package:flutter/cupertino.dart';

class ActiveCallPageArguments {
  String endpoint;
  bool isIncoming;

  ActiveCallPageArguments({
    @required this.endpoint,
    @required this.isIncoming,
  });
}
