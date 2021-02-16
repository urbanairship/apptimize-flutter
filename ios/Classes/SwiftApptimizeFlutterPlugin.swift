import Flutter
import UIKit
import Apptimize

enum PluginError : Error {
    case invalidArgument(msg: String?)
    
    public func toFlutterError() -> FlutterError {
        switch self {
        case .invalidArgument(let m):
            return FlutterError(code: "INVALID_ARGUMENT", message: m, details: nil)
        }
    }
}

class ApptimizeVariableDoesNotExist : Error {}

public class SwiftApptimizeFlutterPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel! = nil

    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "apptimize_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftApptimizeFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Register for all notifications here. Fire them over to flutter and let it
        // handle the dispatch.
        let nc = NotificationCenter.default
        nc.addObserver(forName: NSNotification.Name.ApptimizeInitialized, object: nil, queue: nil) { (_) in
            channel.invokeMethod("ApptimizeInitialized", arguments: nil, result: nil)
        }
        
        nc.addObserver(forName: NSNotification.Name.ApptimizeResumed, object: nil, queue: nil) { (e) in
            guard let notification = e.userInfo else {
                return
            }
            let arguments = [
                "willRefreshMetadata": notification[ApptimizeWillRefreshMetadataKey]
            ]
            channel.invokeMethod("ApptimizeResumed", arguments: arguments, result: nil)
        }

        nc.addObserver(forName: NSNotification.Name.ApptimizeMetadataStateChanged, object: nil, queue: nil) { (e) in
            guard let notification = e.userInfo,
                  let metadataStateNumber = notification[ApptimizeMetadataStateFlagsKey] as? NSNumber
                  else {
                return
            }
            let metadataState = ApptimizeMetadataStateFlags(rawValue: metadataStateNumber.intValue)
            let arguments = [
                "isAvailable": metadataState.contains(.available),
                "isUpToDate": metadataState.contains(.upToDate),
                "isRefreshing": metadataState.contains(.refreshing)
            ]
            channel.invokeMethod("ApptimizeMetadataStateChanged", arguments: arguments, result: nil)
        }

        nc.addObserver(forName: NSNotification.Name.ApptimizeTestsProcessed, object: nil, queue: nil) { (_) in
            channel.invokeMethod("ApptimizeTestsProcessed", arguments: nil, result: nil)
        }

        nc.addObserver(forName: NSNotification.Name.ApptimizeEnrolledInExperiment, object: nil, queue: nil) { (e) in
            guard let notification = e.userInfo,
                  let testInfo = notification[ApptimizeTestInfoKey] as? ApptimizeTestInfo else {
                return
            }
            let arguments = [
                "testInfo": testInfo.serializeForFlutter()
            ] as [String : Any]
            channel.invokeMethod("ApptimizeEnrolledInExperiment", arguments: arguments, result: nil)
        }

        nc.addObserver(forName: NSNotification.Name.ApptimizeUnenrolledInExperiment, object: nil, queue: nil) { (e) in
            guard let notification = e.userInfo,
                  let testInfo = notification[ApptimizeTestInfoKey] as? ApptimizeTestInfo,
                  let unenrollmentReasonId = notification[ApptimizeUnenrollmentReasonKey] as? NSNumber,
                  let unenrollmentReason = UnenrollmentReason(rawValue: unenrollmentReasonId.intValue) else {
                return
            }
            let arguments = [
                "unenrollmentReason": unenrollmentReason.serializeForFlutter(),
                "testInfo": testInfo.serializeForFlutter()
            ] as [String : Any]
            channel.invokeMethod("ApptimizeUnenrolledInExperiment", arguments: arguments, result: nil)
        }

        nc.addObserver(forName: NSNotification.Name.ApptimizeParticipatedInExperiment, object: nil, queue: nil) { (e) in
            guard let notification = e.userInfo,
                  let testInfo = notification[ApptimizeTestInfoKey] as? ApptimizeTestInfo,
                  let firstParticipation = notification[ApptimizeFirstParticipationKey] as? NSNumber else {
                return
            }
            let arguments = [
                "firstParticipation": firstParticipation.boolValue,
                "testInfo": testInfo.serializeForFlutter()
            ] as [String : Any]
            channel.invokeMethod("ApptimizeParticipatedInExperiment", arguments: arguments, result: nil)
        }
    }

    func logError(_ error: String) {
        NSLog("Apptimize-Flutter: \(error)")
    }

    public func handle(_ call: FlutterMethodCall, result    : @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any?]
        var resultValue: Any? = nil
        
        do {
            switch call.method {
                case "startApptimize":
                    try startApptimize(arguments: arguments)
                    
                case "setCustomerUserId":
                    guard let arguments = arguments else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }
                    let customerUserId = arguments["customerUserId"] as? String
                    Apptimize.setCustomerUserID(customerUserId)

                case "getCustomerUserId":
                    resultValue = Apptimize.customerUserID()

                case "getApptimizeAnonUserId":
                    resultValue = Apptimize.apptimizeAnonUserID()
                    
                case "disable":
                    Apptimize.disable()
                    
                case "setOffline":
                    guard let arguments = arguments,
                          let isOffline = arguments["isOffline"] as? Bool else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }
                    Apptimize.setOffline(isOffline)
                    
                case "getOffline":
                    resultValue = Apptimize.isOffline()
                    
                case "getMetadataState":
                    let metadataState = Apptimize.metadataState()
                    resultValue = [
                        "isAvailable": metadataState.contains(.available),
                        "isUpToDate": metadataState.contains(.upToDate),
                        "isRefreshing": metadataState.contains(.refreshing)
                    ]
                    
                case "track":
                    guard let arguments = arguments,
                          let eventName = arguments["eventName"] as? String else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }
                    
                    if let value = arguments["value"] as? Double {
                        Apptimize.track(eventName, value: value)
                    } else {
                        Apptimize.track(eventName)
                    }
                    
                case "getLibraryVersion":
                    resultValue = "\(Apptimize.libraryVersion()) (iOS)"
                    
                case "setPilotTargetingId":
                    guard let arguments = arguments,
                          let pilotTargetingId = arguments["pilotTargetingId"] as? String else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }
                    
                    Apptimize.setPilotTargetingID(pilotTargetingId)
                    
                case "getPilotTargetingId":
                    resultValue = Apptimize.pilotTargetingID()
                    
                case "runTest":
                    resultValue = try runTest(arguments: arguments)
                    
                case "isFeatureFlagOn":
                    guard let arguments = arguments,
                          let featureFlagName = arguments["featureFlagName"] as? String else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }
                    
                    resultValue = Apptimize.isFeatureFlag(on: featureFlagName)
                    
                case "getApptimizeTestInfo":
                    if let testInfo = Apptimize.testInfo() {
                        var result: [String: Any?] = [:]
                        
                        for (key, value) in testInfo {
                            result[key] = value.serializeForFlutter()
                        }
                        
                        resultValue = result
                    }
                    
                case "getInstantUpdateAndWinnerInfo":
                    if let testInfo = Apptimize.instantUpdateAndWinnerInfo() {
                        var result: [String: Any?] = [:]
                        for (key, value) in testInfo {
                            result[key] = value.serializeForFlutter()
                        }
                        
                        resultValue = result
                    }

                case "setUserAttribute":
                    guard let arguments = arguments,
                          let type = arguments["type"] as? String,
                          let attributeName = arguments["attributeName"] as? String,
                          let attributeValueAny = arguments["attributeValue"] else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }
                    
                    switch (type) {
                    case "string":
                        guard let attributeValue = attributeValueAny as? String else {
                            throw PluginError.invalidArgument(msg: "Cannot convert attribute value to \(type)")
                        }
                        Apptimize.setUserAttributeString(attributeValue, forKey: attributeName)
                    case "int":
                        guard let attributeValue = attributeValueAny as? Int else {
                            throw PluginError.invalidArgument(msg: "Cannot convert attribute value to \(type)")
                        }
                        Apptimize.setUserAttributeInteger(attributeValue, forKey: attributeName)
                    case "double":
                        guard let attributeValue = attributeValueAny as? Double else {
                            throw PluginError.invalidArgument(msg: "Cannot convert attribute value to \(type)")
                        }
                        Apptimize.setUserAttributeDouble(attributeValue, forKey: attributeName)
                    case "bool":
                        guard let attributeValue = attributeValueAny as? Bool else {
                            throw PluginError.invalidArgument(msg: "Cannot convert attribute value to \(type)")
                        }
                        Apptimize.setUserAttributeBool(attributeValue, forKey: attributeName)
                    default:
                        throw PluginError.invalidArgument(msg: "Invalid argument type \(type)")
                    }
                                        
                case "removeUserAttribute":
                    guard let arguments = arguments,
                          let attributeName = arguments["attributeName"] as? String else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }
                    
                    Apptimize.removeUserAttribute(forKey: attributeName)

                case "removeAllUserAttributes":
                    Apptimize.removeAllUserAttributes()
                    
                case "getUserAttribute":
                    guard let arguments = arguments,
                          let type = arguments["type"] as? String,
                          let attributeName = arguments["attributeName"] as? String else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }

                    switch (type) {
                    case "string":
                        resultValue = Apptimize.userAttributeString(forKey: attributeName)
                    case "int":
                        resultValue = Apptimize.userAttributeInteger(forKey: attributeName)
                    case "double":
                        resultValue = Apptimize.userAttributeDouble(forKey: attributeName)
                    case "bool":
                        resultValue = Apptimize.userAttributeBool(forKey: attributeName)
                    default:
                        throw PluginError.invalidArgument(msg: "Invalid argument type \(type)")
                    }

                case "forceVariant":
                    guard let arguments = arguments,
                          let variantId = arguments["variantId"] as? Int else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }
                    Apptimize.forceVariant(variantId)
                    
                case "clearForcedVariant":
                    guard let arguments = arguments,
                          let variantId = arguments["variantId"] as? Int else {
                        throw PluginError.invalidArgument(msg: "Missing arguments in call")
                    }
                    Apptimize.clearForcedVariant(variantId)

                case "clearAllForcedVariants":
                    Apptimize.clearAllForcedVariants()
                    
                case "getVariants":
                    let variants = Apptimize.getVariants()
                    resultValue = variants?.values.map({v in
                        return [
                            "experimentName": v["experimentName"],
                            "variantName": v["variantName"],
                            "experimentId": v["experimentID"],
                            "variantId": v["variantID"]
                        ]
                    })
                    
                case "declareDynamicVariable":
                    resultValue = try declareDynamicVariable(arguments: arguments)
                    
                case "isDynamicVariableDeclared":
                    resultValue = try isDynamicVariableDeclared(arguments: arguments)
                    
                case "getDynamicVariableValue":
                    resultValue = try getDynamicVariableValue(arguments: arguments)
                    
                default:
                    NSLog("ApptimizeFlutter: Error \(call.method) unknown.")
                    resultValue = FlutterMethodNotImplemented
            }

            // You _must_ return some result even if null.
            result(resultValue)
        } catch let e as PluginError {
            result(e.toFlutterError())
        } catch {
            result(FlutterError(code: "UNKNOWN", message: nil, details: nil))
        }
    }
    
    private func startApptimize(arguments: [String: Any?]?) throws {
        guard let arguments = arguments,
              let appKey = arguments["appKey"] as? String else {
            throw(PluginError.invalidArgument(msg: "Cannot start apptimize without an appkey"))
        }
        
        var options: [String: Any] = [:]
        if let optionsArgs = arguments["options"] as? [String: Any] {
            if let devicePairingEnabled = optionsArgs["devicePairingEnabled"] as? Bool {
                options[ApptimizeDevicePairingOption] = devicePairingEnabled
            }
            if let delayUntilTestsAreAvailable = optionsArgs["delayUntilTestsAreAvailable"] as? Int {
                options[ApptimizeDelayUntilTestsAreAvailableOption] = delayUntilTestsAreAvailable
            }
            if let enableThirdPartyEventImporting = optionsArgs["enableThirdPartyEventImporting"] as? Bool {
                options[ApptimizeEnableThirdPartyEventImportingOption] = enableThirdPartyEventImporting
            }
            if let enableThirdPartyEventExporting = optionsArgs["enableThirdPartyEventExporting"] as? Bool {
                options[ApptimizeEnableThirdPartyEventExportingOption] = enableThirdPartyEventExporting
            }
            if let forceVariantsShowWinnersAndInstantUpdates = optionsArgs["forceVariantsShowWinnersAndInstantUpdates"] as? Bool {
                options[ApptimizeForceVariantsShowWinnersAndInstantUpdatesOption] = forceVariantsShowWinnersAndInstantUpdates
            }
            if let refreshMetaDataOnSetup = optionsArgs["refreshMetaDataOnSetup"] as? Bool {
                options[ApptimizeRefreshMetadataOnSetupOption] = refreshMetaDataOnSetup
            }
            if let logLevel = optionsArgs["logLevel"] as? String {
                switch (logLevel) {
                case "Verbose":
                    options[ApptimizeLogLevelOption] = ApptimizeLogLevelVerbose
                case "Debug":
                    options[ApptimizeLogLevelOption] = ApptimizeLogLevelDebug
                case "Info":
                    options[ApptimizeLogLevelOption] = ApptimizeLogLevelInfo
                case "Warn":
                    options[ApptimizeLogLevelOption] = ApptimizeLogLevelWarn
                case "Error":
                    options[ApptimizeLogLevelOption] = ApptimizeLogLevelError
                case "Off":
                    options[ApptimizeLogLevelOption] = ApptimizeLogLevelOff
                default:
                    logError("Unknown log level \(logLevel)")
                }
            }
            if let serverRegion = optionsArgs["serverRegion"] as? String {
                switch (serverRegion) {
                case "Default":
                    options[ApptimizeServerRegionOption] = ApptimizeServerRegionDefault
                case "EUCS":
                    options[ApptimizeServerRegionOption] = ApptimizeServerRegionEUCS
                default:
                    logError("Unknown server region \(serverRegion)")
                }
            }
        }
        
        Apptimize.start(withApplicationKey: appKey, options: options)
    }
    
    private func runTest(arguments: [String: Any?]?) throws -> String? {
        guard let arguments = arguments,
              let testName = arguments["testName"] as? String,
              let codeBlockNames = arguments["codeBlocks"] as? [String] else {
            throw(PluginError.invalidArgument(msg: "Invalid arguments for runTest"))
        }
        
        var options:[String:NSNumber]  = [:]
        if let updateMetadataTimeout = arguments["updateMetadataTimeout"] as? Int {
            options[ApptimizeUpdateMetadataTimeoutOption] = NSNumber(value: updateMetadataTimeout)
        }
        
        var result: String? = "CodeBlockError"
        let codeBlocks = codeBlockNames.map { (name) -> ApptimizeCodeBlock in
            return ApptimizeCodeBlock(name: name, andBlock: {
                result = name
            })
        }
        
        Apptimize.runTest(testName, withBaseline: {
            result = nil
        }, apptimizeCodeBlocks: codeBlocks, andOptions: options)
        
        return result
    }
    
    private func declareDynamicVariable(arguments: [String: Any?]?) throws -> Bool {
        guard let arguments = arguments,
              let name = arguments["name"] as? String,
              let type = arguments["type"] as? String,
              let defaultValueRaw = arguments["defaultValue"]
              else {
            throw PluginError.invalidArgument(msg: "Missing arguments in call")
        }

        switch (type)
        {
        case "string":
            guard let defaultValue = defaultValueRaw as? String else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let av = ApptimizeVariable.makeString(name: name, defaultString: defaultValue)
            return av != nil
        case "bool":
            let defaultValue = defaultValueRaw as? Bool ?? false
            let av = ApptimizeVariable.makeBool(name: name, defaultBool: defaultValue)
            return av != nil
        case "integer":
            guard let defaultValue = defaultValueRaw as? Int else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let av = ApptimizeVariable.makeInteger(name: name, defaultInteger: defaultValue)
            return av != nil
        case "double":
            guard let defaultValue = defaultValueRaw as? Double else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let av = ApptimizeVariable.makeDouble(name: name, defaultDouble: defaultValue)
            return av != nil

        case "array.string":
            guard let defaultValue = defaultValueRaw as? [String] else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let av = ApptimizeVariable.makeStringArray(name: name, defaultStringArray: defaultValue)
            return av != nil
        case "array.bool":
            guard let defaultValue = defaultValueRaw as? [Bool] else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let av = ApptimizeVariable.makeBoolArray(name: name, defaultBoolArray: defaultValue.map() { NSNumber(booleanLiteral: $0) })
            return av != nil
        case "array.integer":
            guard let defaultValue = defaultValueRaw as? [Int] else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let av = ApptimizeVariable.makeIntegerArray(name: name, defaultIntegerArray: defaultValue.map() { NSNumber(integerLiteral: $0) })
            return av != nil
        case "array.double":
            guard let defaultValue = defaultValueRaw as? [Double] else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let av = ApptimizeVariable.makeDoubleArray(name: name, defaultDoubleArray: defaultValue.map() { NSNumber(floatLiteral: $0) })
            return av != nil

        case "dictionary.string":
            guard let defaultValue = defaultValueRaw as? [String : String] else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let av = ApptimizeVariable.makeStringDictionary(name: name, defaultStringDictionary: defaultValue)
            return av != nil
        case "dictionary.bool":
            guard let defaultValue = defaultValueRaw as? [String : Bool] else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let bd = Dictionary<String,NSNumber>(uniqueKeysWithValues: defaultValue.enumerated().map({ (e) in
                (e.element.key, NSNumber(booleanLiteral: e.element.value ))
            }))
            let av = ApptimizeVariable.makeBoolDictionary(name: name, defaultBoolDictionary: bd)
            return av != nil
        case "dictionary.integer":
            guard let defaultValue = defaultValueRaw as? [String : Int] else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let id = Dictionary<String,NSNumber>(uniqueKeysWithValues: defaultValue.enumerated().map({ (e) in
                (e.element.key, NSNumber(integerLiteral: e.element.value ))
            }))
            let av = ApptimizeVariable.makeIntegerDictionary(name: name, defaultIntegerDictionary: id)
            return av != nil
        case "dictionary.double":
            guard let defaultValue = defaultValueRaw as? [String : Double] else { throw PluginError.invalidArgument(msg: "Cannot cast default value to expected type.")}
            let dd = Dictionary<String,NSNumber>(uniqueKeysWithValues: defaultValue.enumerated().map({ (e) in
                (e.element.key, NSNumber(floatLiteral: e.element.value ))
            }))
            let av = ApptimizeVariable.makeDoubleDictionary(name: name, defaultDoubleDictionary: dd)
            return av != nil

        default:
            throw PluginError.invalidArgument(msg: "Invalid dynamic variable type \(type)")
        }
    }
    
    private func isDynamicVariableDeclared(arguments: [String: Any?]?) throws -> Bool {
        do {
            let _ = try getDynamicVariableValue(arguments: arguments)
        } catch {
            return false
        }
        
        return true
    }

    private func getDynamicVariableValue(arguments: [String: Any?]?) throws -> Any? {
        guard let arguments = arguments,
              let name = arguments["name"] as? String,
              let type = arguments["type"] as? String
              else {
            throw PluginError.invalidArgument(msg: "Missing arguments in call")
        }

        switch (type)
        {
        case "string":
            guard let av = ApptimizeVariable.getString(name: name) else { throw ApptimizeVariableDoesNotExist() }
            return av.stringValue
        case "bool":
            guard let av = ApptimizeVariable.getBool(name: name) else { throw ApptimizeVariableDoesNotExist() }
            return av.boolValue
        case "integer":
            guard let av = ApptimizeVariable.getInteger(name: name) else { throw ApptimizeVariableDoesNotExist() }
            return av.integerValue
        case "double":
            guard let av = ApptimizeVariable.getDouble(name: name) else { throw ApptimizeVariableDoesNotExist() }
            return av.doubleValue

        case "array.string":
            guard let av = ApptimizeVariable.getStringArray(name: name) else { throw ApptimizeVariableDoesNotExist() }
            return av.arrayValue?.map() { String($0) }
        case "array.bool":
            guard let av = ApptimizeVariable.getBoolArray(name: name) else { throw ApptimizeVariableDoesNotExist() }
            return av.arrayValue?.map() { $0.boolValue }
        case "array.integer":
            guard let av = ApptimizeVariable.getIntegerArray(name: name) else { throw ApptimizeVariableDoesNotExist() }
            return av.arrayValue?.map() { $0.intValue }
        case "array.double":
            guard let av = ApptimizeVariable.getDoubleArray(name: name) else { throw ApptimizeVariableDoesNotExist() }
            return av.arrayValue?.map() { $0.doubleValue }

        case "dictionary.string":
            guard let av = ApptimizeVariable.getStringDictionary(name: name) else { throw ApptimizeVariableDoesNotExist() }
            guard let dv = av.dictionaryValue else { return nil }
            return Dictionary<String,String>(uniqueKeysWithValues:dv.enumerated().map() { ($0.element.key, String($0.element.value)) })
        case "dictionary.bool":
            guard let av = ApptimizeVariable.getBoolDictionary(name: name) else { throw ApptimizeVariableDoesNotExist() }
            guard let dv = av.dictionaryValue else { return nil }
            return Dictionary<String,Bool>(uniqueKeysWithValues:dv.enumerated().map() { ($0.element.key, $0.element.value.boolValue) })
        case "dictionary.integer":
            guard let av = ApptimizeVariable.getIntegerDictionary(name: name) else { throw ApptimizeVariableDoesNotExist() }
            guard let dv = av.dictionaryValue else { return nil }
            return Dictionary<String,Int>(uniqueKeysWithValues:dv.enumerated().map() { ($0.element.key, $0.element.value.intValue) })
        case "dictionary.double":
            guard let av = ApptimizeVariable.getDoubleDictionary(name: name) else { throw ApptimizeVariableDoesNotExist() }
            guard let dv = av.dictionaryValue else { return nil }
            return Dictionary<String,Double>(uniqueKeysWithValues:dv.enumerated().map() { ($0.element.key, $0.element.value.doubleValue) })

        default:
            throw PluginError.invalidArgument(msg: "Invalid dynamic variable type \(type)")
        }
    }

}

