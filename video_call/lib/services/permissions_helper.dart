import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkPermissions() async {
  if (Platform.isAndroid) {
    PermissionStatus recordAudio = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.microphone);
    PermissionStatus camera = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.camera);
    List<PermissionGroup> requestPermissions = List();
    if (recordAudio != PermissionStatus.granted) {
      requestPermissions.add(PermissionGroup.microphone);
    }
    if (camera != PermissionStatus.granted) {
      requestPermissions.add(PermissionGroup.camera);
    }
    if (requestPermissions.isEmpty) {
      return true;
    } else {
      Map<PermissionGroup, PermissionStatus> result =
      await PermissionHandler().requestPermissions(requestPermissions);
      if (result[PermissionGroup.microphone] != PermissionStatus.granted ||
          result[PermissionGroup.camera] != PermissionStatus.granted) {
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