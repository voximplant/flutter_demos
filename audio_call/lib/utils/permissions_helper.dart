/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkPermissions() async {
  if (Platform.isAndroid) {
    PermissionStatus recordAudio = await Permission.microphone.status;
    List<Permission> requestPermissions = [];
    if (recordAudio != PermissionStatus.granted) {
      requestPermissions.add(Permission.microphone);
    }
    if (requestPermissions.isEmpty) {
      return true;
    } else {
      Map<Permission, PermissionStatus> result =
      await requestPermissions.request();
      if (result[Permission.microphone] != PermissionStatus.granted) {
        return false;
      } else {
        return true;
      }
    }
  } else if (Platform.isIOS) {
    return true;
  } else {
    //not supported platforms
    return false;
  }
}