// Help me out with dates!
extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) {
        self.init()
        self.formatOptions = formatOptions
        self.timeZone = timeZone
    }
}
extension Formatter {
    static let iso8601withFractionalSeconds = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}
extension Date {
    var iso8601withFractionalSeconds: String { return Formatter.iso8601withFractionalSeconds.string(from: self) }
}
extension String {
    var iso8601withFractionalSeconds: Date? { return Formatter.iso8601withFractionalSeconds.date(from: self) }
}
extension ExperimentType {
    func serializeForFlutter() -> String {
        switch (self) {
        case .codeBlock:
            return "CodeBlock"
        case .dynamicVariables:
            return "DynamicVariables"
        case .featureFlag:
            return "FeatureFlag"
        case .unknown:
            return "Unknown"
        case .visual:
            return "Visual"
        default:
            return "Unknown"
        }
    }
}
extension UnenrollmentReason {
    func serializeForFlutter() -> String {
        switch (self) {
        case .experimentStopped:
            return "ExperimentStopped"
        case .experimentWinnerSelected:
            return "ExperimentWinnerSelected"
        case .other:
            return "Other"
        case .unknown:
            return "Unknown"
        case .userIdChanged:
            return "UserIdChanged"
        case .variantChanged:
            return "VariantChanged"
        default:
            return "Unknown"
        }
    }
}

