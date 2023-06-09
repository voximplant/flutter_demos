import UIKit
import Flutter
import PushKit
import flutter_callkit_voximplant
import flutter_voximplant

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
    private let voipRegistry: PKPushRegistry = PKPushRegistry(queue: .main)
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        PushKitPlugin.register(with: self.registrar(forPlugin: "PushKitPlugin")!)
        
        PushKitPlugin.shared.setPKPushRegistry(voipRegistry)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        PushKitPlugin.shared.updatePushCredentials(pushCredentials, for: type)
    }
    
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        processPush(with: payload, type: type, and: completion)
    }
    
    private func processPush(with payload: PKPushPayload, type: PKPushType, and completion: (() -> Void)?) {
        print("Push received: \(payload)")
    
        PushKitPlugin.shared.reportIncomingPushWith(payload: payload, for: type)
        
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
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.supportsDTMF = false
        callUpdate.hasVideo = false
        
        let configuration = CXProviderConfiguration(localizedName: "VideoCall")
        if #available(iOS 11.0, *) {
            configuration.includesCallsInRecents = true
        }
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
}

class PushKitPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    static let shared = PushKitPlugin()
    private var pushKitEventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var voipRegistry: PKPushRegistry?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        print("YULIA: register")
        let channel = FlutterMethodChannel(name: "plugins.voximplant.com/pushkit", binaryMessenger: registrar.messenger())
        let instance = PushKitPlugin.shared
        instance.setup(with: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private override init() {
        super.init()
    }
    
    private func setup(with registrar: FlutterPluginRegistrar) {
        pushKitEventChannel = FlutterEventChannel(name: "plugins.voximplant.com/pushkitevents", binaryMessenger: registrar.messenger())
        pushKitEventChannel?.setStreamHandler(self)
    }
    
    public func setPKPushRegistry(_ registry: PKPushRegistry) {
        self.voipRegistry = registry
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "voipToken") {
            guard let voipToken = voipRegistry?.pushToken(for: .voIP) else {
                result(nil)
                return
            }
            let token = convertTokenToString(data: voipToken)
            result(token)
        }
    }
    
    public func updatePushCredentials(_ pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard let eventSink = self.eventSink else {
            print("[PushKitPlugin]: updatePushCredentials: eventSink is not initialized")
            return
        }
        let token = self.convertTokenToString(data: pushCredentials.token)
        eventSink(["event": "didUpdatePushCredentials", "token": token])
    }
    
    public func reportIncomingPushWith(payload: PKPushPayload, for type: PKPushType) {
        guard let eventSink = self.eventSink else {
            print("[PushKitPlugin]: reportIncomingPushWith: eventSink is not initialized")
            return
        }
        eventSink(["event": "didReceiveIncomingPushWithPayload",
                   "payload": payload.dictionaryPayload] as [String : Any])
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if let type = arguments as? String {
            if (type == "pushkit") {
                self.eventSink = events
            }
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let type = arguments as? String {
            if (type == "pushkit") {
                self.eventSink = nil
            }
        }
        return nil
    }
    
    private func convertTokenToString(data: Data) -> String {
        return data.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
