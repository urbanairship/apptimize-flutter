// ignore_for_file: close_sinks
import 'dart:async';
import 'dart:core';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';

/// The Apptimize interface is the main interaction point with the Apptimize SDK
/// for developers.
///
/// To get started call [startApptimize] with your Apptimize app key.
class Apptimize {
  static final String _logTag = "com.apptimize.apptimize";

  /// Gets the broadcast stream of [ApptimizeEnrolledInExperimentEvent] events.
  static Stream<ApptimizeEnrolledInExperimentEvent>
      get apptimizeEnrolledInExperimentStream =>
          _apptimizeEnrolledInExperimentStreamController.stream;

  /// Gets the broadcast stream of [ApptimizeParticipatedInExperimentEvent] events.
  static Stream<ApptimizeParticipatedInExperimentEvent>
      get apptimizeParticipatedInExperimentStream =>
          _apptimizeParticipatedInExperimentStreamController.stream;

  /// Gets the broadcast stream of [ApptimizeUnenrolledInExperimentEvent] events.
  static Stream<ApptimizeUnenrolledInExperimentEvent>
      get apptimizeUnenrolledInExperimentStream =>
          _apptimizeUnenrolledInExperimentStreamController.stream;

  /// Gets the broadcast stream of [ApptimizeInitializedEvent] events.
  static Stream<ApptimizeInitializedEvent> get apptimizeInitializedStream =>
      _apptimizeInitializedStreamController.stream;

  /// Gets the broadcast stream of [ApptimizeTestsProcessedEvent] events.
  static Stream<ApptimizeTestsProcessedEvent>
      get apptimizeTestsProcessedStream =>
          _apptimizeTestsProcessedStreamController.stream;

  /// Gets the broadcast stream of [ApptimizeResumedEvent] events.
  static Stream<ApptimizeResumedEvent> get apptimizeResumedStream =>
      _apptimizeResumedStreamController.stream;

  /// Gets the broadcast stream of [ApptimizeMetadataStateChangedEvent] events.
  static Stream<ApptimizeMetadataStateChangedEvent>
      get apptimizeMetadataStateChangedStream =>
          _apptimizeMetadataStateChangedStreamController.stream;

  /// Starts apptimize with the specified [appKey].
  ///
  /// If [options] are not specified, the default options will be used.
  ///
  /// You should always wait for the [ApptimizeInitializedEvent] event to be
  /// fired before you use Apptimize. See [apptimizeInitializedStream].
  ///
  /// If you do not wait for initialization you may get default values for any
  /// tests run.
  ///
  /// ### iOS specific
  /// Startup may be delayed whenever device file protection has locked files
  /// Apptimize needs to start up. This can happen if your application is
  /// launched in the background before the device has been unlocked for the
  /// first time after a reboot, or if the default file protection level for
  /// the app has been modified to be more secure. In this case, listening for
  /// the [ApptimizeInitializedEvent] event will ensure that apptimize is
  /// available.
  static void startApptimize(String appKey, [ApptimizeOptions? options]) {
    _channel.invokeMethod(
        'startApptimize', {"appKey": appKey, "options": options?.toMap()});
  }

  /// Sets the current customer-specified user id.
  ///
  /// User ids are arbitrary [String]s, except that they cannot be the empty
  /// string (“”). When the customer-specified user id is `null`, then Apptimize
  /// creates and uses an anonymous user id for tracking purposes. If the
  /// [customerUserId] is set to a non-`null` value, then set back to `null`,
  /// Apptimize will use the same anonymous user id as before.
  ///
  /// The initial default value of the customer-specified user id is `null`.
  ///
  /// **Note** If startup is delayed the customer id change will also be delayed
  /// until startup is completed. This means that the change will not be
  /// persisted or available via [customerUserId] until startup is completed.
  static Future<void> setCustomerUserId(String? customerUserId) async {
    await _channel
        .invokeMethod('setCustomerUserId', {'customerUserId': customerUserId});
  }

  /// Gets the current customer-specified user id.
  ///
  /// If there is no customer-specified user id then this value is `null`.
  ///
  /// **Note** If startup is delayed the current customer user id will be
  /// unavailable and this function will return `null`.
  static Future<String?> get customerUserId async {
    return await _channel.invokeMethod('getCustomerUserId');
  }

  /// Gets the current Apptimize-created anonymous user id.
  ///
  /// This anonymous user id will be used if-and-only-if the customer-specified
  /// user id is `null`. A single anonymous user id is created. If the customer
  /// user id is set to a non-`null` value, then set back to `null`, Apptimize will
  /// use the same anonymous user id as before.
  ///
  /// **Note** If startup is delayed the current anonymous user id will be
  /// unavailable and this function will return `null`.
  static Future<String?> get apptimizeAnonUserId async {
    return await _channel.invokeMethod('getApptimizeAnonUserId');
  }

  /// Disables Apptimize and all of its features for one application session.
  ///
  /// No tests will run, no data will be logged, and no results will be posted
  /// to the Apptimize dashboard. Apptimize cannot be re-enabled during this
  /// session; the application must be restarted.
  ///
  /// _Use with caution_.
  static Future<void> disable() async {
    await _channel.invokeMethod('disable');
  }

  /// Updates the Apptimize offline mode flag.
  ///
  /// If [isOffline] is `true` then Apptimize is in offline mode. In offline mode
  /// all network traffic is disabled.
  ///
  /// Specifically the app will not receive metadata, upload results, or (for
  /// debug builds) be able to pair with the Apptimize web dashboard.
  ///
  /// This setting is persistent and stays in effect across sessions.
  ///
  /// You may call [setOffline] before calling [startApptimize].
  static Future<void> setOffline(bool isOffline) async {
    await _channel.invokeMethod('setOffline', {'isOffline': isOffline});
  }

  /// Gets the current value of the offline mode setting.
  ///
  /// Returns `true` if Apptimize is configured to run in offline mode.
  /// Otherwise it returns `false`.
  static Future<bool> get offline async {
    var isOffline = await _channel.invokeMethod('getOffline');
    if (isOffline == null) {
      developer.log("Expected `bool` as `getOffline` response",
          name: Apptimize._logTag);
    }
    return isOffline ?? false;
  }

  /// Gets the current state of the Apptimize metadata.
  ///
  /// See [ApptimizeMetaDataState] for more information.
  static Future<ApptimizeMetaDataState> get metadataState async {
    final Map metadataState =
        await _channel.invokeMethod('getMetadataState') ?? Map();
    final bool? isAvailable = metadataState['isAvailable'];
    final bool? isUpToDate = metadataState['isUpToDate'];
    final bool? isRefreshing = metadataState['isRefreshing'];

    if (isAvailable == null) {
      developer.log("Missing `isAvailable` in `getMetadataState` response",
          name: Apptimize._logTag);
    }
    if (isUpToDate == null) {
      developer.log("Missing `isUpToDate` in `getMetadataState` response",
          name: Apptimize._logTag);
    }
    if (isRefreshing == null) {
      developer.log("Missing `isRefreshing` in `getMetadataState` response",
          name: Apptimize._logTag);
    }

    return new ApptimizeMetaDataState(
        isAvailable ?? false, isUpToDate ?? false, isRefreshing ?? false);
  }

  /// Generate an event with the name [eventName].
  ///
  /// You can optionally associate a numeric [value] with the event.
  static Future<void> track(String eventName, [double? value]) async {
    await _channel
        .invokeMethod('track', {"eventName": eventName, "value": value});
  }

  /// Get the underlying library version.
  ///
  /// Returns the version number of the underlying Apptimize library as a string
  /// formatted as major.minor.build (e.g., 1.2.0) followed by the underlying
  /// platform (e.g. iOS).
  static Future<String> get libraryVersion async {
    final String? libraryVersion =
        await _channel.invokeMethod<String>('getLibraryVersion');
    return libraryVersion ?? "ApptimizeVersionError";
  }

