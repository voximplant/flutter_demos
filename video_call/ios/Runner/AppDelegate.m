#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <FlutterCallkitPlugin.h>
#import <VoximplantPlugin.h>
#import "FlutterVoipPushNotificationPlugin.h"
#import <PermissionHandlerPlugin.h>
#import <FLTSharedPreferencesPlugin.h>
#import <CallKit/CallKit.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Registering plugins manually, because on iOS FLTFirebaseMessagingPlugin and FlutterLocalNotificationsPlugin are not used and should not be registered
    [FlutterCallkitPlugin registerWithRegistrar:[self registrarForPlugin:@"FlutterCallkitPlugin"]];
    [FlutterVoipPushNotificationPlugin registerWithRegistrar:[self registrarForPlugin:@"FlutterVoipPushNotificationPlugin"]];
    [VoximplantPlugin registerWithRegistrar:[self registrarForPlugin:@"VoximplantPlugin"]];
    [PermissionHandlerPlugin registerWithRegistrar:[self registrarForPlugin:@"PermissionHandlerPlugin"]];
    [FLTSharedPreferencesPlugin registerWithRegistrar:[self registrarForPlugin:@"FLTSharedPreferencesPlugin"]];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

#pragma mark APNs and CallKit
- (void)pushRegistry:(nonnull PKPushRegistry *)registry didUpdatePushCredentials:(nonnull PKPushCredentials *)pushCredentials forType:(nonnull PKPushType)type {
    [FlutterVoipPushNotificationPlugin didUpdatePushCredentials:pushCredentials forType:(NSString *)type];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type {
    NSLog(@"%@ Push received: %@", type, payload);
    [FlutterVoipPushNotificationPlugin didReceiveIncomingPushWithPayload:payload forType:(NSString *)type];
    [self processPushWithPayload:payload.dictionaryPayload andCompletionHandler:nil];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion {
    NSLog(@"%@ Push received: %@", type, payload);
    [FlutterVoipPushNotificationPlugin didReceiveIncomingPushWithPayload:payload forType:(NSString *)type];
    [self processPushWithPayload:payload.dictionaryPayload andCompletionHandler:completion];
}

-(void)processPushWithPayload:(NSDictionary *)payload andCompletionHandler:(dispatch_block_t)completion {
    if (!payload[@"voximplant"]) {
        if (completion) {
            completion();
        }
        return;
    }
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        if (completion) {
            completion();
        }
        return;
    }

    NSUUID *callUUID = [VoximplantPlugin uuidForPushNotification:payload];
    if ([FlutterCallkitPlugin hasCallWithUUID:callUUID]) {
        if (completion) {
            completion();
        }
        return;
    }

    CXCallUpdate *callUpdate = [CXCallUpdate new];
    callUpdate.localizedCallerName = payload[@"voximplant"][@"display_name"];
    callUpdate.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric
                                                       value:payload[@"voximplant"][@"userid"]];
    callUpdate.supportsHolding = true;
    callUpdate.supportsGrouping = false;
    callUpdate.supportsUngrouping = false;
    callUpdate.supportsDTMF = false;
    callUpdate.hasVideo = payload[@"voximplant"][@"video"];

    CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"VideoCall"];
    if (@available(iOS 11.0, *)) {
        configuration.includesCallsInRecents = true;
    }
    configuration.supportsVideo = payload[@"voximplant"][@"video"];

    [FlutterCallkitPlugin reportNewIncomingCallWithUUID:callUUID
                                             callUpdate:callUpdate
                                  providerConfiguration:configuration
                               pushProcessingCompletion:completion];
}


@end
