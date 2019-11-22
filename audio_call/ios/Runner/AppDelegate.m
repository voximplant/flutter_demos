#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

#include <flutter_voip_push_notification/FlutterVoipPushNotificationPlugin.h>
#include <flutter_call_kit/FlutterCallKitPlugin.h>
#include <flutter_voximplant/VoximplantPlugin.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

#pragma mark APNs and CallKit
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type {
    [FlutterVoipPushNotificationPlugin didUpdatePushCredentials:pushCredentials
                                                        forType:type];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type {
    [FlutterVoipPushNotificationPlugin didReceiveIncomingPushWithPayload:payload
                                                                 forType:type];


    if (!payload.dictionaryPayload[@"voximplant"]) return;

    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        NSString *callUUID = [VoximplantPlugin uuidForPushNotification:payload.dictionaryPayload].UUIDString.uppercaseString;
        NSString *callerName = payload.dictionaryPayload[@"voximplant"][@"display_name"];
        NSString *callId = payload.dictionaryPayload[@"voximplant"][@"callid"];


        [FlutterCallKitPlugin reportNewIncomingCall:callUUID
                                             handle:callId
                                         handleType:@"generic"
                                           hasVideo:NO
                                localizedCallerName:callerName
                                        fromPushKit:YES];
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion {
    [self pushRegistry:registry didReceiveIncomingPushWithPayload:payload forType:type];

    completion();
}


@end