  /// Sets the pilotTargetingId
  ///
  /// In order to use the pilot targeting feature available on the Apptimize web
  /// dashboard this value must be set. Set this value to `null` to disable pilot
  /// targeting.
  ///
  /// Pilot targeting allows you to select specific pilot targeting ids and
  /// groups of pilot targeting ids in the Apptimize web dashboard for the
  /// purposes of targeting experiments and feature flags to specific app/user
  /// instances.
  ///
  /// Setting this value will cause pilot targeting to be recalculated if
  /// applicable.
  static Future<void> setPilotTargetingId(String? pilotTargetingId) async {
    await _channel.invokeMethod(
        'setPilotTargetingId', {'pilotTargetingId': pilotTargetingId});
  }

  /// Gets the currently set pilot targeting id.
  ///
  /// Returns `null` if no pilot targeting id is configured.
  ///
  /// See [setPilotTargetingId] for more information.
  static Future<String?> get pilotTargetingId async {
    return await _channel.invokeMethod('getPilotTargetingId');
  }

  /// Wait for the initial set of tests to become available.
  ///
  /// This method will block for [timeout] milliseconds (up to 8000) while
  /// Apptimize attempts to fetch tests and any related assets.
  ///
  /// This is meant to be used as part of application initialization, usually
  /// during a loading screen.
  static Future<void> waitForTestsToBecomeAvailable(int timeout) async {
    return await _channel
        .invokeMethod('getPilotTargetingID', {'timeout': timeout});
  }

  /// Runs the code block A/B test specified by [testName].
  ///
  /// You must specify the [baseline] (default) code block to execute if we are
  /// enrolled in the default variant. Each of the variants are specified in the
  /// [codeblocks] [Map] keyed using strings. The string keys must match the
  /// name of the variant set in the Apptimize dashboard.
  ///
  /// Additional [updateMetadataTimeout] in milliseconds may be specified.
  ///
  /// When this method is called, one of the code block variants or the default
  /// code block will be run sychronously in accordance with the A/B test
  /// variant this user/device is enrolled in.
  static Future<void> runTest(
      String testName, Function baseline, Map<String, Function> codeblocks,
      [int? updateMetadataTimeout]) async {
    final String? codeblock = await _channel.invokeMethod('runTest', {
      "testName": testName,
      "codeBlocks": codeblocks.keys.toList(),
      "updateMetadataTimeout": updateMetadataTimeout
    });

    Function? block = null;

    if (codeblock != null) {
      block = codeblocks[codeblock];
      if (block == null) {
        developer.log("`runTest` received unknown codeblock `${codeblock}` in result, executing default.",
            name: Apptimize._logTag);
      }
    }

    block = block ?? baseline;
    block();
  }

  /// Check whether a given feature flag is enabled or not.
  ///
  /// Returns `true` if the feature flag is on, `false` if it is not.
  static Future<bool> isFeatureFlagOn(String featureFlagName) async {
    final bool? response = await _channel.invokeMethod<bool>(
        'isFeatureFlagOn', {'featureFlagName': featureFlagName});
    if (response == null) {
      developer.log("Expected `bool` in `featureFlatName` response",
          name: Apptimize._logTag);
    }

    return response ?? false;
  }

  /// Get information about all Apptimize A/B tests and Feature Flags that the
  /// device is enrolled in.
  ///
  /// Returns a [Map] whose keys are the names of all A/B tests and Feature
  /// Flags the device is enrolled in, and whose values are [ApptimizeTestInfo]
  /// objects containing information about the test or feature flag. If this
  /// device is enrolled in no tests, an empty Map is returned. If
  /// [startApptimize] has not been called yet, `null` is returned.
  ///
  /// **Note** This does not include information about Apptimize A/B tests or
  /// Feature Flags that are running but that the device is not enrolled in.
  static Future<Map<String, ApptimizeTestInfo?>?> get apptimizeTestInfo async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('getApptimizeTestInfo');
    if (result == null) {
      return null;
    }

    final entries = result.entries;
    if (entries == null) {
      developer.log("Missing `entries` in `getApptimizeInfo` response",
          name: Apptimize._logTag);
      return null;
    }

    Map<String, ApptimizeTestInfo?> apptimizeTestInfos =
        new Map<String, ApptimizeTestInfo?>();
    for (final e in entries) {
      final String key = e.key;
      final Map value = e.value;
      if (key == null) {
        developer.log(
            "Expected `String` key in entries of `getApptimizeTestInfo` response",
            name: Apptimize._logTag);
        continue;
      }
      if (value == null) {
        developer.log(
            "Expected `Map` value in entries of `getApptimizeTestInfo` response",
            name: Apptimize._logTag);
        continue;
      }

      apptimizeTestInfos[key] = ApptimizeTestInfo._fromMap(value);
    }

