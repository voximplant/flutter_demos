import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

Future<bool> checkPermissions() async {
  if (Platform.isAndroid) {
    PermissionStatus recordAudio = await Permission.microphone.status;
    PermissionStatus camera = await Permission.camera.status;
    List<Permission> requestPermissions = List();
    if (recordAudio != PermissionStatus.granted) {
      requestPermissions.add(Permission.microphone);
    }
    if (camera != PermissionStatus.granted) {
      requestPermissions.add(Permission.camera);
    }
    if (requestPermissions.isEmpty) {
      return true;
    } else {
      Map<Permission, PermissionStatus> result =
          await requestPermissions.request();
      if (result[Permission.microphone] != PermissionStatus.granted ||
          result[Permission.camera] != PermissionStatus.granted) {
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