extension ApptimizeTestInfo {
    func serializeForFlutter() -> [String:Any?] {
        return [
            "testName": self.testName(),
            "enrolledVariantName": self.enrolledVariantName(),
            "testId": self.testID().intValue,
            "enrolledVariantId": self.enrolledVariantID(),
            "testStartedDate": self.testStartedDate().iso8601withFractionalSeconds,
            "testEnrolledDate": self.testEnrolledDate().iso8601withFractionalSeconds,
            "cycle": self.cycle().intValue,
            "currentPhase": self.currentPhase().intValue,
            "participationPhase": self.participationPhase().intValue,
            "userHasParticipated": self.userHasParticipated(),
            "userId": self.userID() as Any?,
            "anonymousUserId": self.anonymousUserID(),
            "experimentType": self.experimentType().serializeForFlutter()
        ]
    }
}
extension ApptimizeInstantUpdateOrWinnerInfo {
    func serializeForFlutter() -> [String:Any?] {
        return [
            "isInstantUpdate": self.isInstantUpdate(),
            "winningExperimentName": self.winningExperimentName(),
            "winningExperimentId": self.winningExperimentID().intValue,
            "instantUpdateName": self.instantUpdateName(),
            "instantUpdateId": self.instantUpdateID().intValue,
            "winningVariantName": self.winningVariantName(),
            "winningVariantId": self.winningVariantID().intValue,
            "startDate": self.startDate()?.iso8601withFractionalSeconds as Any?,
            "userId": self.userID() as Any?,
            "anonymousUserId": self.anonymousUserID()
        ]
    }
}