    return apptimizeTestInfos;
  }

  /// Get information about all winning A/B tests and instant updates that the
  /// device will show.
  ///
  /// Returns a dictionary whose keys are the names of all A/B tests and instant
  /// updates the device has active, and whose values are
  /// `ApptimizeInstantUpdateOrWinnerInfo` objects containing information about
  /// the test or instant update. If there are no winners or instant updates,
  /// an empty dictionary is returned. If `startApptimize` has not been called
  /// yet `null` is returned.
  static Future<Map<String, ApptimizeInstantUpdateOrWinnerInfo?>?>
      get instantUpdateAndWinnerInfo async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('getInstantUpdateAndWinnerInfo');
    if (result == null) {
      return null;
    }

    final entries = result.entries;
    if (entries == null) {
      developer.log(
          "Missing `entries` in `getInstantUpdateAndWinnerInfo` response",
          name: Apptimize._logTag);
      return null;
    }

    Map<String, ApptimizeInstantUpdateOrWinnerInfo?> apptimizeTestInfos =
        new Map<String, ApptimizeInstantUpdateOrWinnerInfo?>();
    for (final e in entries) {
      final String key = e.key;
      final Map value = e.value;
      if (key == null) {
        developer.log(
            "Expected `String` key in entries of `getInstantUpdateAndWinnerInfo` response",
            name: Apptimize._logTag);
        continue;
      }
      if (value == null) {
        developer.log(
            "Expected `Map` value in entries of `getInstantUpdateAndWinnerInfo` response",
            name: Apptimize._logTag);
        continue;
      }

      apptimizeTestInfos[key] =
          ApptimizeInstantUpdateOrWinnerInfo._fromMap(value);
    }

    return apptimizeTestInfos;
  }

  /// Set a user attribute [String] to be used for targeting, filtering and
  /// segmentation.
  ///
  /// [attributeName] specifies the name of the attribute while [attributeValue]
  /// specifies the [String] value to associate with the attribute.
  static Future<void> setUserAttributeString(
      String attributeName, String attributeValue) async {
    await _channel.invokeMethod('setUserAttribute', {
      'type': 'string',
      'attributeName': attributeName,
      'attributeValue': attributeValue
    });
  }

  /// Set a user attribute [int] to be used for targeting, filtering and
  /// segmentation.
  ///
  /// [attributeName] specifies the name of the attribute while [attributeValue]
  /// specifies the [int] value to associate with the attribute.
  static Future<void> setUserAttributeInteger(
      String attributeName, int attributeValue) async {
    await _channel.invokeMethod('setUserAttribute', {
      'type': 'int',
      'attributeName': attributeName,
      'attributeValue': attributeValue
    });
  }

  /// Set a user attribute [double] to be used for targeting, filtering and
  /// segmentation.
  ///
  /// [attributeName] specifies the name of the attribute while [attributeValue]
  /// specifies the [double] value to associate with the attribute.
  static Future<void> setUserAttributeDouble(
      String attributeName, double attributeValue) async {
    await _channel.invokeMethod('setUserAttribute', {
      'type': 'double',
      'attributeName': attributeName,
      'attributeValue': attributeValue
    });
  }

  /// Set a user attribute [bool] to be used for targeting, filtering and
  /// segmentation.
  ///
  /// [attributeName] specifies the name of the attribute while [attributeValue]
  /// specifies the [bool] value to associate with the attribute.
  static Future<void> setUserAttributeBool(
      String attributeName, bool attributeValue) async {
    await _channel.invokeMethod('setUserAttribute', {
      'type': 'bool',
      'attributeName': attributeName,
      'attributeValue': attributeValue
    });
  }

  /// Remove the user defined attribute for a given for [attributeName].
  static Future<void> removeUserAttribute(String attributeName) async {
    await _channel
        .invokeMethod('removeUserAttribute', {'attributeName': attributeName});
  }

  /// Remove all user defined attributes.
  static Future<void> removeAllUserAttributes() async {
    await _channel.invokeMethod('removeAllUserAttributes');
  }

  /// Get the currently set [String] value for an attribute.
  static Future<String?> getUserAttributeString(String attributeName) async {
    return await _channel.invokeMethod(
        'getUserAttribute', {'type': 'string', 'attributeName': attributeName});
  }

  /// Get the currently set [int] value for an attribute.
  static Future<int?> getUserAttributeInteger(String attributeName) async {
    return await _channel.invokeMethod(
        'getUserAttribute', {'type': 'int', 'attributeName': attributeName});
  }

  /// Get the currently set [double] value for an attribute.
  static Future<double?> getUserAttributeDouble(String attributeName) async {
    return await _channel.invokeMethod(
        'getUserAttribute', {'type': 'double', 'attributeName': attributeName});
  }

  /// Get the currently set [bool] value for an attribute.
  static Future<bool?> getUserAttributeBool(String attributeName) async {
    return await _channel.invokeMethod(
        'getUserAttribute', {'type': 'bool', 'attributeName': attributeName});
  }

  /// Force a variant with the given id to be enabled.
  ///
  /// Once forceVariant is called, Apptimize is placed in a special test mode
  /// where it will only enable variants that are forced by forceVariant. All
  /// other Feature Flags, A/B Experiments and Instant Updates will appear
  /// disabled/off unless a specific variant is forced for those projects.
  ///
  /// The variant specified by [variantId] will be enabled.
  ///
  /// Call [forceVariant] for each of the variants you want to apply.
  /// Call [clearAllForcedVariants] to return Apptimize to normal operation.
  /// Call [clearForcedVariant] to clear a single forced variant.
  /// Call [getVariants] to list all possible variants.
  static Future<void> forceVariant(int variantId) async {
    await _channel.invokeMethod('forceVariant', {'variantId': variantId});
  }

  /// Cancel a forced variant with the given id.
  ///
  /// The variant specified by [variantId] will be cancelled.
  static Future<void> clearForcedVariant(int variantId) async {
    await _channel.invokeMethod('clearForcedVariant', {'variantId': variantId});
  }

  /// Cancel all forced variants.
  ///
  /// Cancels all forced variants specified by calls to [forceVariant].
  static Future<void> clearAllForcedVariants() async {
    await _channel.invokeMethod('clearAllForcedVariants');
  }

  /// Get information about all available variants.
  ///
  /// The returned map is a mapping of variant ids to an [ApptimizeVariant].
  /// The returned map will be empty if there are no available variants.
  static Future<Map<int, ApptimizeVariant>> getVariants() async {
    final List<dynamic>? result = await _channel.invokeMethod('getVariants');
    if (result == null) {
      return Map();
    }

    Map<int, ApptimizeVariant> variants = new Map<int, ApptimizeVariant>();
    for (final Map e in result) {
      if (e == null) {
        developer.log("Expected `Map` in each entry of `getVariants` response",
            name: Apptimize._logTag);
        continue;
      }

      final ApptimizeVariant variant = ApptimizeVariant._fromMap(e)!;
      final int key = variant.variantId;
      if (variant == null || key == null) {
        developer.log(
            "Expected `int` `variantId` in each entry of `getVariants` response",
            name: Apptimize._logTag);
        continue;
      }

      variants[variant.variantId] = variant;
    }

    return variants;
  }

  //
  // Internals
  //

  /// Internal method channel bridge to native
  static final MethodChannel _channel = MethodChannel('apptimize_flutter')
    ..setMethodCallHandler(_methodCallHandler);

  /// Helper declaring dynamic variables
  static Future<bool> _declareDynamicVariable(
      String name, String type, dynamic defaultValue) async {
    final variableDeclared = await _channel.invokeMethod(
        "declareDynamicVariable",
        {'name': name, 'type': type, 'defaultValue': defaultValue});
    return variableDeclared ?? false;
  }

  /// Helper to determine if a dynamic variable is declared or not.
  static Future<bool> _isDynamicVariableDeclared(
      String name, String type) async {
    var variableDeclared = await _channel.invokeMethod(
        "isDynamicVariableDeclared", {'name': name, 'type': type});
    return variableDeclared ?? false;
  }

  /// Helper for getting the value of a dynamic variable.
  static Future<dynamic> _getDynamicVariableValue(
      String name, String type) async {
    dynamic value = await _channel
        .invokeMethod("getDynamicVariableValue", {'name': name, 'type': type});

    return value;
  }

  /// Dispatcher for callbacks, fired as streams.
  static Future<void> _methodCallHandler(MethodCall call) async {
    try {
      switch (call.method) {
        case 'ApptimizeEnrolledInExperiment':
          var testInfo = ApptimizeTestInfo._fromMap(call.arguments['testInfo']);
          if (testInfo == null) {
            developer.log(
                "Will not fire `ApptimizeEnrolledInExperiment` with empty info",
                name: Apptimize._logTag);
            return;
          }
          _apptimizeEnrolledInExperimentStreamController
              .add(new ApptimizeEnrolledInExperimentEvent(testInfo));
          break;

        case 'ApptimizeParticipatedInExperiment':
          var testInfo = ApptimizeTestInfo._fromMap(call.arguments['testInfo']);
          bool? firstParticipation = call.arguments['firstParticipation'];
          if (testInfo == null) {
            developer.log(
                "Will not fire `ApptimizeParticipatedInExperiment` with empty info",
                name: Apptimize._logTag);
            return;
          }
          if (firstParticipation == null) {
            developer.log(
                "Expected `firstParticipation` in `ApptimizeParticipatedInExperiment` event args.",
                name: Apptimize._logTag);
          }
          _apptimizeParticipatedInExperimentStreamController.add(
              new ApptimizeParticipatedInExperimentEvent(
                  testInfo, firstParticipation ?? false));
          break;

        case 'ApptimizeUnenrolledInExperiment':
          var testInfo = ApptimizeTestInfo._fromMap(call.arguments['testInfo']);
          if (testInfo == null) {
            developer.log(
                "Will not fire `ApptimizeUnenrolledInExperiment` with empty info",
                name: Apptimize._logTag);
            return;
          }

          String? unenrollmentReasonString =
              call.arguments['unenrollmentReason'];
          if (unenrollmentReasonString == null) {
            developer.log(
                "Will not fire `ApptimizeUnenrolledInExperiment` with missing `unenrollmentReasonString`",
                name: Apptimize._logTag);
            return;
          }

          ApptimizeUnenrollmentReason unenrollmentReason =
              unenrollmentReasonString.parseApptimizeUnenrollmentReason();
          _apptimizeUnenrolledInExperimentStreamController.add(
              new ApptimizeUnenrolledInExperimentEvent(
                  testInfo, unenrollmentReason));
          break;

        case 'ApptimizeInitialized':
          _apptimizeInitializedStreamController
              .add(new ApptimizeInitializedEvent());
          break;

        case 'ApptimizeResumed':
          bool willRefreshMetadata =
              call.arguments['willRefreshMetadata'] ?? false;
          _apptimizeResumedStreamController
              .add(new ApptimizeResumedEvent(willRefreshMetadata));
          break;

        case 'ApptimizeMetadataStateChanged':
          bool isAvailable = call.arguments['isAvailable'] ?? false;
          bool isUpToDate = call.arguments['isUpToDate'] ?? false;
          bool isRefreshing = call.arguments['isRefreshing'] ?? false;

          ApptimizeMetaDataState metaDataState =
              ApptimizeMetaDataState(isAvailable, isUpToDate, isRefreshing);
          _apptimizeMetadataStateChangedStreamController
              .add(new ApptimizeMetadataStateChangedEvent(metaDataState));
          break;

        case 'ApptimizeTestsProcessed':
          _apptimizeTestsProcessedStreamController
              .add(new ApptimizeTestsProcessedEvent());
          break;

        default:
            developer.log("Don't know how to handle ${call.method}.",
              name: Apptimize._logTag);
          break;
      }
    } catch (e) {
      developer.log("An error occurred handling a callback from the plugin.",
        name: Apptimize._logTag);
      developer.log("${e}",
        name: Apptimize._logTag);
    }
  }

  // Stream broadcasters.
  static final StreamController<ApptimizeEnrolledInExperimentEvent>
      _apptimizeEnrolledInExperimentStreamController =
      new StreamController<ApptimizeEnrolledInExperimentEvent>.broadcast();
  static final StreamController<ApptimizeParticipatedInExperimentEvent>
      _apptimizeParticipatedInExperimentStreamController =
      new StreamController<ApptimizeParticipatedInExperimentEvent>.broadcast();
  static final StreamController<ApptimizeUnenrolledInExperimentEvent>
      _apptimizeUnenrolledInExperimentStreamController =
      new StreamController<ApptimizeUnenrolledInExperimentEvent>.broadcast();
  static final StreamController<ApptimizeInitializedEvent>
      _apptimizeInitializedStreamController =
      new StreamController<ApptimizeInitializedEvent>.broadcast();
  static final StreamController<ApptimizeTestsProcessedEvent>
      _apptimizeTestsProcessedStreamController =
      new StreamController<ApptimizeTestsProcessedEvent>.broadcast();
  static final StreamController<ApptimizeResumedEvent>
      _apptimizeResumedStreamController =
      new StreamController<ApptimizeResumedEvent>.broadcast();
  static final StreamController<ApptimizeMetadataStateChangedEvent>
      _apptimizeMetadataStateChangedStreamController =
      new StreamController<ApptimizeMetadataStateChangedEvent>.broadcast();
}

