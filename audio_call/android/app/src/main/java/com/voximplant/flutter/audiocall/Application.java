package com.voximplant.flutter.audiocall;

import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin;
import com.example.flutter_voip_push_notification.FlutterVoipPushNotificationPlugin;

import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin;
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService;
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin;

public class Application extends FlutterApplication implements PluginRegistry.PluginRegistrantCallback {
    @Override
    public void onCreate() {
        super.onCreate();
        FlutterFirebaseMessagingService.setPluginRegistrant(this);
    }

    @Override
    public void registerWith(PluginRegistry registry) {
        FlutterVoipPushNotificationPlugin.registerWith(registry.registrarFor("com.example.flutter_voip_push_notification.FlutterVoipPushNotificationPlugin"));
        com.voximplant.flutter_voximplant.VoximplantPlugin.registerWith(registry.registrarFor("com.voximplant.flutter_voximplant.VoximplantPlugin"));
        com.baseflow.permissionhandler.PermissionHandlerPlugin.registerWith(registry.registrarFor("com.baseflow.permissionhandler.PermissionHandlerPlugin"));
        FlutterLocalNotificationsPlugin.registerWith(registry.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"));
        SharedPreferencesPlugin.registerWith(registry.registrarFor("io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin"));
        FirebaseMessagingPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
    }
}
