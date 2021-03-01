import Flutter
import PushKit
import CallKit
import flutter_callkit_voximplant
import flutter_voip_push_notification
import shared_preferences
import flutter_voximplant
import permission_handler

@UIApplicationMain
final class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Registering plugins manually, because on iOS FLTFirebaseMessagingPlugin and FlutterLocalNotificationsPlugin
        // are not used and should not be registered
        FlutterCallkitPlugin.register(with: registrar(forPlugin: "FlutterCallkitPlugin")!)
        FlutterVoipPushNotificationPlugin.register(with: registrar(forPlugin: "FlutterVoipPushNotificationPlugin")!)
        VoximplantPlugin.register(with: registrar(forPlugin: "VoximplantPlugin")!)
        PermissionHandlerPlugin.register(with: registrar(forPlugin: "PermissionHandlerPlugin")!)
        FLTSharedPreferencesPlugin.register(with: registrar(forPlugin: "FLTSharedPreferencesPlugin")!)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - PKPushRegistryDelegate -
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        FlutterVoipPushNotificationPlugin.didUpdate(pushCredentials, forType: type.rawValue)
    }
    
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType
    ) {
        processPush(with: payload, type: type, and: nil)
    }
    
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void
    ) {
        processPush(with: payload, type: type, and: completion)
    }
    
    private func processPush(with payload: PKPushPayload, type: PKPushType, and completion: (() -> Void)?) {
        print("Push received: \(payload)")
        
        FlutterVoipPushNotificationPlugin.didReceiveIncomingPush(with: payload, forType: type.rawValue)

        let callKitPlugin = FlutterCallkitPlugin.sharedInstance

        guard
            let content = payload.dictionaryPayload.content,
            UIApplication.shared.applicationState != .active,
            let callUUID = VoximplantPlugin.uuid(forPushNotification: payload.dictionaryPayload),
            !callKitPlugin.hasCall(with: callUUID)
        else {
            completion?()
            return
        }
        
        let callUpdate = CXCallUpdate()
        callUpdate.localizedCallerName = content.displayName
        callUpdate.remoteHandle = CXHandle(type: .generic, value: content.fullUsername)
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.supportsDTMF = false
        callUpdate.hasVideo = content.isVideoCall
        
        let configuration = CXProviderConfiguration(localizedName: "VideoCall")
        if #available(iOS 11.0, *) {
            configuration.includesCallsInRecents = true
        }
        configuration.supportsVideo = content.isVideoCall
        callKitPlugin.reportNewIncomingCall(
            with: callUUID,
            callUpdate: callUpdate,
            providerConfiguration: configuration,
            pushProcessingCompletion: completion
        )
    }
}

fileprivate extension Dictionary where Key == AnyHashable {
    var content: [String: Any]? {
        self["voximplant"] as? [String:Any]
    }
}

fileprivate extension Dictionary where Key == String {
    var displayName: String {
        self["display_name"] as! String
    }
    
    var fullUsername: String {
        self["userid"] as! String
    }
    
    var isVideoCall: Bool {
        self["video"] as! Bool
    }
}