/// ApptimizeValueVariable is a dynamic variable which contains a specified
/// type.
///
/// Supported dynamic variable types are: [String], [bool], [int], [double].
/// Use the static methods on [ApptimizeVariable] to declare new
/// [ApptimizeValueVariable]s (using the `declare` methods) or to retrieve them
/// (using the `get` methods).
///
/// All dynamic variables must be declared first before using.
class ApptimizeValueVariable<T> extends ApptimizeVariable<T> {
  ApptimizeValueVariable._(name, type) : super._(name, type);

  /// Gets the value of this ApptimizeValueVariable of the specified type.
  ///
  /// Gets the default value provided at construction if no variant has been
  /// received from the servers, or the variant value if enrolled in a
  /// particular variant.
  ///
  /// Returns the default value if there is an issue with the incoming variant
  /// data.
  Future<T?> get value async {
    T? value = await Apptimize._getDynamicVariableValue(name, _type);
    if (value == null) {
      return null;
    }

    if (value is T) {
      return value;
    }

    developer.log(
        "Apptimzie variable with name `${name}` did not contain the expected type.",
        name: Apptimize._logTag);

    return null;
  }
}

/// ApptimizeListVariable is a dynamic variable which contains a list of values
/// of the specified type.
///
/// Supported dynamic variable list types are: [String], [bool], [int], [double].
/// Use the static methods on [ApptimizeVariable] to declare new
/// [ApptimizeListVariable]s (using the `declare` methods) or to retrieve them
/// (using the `get` methods).
///
/// All dynamic variables must be declared first before using.
class ApptimizeListVariable<T> extends ApptimizeVariable<T> {
  ApptimizeListVariable._(name, type) : super._(name, type);

  /// Gets the value of this ApptimizeListVariable of the specified type.
  ///
  /// Gets the default list provided at construction if no variant has been
  /// received from the servers, or the variant list if enrolled in a
  /// particular variant.
  ///
  /// Returns the default value if there is an issue with the incoming variant
  /// data.
  Future<List<T>> get value async {
    List<dynamic> list = await Apptimize._getDynamicVariableValue(name, _type);
    if (list.isEmpty) {
      return [];
    }

    return List<T>.from(list);
  }
}

/// ApptimizeMapVariable is a dynamic variable which contains a map of values of
/// the specified type keyed by strings.
///
/// Supported dynamic variable map types are: [String], [bool], [int], [double].
/// Use the static methods on [ApptimizeVariable] to declare new
/// [ApptimizeMapVariable]s (using the `declare` methods) or to retrieve them
/// (using the `get` methods).
///
/// All dynamic variables must be declared first before using.
class ApptimizeMapVariable<T> extends ApptimizeVariable<T> {
  ApptimizeMapVariable._(name, type) : super._(name, type);

  /// Gets the map of this ApptimizeMapVariable of the specified type.
  ///
  /// Gets the default map provided at construction if no variant has been
  /// received from the servers, or the variant map if enrolled in a
  /// particular variant.
  ///
  /// If a variant is returned, none of the key/value pairs from the default
  /// will be returned, even if that key isn’t specified in the variant
  /// dictionary.
  ///
  /// Returns the default value if there is an issue with the incoming variant
  /// data.
  Future<Map<String, T>> get value async {
    Map<dynamic, dynamic> map =
        await Apptimize._getDynamicVariableValue(name, _type);

    if (map.isEmpty) {
      return Map<String, T>();
    }

    return Map.fromEntries(
        map.entries.map((e) => MapEntry(e.key.toString(), e.value as T)));
  }
}

/// The interface used to create and retrieve dynamic variables.
///
/// The factory methods are used to create and register dynamic variables with
/// the SDK. As they need to be declared prior to setting up an experiment, they
/// should be called as early as possible during app execution. Variables can
/// be declared before the call to [startApptimize].
///
/// All the factory methods return a reference to the created dynamic variable.
///
/// As dynamic variables are expected to be declared ahead of time during app
/// startup, getters are provided to retrieve those dynamic variables at time of
/// use.
class ApptimizeVariable<T> {
  /// The name this dynamic variable was declared with.
  final String name;
  final String _type;

  ApptimizeVariable._(this.name, this._type);

  static const String _DVTypeString = 'string';
  static const String _DVTypeBool = 'bool';
  static const String _DVTypeInt = 'integer';
  static const String _DVTypeDouble = 'double';
  static const String _DVTypeArray = 'array.';
  static const String _DVTypeDictionary = 'dictionary.';

  /// Create a string dynamic variable with a specified [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeVariable] of type [String] if no variable has been
  /// created before with this [name]. If an [ApptimizeVariable] already exists
  /// with this name it returns the existing [String] variable but does not
  /// update the default value or [null] if it is not a [String].
  ///
  /// The [name] must not be `null`.
  static Future<ApptimizeVariable<String>?> declareString(
      String name, String defaultValue) async {
    return _declareDynamicVariable<String>(name, _DVTypeString, defaultValue);
  }

  /// Create a bool dynamic variable with a specified [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeVariable] of type [bool] if no variable has been
  /// created before with this [name]. If an [ApptimizeVariable] already exists
  /// with this name it returns the existing [bool] variable but does not
  /// update the default value or [null] if it is not a [bool].
  ///
  /// The [name] and [defaultValue] must not be `null`.
  static Future<ApptimizeVariable<bool>?> declareBool(
      String name, bool defaultValue) async {
    return _declareDynamicVariable<bool>(name, _DVTypeBool, defaultValue);
  }

  /// Create a integer dynamic variable with a specified [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeVariable] of type [int] if no variable has been
  /// created before with this [name]. If an [ApptimizeVariable] already exists
  /// with this name it returns the existing [int] variable but does not
  /// update the default value or [null] if it is not an [int].
  ///
  /// The [name] and [defaultValue] must not be `null`.
  static Future<ApptimizeVariable<int>?> declareInteger(
      String name, int defaultValue) async {
    return _declareDynamicVariable<int>(name, _DVTypeInt, defaultValue);
  }

