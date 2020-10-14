import Flutter
import PushKit
import flutter_voximplant
import flutter_voip_push_notification
import flutter_call_kit

@UIApplicationMain
final class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
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
        
        guard
            let content = payload.dictionaryPayload.content,
            UIApplication.shared.applicationState != .active,
            let callUUID = VoximplantPlugin.uuid(forPushNotification: payload.dictionaryPayload)?.uuidString.uppercased()
        else {
            completion?()
            return
        }
        
        FlutterCallKitPlugin.reportNewIncomingCall(
            callUUID,
            handle: content.fullUsername,
            handleType: "generic",
            hasVideo: false,
            localizedCallerName: content.displayName,
            fromPushKit: true
        )
        completion?()
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