  /// Create a double dynamic variable with a specified [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeVariable] of type [double] if no variable has been
  /// created before with this [name]. If an [ApptimizeVariable] already exists
  /// with this name it returns the existing [double] variable but does not
  /// update the default value or [null] if it is not a [double].
  ///
  /// The [name] and [defaultValue] must not be `null`.
  static Future<ApptimizeVariable<double>?> declareDouble(
      String name, double defaultValue) async {
    return _declareDynamicVariable<double>(name, _DVTypeDouble, defaultValue);
  }

  /// Create a dynamic variable of an array containing strings with a specified
  /// [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeListVariable] of type [String] if no variable has
  /// been created before with this [name]. If an [ApptimizeVariable] already
  /// exists with this name it returns the existing list variable but does not
  /// update the default value or [null] if it is not a list of strings.
  ///
  /// The [name] and [defaultValue] must not be `null`.
  static Future<ApptimizeListVariable<String>?> declareStringArray(
      String name, List<String> defaultValue) async {
    return _declareDynamicListVariable<String>(
        name, _DVTypeArray + _DVTypeString, defaultValue);
  }

  /// Create a dynamic variable of an array containing booleans with a specified
  /// [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeListVariable] of type [bool] if no variable has
  /// been created before with this [name]. If an [ApptimizeVariable] already
  /// exists with this name it returns the existing list variable but does not
  /// update the default value or [null] if it is not a list of booleans.
  ///
  /// The [name] and [defaultValue] must not be `null`.
  static Future<ApptimizeListVariable<bool>?> declareBoolArray(
      String name, List<bool> defaultValue) async {
    return _declareDynamicListVariable<bool>(
        name, _DVTypeArray + _DVTypeBool, defaultValue);
  }

  /// Create a dynamic variable of an array containing integers with a specified
  /// [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeListVariable] of type [int] if no variable has
  /// been created before with this [name]. If an [ApptimizeVariable] already
  /// exists with this name it returns the existing list variable but does not
  /// update the default value  or [null] if it is not a list of integers.
  ///
  /// The [name] and [defaultValue] must not be null.
  static Future<ApptimizeListVariable<int>?> declareIntegerArray(
      String name, List<int> defaultValue) async {
    return _declareDynamicListVariable<int>(
        name, _DVTypeArray + _DVTypeInt, defaultValue);
  }

  /// Create a dynamic variable of an array containing doubles with a specified
  /// [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeListVariable] of type [double] if no variable has
  /// been created before with this [name]. If an [ApptimizeVariable] already
  /// exists with this name it returns the existing list variable but does not
  /// update the default value  or [null] if it is not a list of doubles.
  ///
  /// The [name] and [defaultValue] must not be null.
  static Future<ApptimizeListVariable<double>?> declareDoubleArray(
      String name, List<double> defaultValue) async {
    return _declareDynamicListVariable<double>(
        name, _DVTypeArray + _DVTypeDouble, defaultValue);
  }

  /// Create a dynamic variable of an map containing strings keyed by strings
  /// with a specified [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeMapVariable] of type [String] if no variable has
  /// been created before with this [name]. If an [ApptimizeVariable] already
  /// exists with this name it returns the existing map variable but does not
  /// update the default value  or [null] if it is not a string dictionary.
  ///
  /// The [name] and [defaultValue] must not be `null`.
  static Future<ApptimizeMapVariable<String>?> declareStringDictionary(
      String name, Map<String, String> defaultValue) async {
    return _declareDynamicMapVariable<String>(
        name, _DVTypeDictionary + _DVTypeString, defaultValue);
  }

  /// Create a dynamic variable of an map containing booleans keyed by strings
  /// with a specified [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeMapVariable] of type [bool] if no variable has
  /// been created before with this [name]. If an [ApptimizeVariable] already
  /// exists with this name it returns the existing map variable but does not
  /// update the default value  or [null] if it is not a boolean dictionary.
  ///
  /// The [name] and [defaultValue] must not be `null`.
  static Future<ApptimizeMapVariable<bool>?> declareBoolDictionary(
      String name, Map<String, bool> defaultValue) async {
    return _declareDynamicMapVariable<bool>(
        name, _DVTypeDictionary + _DVTypeBool, defaultValue);
  }

  /// Create a dynamic variable of an map containing integers keyed by strings
  /// with a specified [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeMapVariable] of type [int] if no variable has
  /// been created before with this [name]. If an [ApptimizeVariable] already
  /// exists with this name it returns the existing map variable but does not
  /// update the default value or [null] if it is not an integer dictionary.
  ///
  /// The [name] and [defaultValue] must not be `null`.
  static Future<ApptimizeMapVariable<int>?> declareIntegerDictionary(
      String name, Map<String, int> defaultValue) async {
    return _declareDynamicMapVariable<int>(
        name, _DVTypeDictionary + _DVTypeInt, defaultValue);
  }

  /// Create a dynamic variable of an map containing doubles keyed by strings
  /// with a specified [name] and [defaultValue].
  ///
  /// Returns a new [ApptimizeMapVariable] of type [double] if no variable has
  /// been created before with this [name]. If an [ApptimizeVariable] already
  /// exists with this name it returns the existing map variable but does not
  /// update the default value or [null] if it is not a double dictionary.
  ///
  /// The [name] and [defaultValue] must not be `null`.
  static Future<ApptimizeMapVariable<double>?> declareDoubleDictionary(
      String name, Map<String, double> defaultValue) async {
    return _declareDynamicMapVariable<double>(
        name, _DVTypeDictionary + _DVTypeDouble, defaultValue);
  }

  /// Retrieve a string dynamic variable of the specified [name] that has
  /// already been declared.
  ///
  /// [name] must not be null. If no string dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeValueVariable<String>?> getString(String name) async {
    return _getDynamicVariable<String>(name, _DVTypeString);
  }

  /// Retrieve a boolean dynamic variable of the specified [name] that has
  /// already been declared.
  ///
  /// [name] must not be null. If no boolean dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeValueVariable<bool>?> getBool(String name) async {
    return _getDynamicVariable<bool>(name, _DVTypeBool);
  }

  /// Retrieve a integer dynamic variable of the specified [name] that has
  /// already been declared.
  ///
  /// [name] must not be null. If no integer dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeValueVariable<int>?> getInteger(String name) async {
    return _getDynamicVariable<int>(name, _DVTypeInt);
  }

  /// Retrieve a double dynamic variable of the specified [name] that has
  /// already been declared.
  ///
  /// [name] must not be null. If no double dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeValueVariable<double>?> getDouble(String name) async {
    return _getDynamicVariable<double>(name, _DVTypeDouble);
  }

  /// Retrieve a list of strings dynamic variable of the specified [name] that
  /// has already been declared.
  ///
  /// [name] must not be null. If no string list dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeListVariable<String>?> getStringArray(
      String name) async {
    return _getDynamicListVariable<String>(name, _DVTypeArray + _DVTypeString);
  }

  /// Retrieve a list of booleans dynamic variable of the specified [name] that
  /// has already been declared.
  ///
  /// [name] must not be null. If no boolean list dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeListVariable<bool>?> getBoolArray(String name) async {
    return _getDynamicListVariable<bool>(name, _DVTypeArray + _DVTypeBool);
  }

  /// Retrieve a list of integers dynamic variable of the specified [name] that
  /// has already been declared.
  ///
  /// [name] must not be null. If no integer list dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeListVariable<int>?> getIntegerArray(
      String name) async {
    return _getDynamicListVariable<int>(name, _DVTypeArray + _DVTypeInt);
  }

  /// Retrieve a list of doubles dynamic variable of the specified [name] that
  /// has already been declared.
  ///
  /// [name] must not be null. If no double list dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeListVariable<double>?> getDoubleArray(
      String name) async {
    return _getDynamicListVariable<double>(name, _DVTypeArray + _DVTypeDouble);
  }

  /// Retrieve a map of strings dynamic variable of the specified [name] that
  /// has already been declared.
  ///
  /// [name] must not be null. If no string dictionary dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeMapVariable<String>?> getStringDictionary(
      String name) async {
    return _getDynamicMapVariable<String>(
        name, _DVTypeDictionary + _DVTypeString);
  }

  /// Retrieve a map of booleans dynamic variable of the specified [name] that
  /// has already been declared.
  ///
  /// [name] must not be null. If no boolean dictionary dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeMapVariable<bool>?> getBoolDictionary(
      String name) async {
    return _getDynamicMapVariable<bool>(name, _DVTypeDictionary + _DVTypeBool);
  }

  /// Retrieve a map of integers dynamic variable of the specified [name] that
  /// has already been declared.
  ///
  /// [name] must not be null. If no integer dictionary dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeMapVariable<int>?> getIntegerDictionary(
      String name) async {
    return _getDynamicMapVariable<int>(name, _DVTypeDictionary + _DVTypeInt);
  }

  /// Retrieve a map of doubles dynamic variable of the specified [name] that
  /// has already been declared.
  ///
  /// [name] must not be null. If no double dictionary dynamic variable has been declared
  /// with the specified name, this function returns `null`.
  static Future<ApptimizeMapVariable<double>?> getDoubleDictionary(
      String name) async {
    return _getDynamicMapVariable<double>(
        name, _DVTypeDictionary + _DVTypeDouble);
  }

  // Internals

  static Future<ApptimizeVariable<T>?> _declareDynamicVariable<T>(
      String name, String type, T defaultValue) async {
    final bool isDeclared =
        await Apptimize._declareDynamicVariable(name, type, defaultValue);
    if (isDeclared) {
      return new ApptimizeVariable<T>._(name, type);
    }

    return null;
  }

  static Future<ApptimizeListVariable<T>?> _declareDynamicListVariable<T>(
      String name, String type, List<T> defaultValue) async {
    final bool isDeclared =
        await Apptimize._declareDynamicVariable(name, type, defaultValue);
    if (isDeclared) {
      return new ApptimizeListVariable<T>._(name, type);
    }

    return null;
  }

  static Future<ApptimizeMapVariable<T>?> _declareDynamicMapVariable<T>(
      String name, String type, Map<String, T> defaultValue) async {
    final bool isDeclared =
        await Apptimize._declareDynamicVariable(name, type, defaultValue);
    if (isDeclared) {
      return new ApptimizeMapVariable<T>._(name, type);
    }

    return null;
  }

  static Future<ApptimizeValueVariable<T>?> _getDynamicVariable<T>(
      String name, String type) async {
    final bool isDeclared =
        await Apptimize._isDynamicVariableDeclared(name, type);
    if (isDeclared) {
      return new ApptimizeValueVariable<T>._(name, type);
    }

    return null;
  }

  static Future<ApptimizeListVariable<T>?> _getDynamicListVariable<T>(
      String name, String type) async {
    final bool isDeclared =
        await Apptimize._isDynamicVariableDeclared(name, type);
    if (isDeclared) {
      return new ApptimizeListVariable<T>._(name, type);
    }

    return null;
  }

  static Future<ApptimizeMapVariable<T>?> _getDynamicMapVariable<T>(
      String name, String type) async {
    final bool isDeclared =
        await Apptimize._isDynamicVariableDeclared(name, type);
    if (isDeclared) {
      return new ApptimizeMapVariable<T>._(name, type);
    }

    return null;
  }
}

/// Information about a single available variant.
class ApptimizeVariant {
  /// The name of the experiment associated with this variant
  final String experimentName;

  /// The numeric id of the experiment associated with this variant
  final int experimentId;

  /// The name of this variant
  final String variantName;

  /// The numeric id of this variant
  final int variantId;

  ApptimizeVariant(
      this.experimentName, this.experimentId, this.variantName, this.variantId);

  static ApptimizeVariant? _fromMap(Map<dynamic, dynamic> map) {
    final String? experimentName = map['experimentName'];
    final String? variantName = map['variantName'];
    final int? experimentId = map['experimentId'];
    final int? variantId = map['variantId'];

    if (variantId == null) {
      developer.log("Missing `variantId` in `ApptimizeVariant` map",
          name: Apptimize._logTag);
      return null;
    }
    if (variantName == null) {
      developer.log("Missing `variantName` in `ApptimizeVariant` map",
          name: Apptimize._logTag);
      return null;
    }
    if (experimentId == null) {
      developer.log("Missing `experimentId` in `ApptimizeVariant` map",
          name: Apptimize._logTag);
      return null;
    }
    if (experimentName == null) {
      developer.log("Missing `experimentName` in `ApptimizeVariant` map",
          name: Apptimize._logTag);
      return null;
    }

    return new ApptimizeVariant(
        experimentName, experimentId, variantName, variantId);
  }
}

/// Information about a single A/B test or feature flag this device is enrolled
/// in.
class ApptimizeTestInfo {
  /// The name of the test.
  final String testName;

  /// The name of the variant of the test that this device is enrolled in.
  final String enrolledVariantName;

  /// The unique numeric id of the test.
  final int testId;

  /// The unique numeric id of the currently enrolled test variant.
  final int enrolledVariantId;

  /// The date this Apptimize test was started.
  ///
  /// **Note** this is the time as reported by Apptimize's servers and is not
  /// affected by changes in the device's clock.
  final DateTime testStartedDate;

  /// The date this device was enrolled into this test.
  ///
  /// **Note** unlike the return value for [testStartedDate], this is the time
  /// as reported by the device, and not the time as reported by Apptimize's
  /// server. This difference is relevant if the device's clock is inaccurate.
  final DateTime testEnrolledDate;

  /// The cycle id of this test.
  ///
  /// This is 1 if it's the initial test run, and increments by 1 each time the
  /// test is restarted or if a non-proportional allocation change is made.
  final int cycle;

  /// The current phase of this test.
  ///
  /// This is 1 if the test has not been modified since creation, and increments
  /// by 1 each time the test is modified (such as when the test's allocations
  /// have been changed). The phase id does not reset when a test is restarted.
  final int currentPhase;

  /// The first phase in which this device participated in this test for this
  /// cycle.
  ///
  /// If this test has not been participated in during this cycle, this value
  /// will be 0.
  final int participationPhase;

  /// Has the user participated in this test in this cycle since enrollment.
  ///
  /// `true` if the user has participated in this test, or `false` if they have
  /// not.
  ///
  /// * For code block tests, this indicates that a codeblock has been executed
  ///   for this test.
  /// * For visual tests, this indicates that at least one changed element has
  ///   been seen.
  /// * For dynamic variable tests, this indicates that the value of a variable
  ///   has been queried.
  final bool userHasParticipated;

  /// The user id of the currently enrolled user.
  ///
  /// If the user has not been set then the anonymous user id is used.
  final String? userId;

  /// The anonymous user id currently assigned to this apptimize instance.
  final String anonymousUserId;

  /// The experiment type this test info represents.
  final ApptimizeExperimentType experimentType;

  const ApptimizeTestInfo(
      this.testName,
      this.enrolledVariantName,
      this.testId,
      this.enrolledVariantId,
      this.testStartedDate,
      this.testEnrolledDate,
      this.cycle,
      this.currentPhase,
      this.participationPhase,
      this.userHasParticipated,
      this.userId,
      this.anonymousUserId,
      this.experimentType);

  static ApptimizeTestInfo? _fromMap(Map<dynamic, dynamic> map) {
    final String? testName = map['testName'];
    final String? enrolledVariantName = map['enrolledVariantName'];
    final int? testId = map['testId'];
    final int? enrolledVariantId = map['enrolledVariantId'];
    final String? testStartedDateRaw = map['testStartedDate'];
    final DateTime? testStartedDate =
        testStartedDateRaw != null ? DateTime.parse(testStartedDateRaw) : null;
    final String? testEnrolledDateRaw = map['testEnrolledDate'];
    final DateTime? testEnrolledDate = testEnrolledDateRaw != null
        ? DateTime.parse(testEnrolledDateRaw)
        : null;
    final int? cycle = map['cycle'];
    final int? currentPhase = map['currentPhase'];
    final int? participationPhase = map['participationPhase'];
    final bool? userHasParticipated = map['userHasParticipated'];
    final String? userId = map['userId'];
    final String? anonymousUserId = map['anonymousUserId'];
    final String? apptimizeExperimentTypeName = map['experimentType'];
    final ApptimizeExperimentType experimentType =
        apptimizeExperimentTypeName.parseApptimizeExperimentType();

    if (testName == null) {
      developer.log("Missing `testName` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (enrolledVariantName == null) {
      developer.log("Missing `enrolledVariantName` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (testId == null) {
      developer.log("Missing `testId` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (enrolledVariantId == null) {
      developer.log("Missing `enrolledVariantId` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (testStartedDate == null) {
      developer.log("Missing `testStartedDate` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (testEnrolledDate == null) {
      developer.log("Missing `testEnrolledDate` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (cycle == null) {
      developer.log("Missing `cycle` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (currentPhase == null) {
      developer.log("Missing `currentPhase` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (participationPhase == null) {
      developer.log("Missing `participationPhase` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (userHasParticipated == null) {
      developer.log("Missing `userHasParticipated` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (anonymousUserId == null) {
      developer.log("Missing `anonymousUserId` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (apptimizeExperimentTypeName == null) {
      developer.log("Missing `experimentType` in `ApptimizeTestInfo` map",
          name: Apptimize._logTag);
      return null;
    }

    return new ApptimizeTestInfo(
        testName,
        enrolledVariantName,
        testId,
        enrolledVariantId,
        testStartedDate,
        testEnrolledDate,
        cycle,
        currentPhase,
        participationPhase,
        userHasParticipated,
        userId,
        anonymousUserId,
        experimentType);
  }
}

/// Options to configure apptimize. If you do not specify a value for an
/// option (and its value is `null`), the default value will be used.
class ApptimizeOptions {
  /// This option controls whether Apptimize will attempt to pair with the
  /// development server.
  bool? devicePairingEnabled;

  /// This option controls how long (in milliseconds) Apptimize will wait for
  /// tests and their associated data to download.
  int? delayUntilTestsAreAvailable;

  /// This option controls whether Apptimize will automatically import events
  /// from third-party analytics frameworks.
  bool? enableThirdPartyEventImporting;

  /// This option controls whether Apptimize will automatically export events to
  /// third-party analytics frameworks.
  bool? enableThirdPartyEventExporting;

  /// This option controls the amount of logging the Apptimize SDK will output.
  /// If not specified, the default value is [ApptimizeLogLevel.Off]
  ApptimizeLogLevel? logLevel;

  /// This option governs whether Apptimize will show winning variants and
  /// instant updates when [Apptimize.forceVariant] is used.
  bool? forceVariantsShowWinnersAndInstantUpdates;

  /// This option governs whether Apptimize will force a refresh on startup,
  /// even if metadata is currently saved on device. [ApptimizeInitializedEvent]
  /// will not be dispatched until the metadata has been downloaded. If metadata
  /// fails to download, [ApptimizeInitializedEvent] will dispatch only if there
  /// is a cached version of the data available on disk.
  bool? refreshMetaDataOnSetup;

  /// This option controls the Apptimize server region selection. You should not
  /// set this option unless your account is configured to use a different value.
  ApptimizeServerRegion? serverRegion;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = new Map<String, dynamic>();
    if (devicePairingEnabled != null)
      result['devicePairingEnabled'] = devicePairingEnabled;
    if (delayUntilTestsAreAvailable != null)
      result['delayUntilTestsAreAvailable'] = delayUntilTestsAreAvailable;
    if (enableThirdPartyEventImporting != null)
      result['enableThirdPartyEventImporting'] = enableThirdPartyEventImporting;
    if (enableThirdPartyEventExporting != null)
      result['enableThirdPartyEventExporting'] = enableThirdPartyEventExporting;
    if (forceVariantsShowWinnersAndInstantUpdates != null)
      result['forceVariantsShowWinnersAndInstantUpdates'] =
          forceVariantsShowWinnersAndInstantUpdates;
    if (logLevel != null)
      result['logLevel'] = logLevel.toString().split('.').last;
    if (serverRegion != null)
      result['serverRegion'] = serverRegion.toString().split('.').last;
    if (refreshMetaDataOnSetup != null) {
      result['refreshMetaDataOnSetup'] = refreshMetaDataOnSetup;
    }
    return result;
  }
}

/// This type is used to determine the state of the metadata.
class ApptimizeMetaDataState {
  /// Metadata is available, you can use Apptimize even though you may wish
  /// to wait for a refresh if [isRefreshing] is `true`.
  final bool isAvailable;

  /// Metadata has been recently updated. If this value is `false` and
  /// [isRefreshing] is also `false`, apptimize may not be able to update
  /// metadata.
  final bool isUpToDate;

  /// Metadata is currently being refreshed.
  final bool isRefreshing;

  const ApptimizeMetaDataState(
      this.isAvailable, this.isUpToDate, this.isRefreshing);
}

/// Information about a single winning A/B test or instant update this device
/// will display.
class ApptimizeInstantUpdateOrWinnerInfo {
  /// The date this device would start showing the winning variant or instant
  /// update.
  ///
  /// **Note** this is the time as reported by Apptimize's servers and is not
  /// affected by changes in the device's clock.
  final DateTime startDate;

  /// The user id of the user that will be shown the winning variant or instant
  /// update.
  ///
  /// If the user has not been set then the anonymous user id is used.
  final String? userId;

  /// The anonymous user id currently assigned to this apptimize instance.
  final String anonymousUserId;

  const ApptimizeInstantUpdateOrWinnerInfo(
    DateTime startDate,
    String? userId,
    String anonymousUserId
  ) : startDate = startDate, userId = userId, anonymousUserId = anonymousUserId;

  static ApptimizeInstantUpdateOrWinnerInfo? _fromMap(
      Map<dynamic, dynamic> map) {
    final bool? isInstantUpdate = map['isInstantUpdate'];
    final String? winningExperimentName = map['winningExperimentName'];
    final int? winningExperimentId = map['winningExperimentId'];
    final String? instantUpdateName = map['instantUpdateName'];
    final int? instantUpdateId = map['instantUpdateId'];
    final String? winningVariantName = map['winningVariantName'];
    final int? winningVariantId = map['winningVariantId'];
    final String? startDateRaw = map['startDate'];
    final DateTime? startDate =
        startDateRaw != null ? DateTime.parse(startDateRaw) : null;
    final String? userId = map['userId'];
    final String? anonymousUserId = map['anonymousUserId'];

    if (isInstantUpdate == null) {
      developer.log(
          "Missing `isInstantUpdate` in `ApptimizeInstantUpdateOrWinnerInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (startDate == null) {
      developer.log(
          "Missing `startDate` in `ApptimizeInstantUpdateOrWinnerInfo` map",
          name: Apptimize._logTag);
      return null;
    }
    if (anonymousUserId == null) {
      developer.log(
          "Missing `anonymousUserId` in `ApptimizeInstantUpdateOrWinnerInfo` map",
          name: Apptimize._logTag);
      return null;
    }

    if (isInstantUpdate) {
      if (instantUpdateName == null) {
        developer.log(
            "Missing `instantUpdateName` in `ApptimizeInstantUpdateOrWinnerInfo` map",
            name: Apptimize._logTag);
        return null;
      }
      if (instantUpdateId == null) {
        developer.log(
            "Missing `instantUpdateId` in `ApptimizeInstantUpdateOrWinnerInfo` map",
            name: Apptimize._logTag);
        return null;
      }
      return new ApptimizeInstantUpdate(
        instantUpdateName,
        instantUpdateId,
        startDate,
        userId,
        anonymousUserId);
    } else {
      if (winningExperimentName == null) {
        developer.log(
            "Missing `winningExperimentName` in `ApptimizeInstantUpdateOrWinnerInfo` map",
            name: Apptimize._logTag);
        return null;
      }
      if (winningExperimentId == null) {
        developer.log(
            "Missing `winningExperimentId` in `ApptimizeInstantUpdateOrWinnerInfo` map",
            name: Apptimize._logTag);
        return null;
      }
      if (winningVariantName == null) {
        developer.log(
            "Missing `winningVariantName` in `ApptimizeInstantUpdateOrWinnerInfo` map",
            name: Apptimize._logTag);
        return null;
      }
      if (winningVariantId == null) {
        developer.log(
            "Missing `winningVariantId` in `ApptimizeInstantUpdateOrWinnerInfo` map",
            name: Apptimize._logTag);
        return null;
      }
      return new ApptimizeWinnerInfo(
        winningExperimentName,
        winningExperimentId,
        winningVariantName,
        winningVariantId,
        startDate,
        userId,
        anonymousUserId);
    }
  }
}

/// Information about a single winning A/B test this device will display.
class ApptimizeWinnerInfo extends ApptimizeInstantUpdateOrWinnerInfo {
  /// The experiment name of the winning experiment.
  final String winningExperimentName;

  /// The experiment id of the winning experiment.
  final int winningExperimentId;

  /// The name of the winning variant.
  ///
  /// If this is a winner, then this is the name of the winning variant.
  /// Otherwise it is `null`.
  final String winningVariantName;

  /// The id of the winning variant
  ///
  /// If this is a winner, then this is the unique numeric id of the winning
  /// variant. Otherwise it is `null`.
  final int winningVariantId;

  const ApptimizeWinnerInfo(
    this.winningExperimentName,
    this.winningExperimentId,
    this.winningVariantName,
    this.winningVariantId,
    DateTime startDate,
    String? userId,
    String anonymousUserId
    ) : super(startDate, userId, anonymousUserId);
}

/// Information about a single instant update this device will display.
class ApptimizeInstantUpdate extends ApptimizeInstantUpdateOrWinnerInfo {
  /// The name of the instant update.
  final String instantUpdateName;

  /// The id of the instant update.
  final int instantUpdateId;

  const ApptimizeInstantUpdate(
    this.instantUpdateName,
    this.instantUpdateId,
    DateTime startDate,
    String? userId,
    String anonymousUserId
    ) : super(startDate, userId, anonymousUserId);
}

/// This enumerated type is used to indicate why the user has been unenrolled
/// from a given experiment.
enum ApptimizeUnenrollmentReason {
  /// The experiment has been stopped in the dashboard.
  ExperimentStopped,

  /// The experiment has been stopped and a winner selected in the dashboard.
  ExperimentWinnerSelected,

  /// The variant that the user has been enrolled in has changed, therefore the
  /// user has been unenrolled from the old variant.
  VariantChanged,

  /// The user id has been changed by calling the setUserId method.
  UserIdChanged,

  /// The user is no longer enrolled in the experiment for some other reason,
  /// such as a change in the device or custom properties.
  Other,

  /// The reason for unenrollment could not be determined.
  Unknown
}

/// This enumerated type is used to indicate the type of experiment that the
/// ApptimizeTestInfo class refers to.
enum ApptimizeExperimentType {
  /// The experiment type is a code block
  CodeBlock,

  /// The experiment type is a feature flag
  FeatureFlag,

  /// The experiment type is a dynamic variable
  DynamicVariables,

  /// The experiment is visual
  ///
  /// Note that visual experiments are not supported in flutter apps.
  Visual,

  /// The experiment type is unknown
  Unknown
}

/// This enumerated type is used to specify the log level to be used when
/// starting apptimize.
enum ApptimizeLogLevel {
  /// Log level option to show all possible logging output.
  Verbose,

  ///Log level option to show additional information to aid with debugging.
  Debug,

  /// Log level option to show information in addition to warnings and errors.
  Info,

  /// Log level option to show all warnings and errors.
  Warn,

  /// Log level option to show only errors.
  Error,

  /// Log level option to disable logging entirely. This is the default option.
  Off
}

/// This enumerated type is used to specify the server region to be used when
/// starting apptimize.
enum ApptimizeServerRegion {
  /// Use Apptimize default servers.
  Default,

  /// Set the apptimize server region to EU.
  EUCS
}

extension _ApptimizeEnumSerialization on String? {
  ApptimizeUnenrollmentReason parseApptimizeUnenrollmentReason() {
    return ApptimizeUnenrollmentReason.values.firstWhere(
        (e) =>
            e.toString().toLowerCase().split(".").last == this!.toLowerCase(),
        orElse: () => ApptimizeUnenrollmentReason.Unknown);
  }

  ApptimizeExperimentType parseApptimizeExperimentType() {
    return ApptimizeExperimentType.values.firstWhere(
        (e) =>
            e.toString().toLowerCase().split(".").last == this!.toLowerCase(),
        orElse: () => ApptimizeExperimentType.Unknown);
  }
}

// Callback definitions

/// Base class for all Apptimize events.
class ApptimizeEvent {}

/// Broadcasted when a user first becomes enrolled in a test.
///
/// [testInfo] contains the test info at the time of enrollment.
/// See [ApptimizeTestInfo]
class ApptimizeEnrolledInExperimentEvent extends ApptimizeEvent {
  final ApptimizeTestInfo testInfo;
  ApptimizeEnrolledInExperimentEvent(this.testInfo);
}

/// Broadcasted when an Apptimize A/B experiment is run.
///
/// [testInfo] contains the test info at the time of unenrollment.
/// [firstParticipation] is `true` if this is the first time the user has
/// participated in the test.
/// See [ApptimizeTestInfo]
class ApptimizeParticipatedInExperimentEvent extends ApptimizeEvent {
  final ApptimizeTestInfo testInfo;
  final bool firstParticipation;
  ApptimizeParticipatedInExperimentEvent(
      this.testInfo, this.firstParticipation);
}

/// Broadcasted when a user becomes unenrolled in a test.
///
/// [testInfo] contains the test info at the time of unenrollment.
/// [unenrollmentReason] indicates the reason the user was unenrollment.
/// See [ApptimizeTestInfo]
/// See [ApptimizeUnenrollmentReason]
class ApptimizeUnenrolledInExperimentEvent extends ApptimizeEvent {
  final ApptimizeTestInfo testInfo;
  final ApptimizeUnenrollmentReason unenrollmentReason;
  ApptimizeUnenrolledInExperimentEvent(this.testInfo, this.unenrollmentReason);
}

/// Broadcasted when Apptimize has finished initializing and tests are available
/// to run.
class ApptimizeInitializedEvent extends ApptimizeEvent {
  ApptimizeInitializedEvent();
}

/// Broadcasted when an Apptimize A/B experiment configuration is recalculated.
class ApptimizeTestsProcessedEvent extends ApptimizeEvent {
  ApptimizeTestsProcessedEvent();
}

/// Broadcasted in response to your application moving to the foreground.
///
/// If [willRefreshMetadata] is `true`, you can wait until you receive a
/// [ApptimizeMetadataStateChangedEvent] indicating that test information
/// is up to date.
class ApptimizeResumedEvent extends ApptimizeEvent {
  bool willRefreshMetadata;
  ApptimizeResumedEvent(this.willRefreshMetadata);
}

/// Broadcasted when Apptimize metadata state changes.
///
/// See the documentation for [ApptimizeMetadataStateChangedEvent] for more
/// information on the value in [metaDataState].
class ApptimizeMetadataStateChangedEvent extends ApptimizeEvent {
  final ApptimizeMetaDataState metaDataState;
  ApptimizeMetadataStateChangedEvent(this.metaDataState);
}
