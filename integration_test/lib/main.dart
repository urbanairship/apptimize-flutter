import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:apptimize_flutter/apptimize_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> _results = [];
  List<String> _notifications = [];
  List<ApptimizeEvent> _events = [];
  List<String> _messages = [];
  int _onApptimizeInitialized = 0;
  int _onEnrolledInExperiment = 0;
  int _onUnenrolledInExpriement = 0;
  int _onParticipated = 0;
  int _onResumed = 0;
  int _onMetadataStateChanged = 0;
  int _onTestsProcessed = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void addNotification(String result) {
    /*
    setState(() {
      _notifications.add(result);
      _messages = [_results, _notifications].expand((x) => x).toList();
    });
    */
  }

  int addResult(String result) {
    int count = 0;
    setState(() {
      count = _results.length;
      _results.add(result);
      _messages = [_results, _notifications].expand((x) => x).toList();
    });

    return count;
  }

  void updateResult(int index, String result) {
    setState(() {
      _results.removeAt(index);
      _results.insert(index, result);
      _messages = [_results, _notifications].expand((x) => x).toList();
    });
  }

  Future<void> onApptimizeInitialized(ApptimizeInitializedEvent e) async {
    setState(() {
      _onApptimizeInitialized++;
      _events.add(e);
    });
    addResult('🔔 onApptimizeInitialized');
    await runTests();
  }

  Future<void> onEnrolledInExperiment(
      ApptimizeEnrolledInExperimentEvent e) async {
    setState(() {
      _onEnrolledInExperiment++;
      _events.add(e);
    });
    addNotification(
        "🔔 onEnrolledInExperiment\n${e.testInfo.testName}.${e.testInfo.enrolledVariantName}");
  }

  Future<void> onUnenrolledInExpriement(
      ApptimizeUnenrolledInExperimentEvent e) async {
    setState(() {
      _onUnenrolledInExpriement++;
      _events.add(e);
    });
    addNotification(
        "🔔 onUnenrolledInExpriement\n${e.testInfo.testName}.${e.testInfo.enrolledVariantName}\n${e.unenrollmentReason}");
  }

  Future<void> onParticipated(ApptimizeParticipatedInExperimentEvent e) async {
    setState(() {
      _onParticipated++;
      _events.add(e);
    });
    addNotification(
        "🔔 onParticipated\nFirst participation: ${e.firstParticipation}\n${e.testInfo.testName}.${e.testInfo.enrolledVariantName}");
  }

  Future<void> onResumed(ApptimizeResumedEvent e) async {
    setState(() {
      _onResumed++;
      _events.add(e);
    });
    addNotification(
        "🔔 onResumed(willRefreshMetadata: ${e.willRefreshMetadata})");
  }

  Future<void> onMetadataStateChanged(
      ApptimizeMetadataStateChangedEvent e) async {
    setState(() {
      _onMetadataStateChanged++;
      _events.add(e);
    });
    addNotification(
        "🔔 onMetadataStateChanged(isAvailable: ${e.metaDataState.isAvailable}, isRefreshing: ${e.metaDataState.isRefreshing}, isUpToDate: ${e.metaDataState.isUpToDate})");
  }

  Future<void> onTestsProcessed(ApptimizeTestsProcessedEvent e) async {
    setState(() {
      _onTestsProcessed++;
      _events.add(e);
    });
    addNotification("🔔 onTestsProcessed");
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    Apptimize.apptimizeInitializedStream
        .listen((event) => {onApptimizeInitialized(event)});
    Apptimize.apptimizeEnrolledInExperimentStream
        .listen((event) => {onEnrolledInExperiment(event)});
    Apptimize.apptimizeUnenrolledInExperimentStream
        .listen((event) => {onUnenrolledInExpriement(event)});
    Apptimize.apptimizeParticipatedInExperimentStream
        .listen((event) => {onParticipated(event)});
    Apptimize.apptimizeResumedStream.listen((event) => {onResumed(event)});
    Apptimize.apptimizeMetadataStateChangedStream
        .listen((event) => {onMetadataStateChanged(event)});
    Apptimize.apptimizeTestsProcessedStream
        .listen((event) => {onTestsProcessed(event)});

    String platformVersion = "Well...";
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Apptimize.libraryVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    addResult("Apptimize $platformVersion");

    // Now start apptimize?
    try {
      var options = new ApptimizeOptions();
      options.logLevel = ApptimizeLogLevel.Verbose;
      options.serverRegion = ApptimizeServerRegion.Default;
      options.delayUntilTestsAreAvailable = 500;
      options.refreshMetaDataOnSetup = true;
      Apptimize.startApptimize("bCGAPNeNfdqGdcTPNciN86a56rezJQ", options);
    } on PlatformException {
      addResult('Failed to initialize apptimize.');
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle statusStyle =
        TextStyle(fontSize: 10, fontFeatures: [FontFeature.tabularFigures()]);

    return MaterialApp(
        home: Scaffold(
            extendBody: true,
            appBar: AppBar(
                title: Column(
              children: [
                Text('Plugin Integration Tests app'),
                Row(
                  children: [
                    Expanded(
                        child: Text('inited: $_onApptimizeInitialized',
                            style: statusStyle)),
                    Expanded(
                        child:
                            Text('resumed: $_onResumed', style: statusStyle)),
                    Expanded(
                        child: Text('testsProcd: $_onTestsProcessed',
                            style: statusStyle)),
                    Expanded(
                        child: Text('mdataState: $_onMetadataStateChanged',
                            style: statusStyle)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                        child: Text('enrolled: $_onEnrolledInExperiment',
                            style: statusStyle)),
                    Expanded(
                        child: Text('unenrolled: $_onUnenrolledInExpriement',
                            style: statusStyle)),
                    Expanded(
                        child: Text('participated: $_onParticipated',
                            style: statusStyle)),
                  ],
                )
              ],
            )),
            body: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    margin: EdgeInsets.all(2),
                    color: index % 2 == 1 ? Colors.white70 : Colors.white,
                    child: Text(
                      '${_messages[index]}',
                      style: TextStyle(
                          fontSize: 14,
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  );
                })));
  }

  Future<void> runTests() async {
    var tests = {
      'testGetSetCustomerUserId': testGetSetCustomerUserId,
      'testClearCustomerUserId': testClearCustomerUserId,
      'testApptimizeAnonUserId': testApptimizeAnonUserId,
      'testMetadataState': testMetadataState,
      'testTrack': testTrack,
      'testTrackValue': testTrackValue,
      'testRunTestExpectBaseline': testRunTestExpectBaseline,
      'testRunTestExpectVariant': testRunTestExpectVariant,
      'testFeatureFlagIsOn': testFeatureFlagIsOn,
      'testFeatureFlagIsOff': testFeatureFlagIsOff,
      'testGetApptimizeTestInfo': testGetApptimizeTestInfo,
      'testGetInstantUpdateAndWinnerInfo': testGetInstantUpdateAndWinnerInfo,
      'testGetSetUserAttribute': testGetSetUserAttribute,
      'testRemoveUserAttribute': testRemoveUserAttribute,
      'testRemoveAllUserAttributes': testRemoveAllUserAttributes,
      'testGetVariants': testGetVariants,
      'testForceVariant': testForceVariant,

      'testDeclareVariables': testDeclareVariables,
      'testGetVariables': testGetVariables,

      // This one should come after 'testDeclareVariables' as a dependency.
      'testGetVariableValues': testGetVariableValues,

      'testApptimizeInitializedEvent': testApptimizeInitializedEvent,
      'testApptimizeResumedEvent': testApptimizeResumedEvent,
      'testApptimizeTestsProcessedEvent': testApptimizeTestsProcessedEvent,
      'testApptimizeMetadataStateChangedEvent':
          testApptimizeMetadataStateChangedEvent,
      'testApptimizeEnrolledInExperimentEvent':
          testApptimizeEnrolledInExperimentEvent,
      'testApptimizeParticipatedInExperimentEvent':
          testApptimizeParticipatedInExperimentEvent,
      'testApptimizeUnenrolledInExperimentEvent':
          testApptimizeUnenrolledInExperimentEvent,

      'testGetSetPilotTargetingId': this.testGetSetPilotTargetingId,

      // Do this one manually.
      //'testSetOffline': this.testSetOffline,

      // Do this one manually since you can't undo it (and it would disable the metadata updates)
      // 'testDisable': this.testDisable
    };

    // Setup
    await Apptimize.clearAllForcedVariants();
    await Apptimize.setCustomerUserId(null);
    await Apptimize.removeUserAttribute("uabool");
    await Apptimize.removeUserAttribute("uadbl");
    await Apptimize.removeUserAttribute("uaint");
    await Apptimize.removeUserAttribute("uastr");

    var index = 0;
    var failCount = 0;
    var error = "";
    for (var test in tests.entries) {
      index++;
      var label = "[$index/${tests.length}] ${test.key}";
      var resultIndex = addResult(label);

      var result = true;
      try {
        await test.value();
      } catch (e) {
        result = false;
        error = e.toString();
      }

      label += result ? ' ✅' : ' ❌';
      updateResult(resultIndex, label);

      if (!result) {
        addResult(error);
      }

      if (!result) {
        failCount++;
      }
    }

    addResult("${tests.length} tests run.");
    addResult("${tests.length - failCount} tests passed.");

    if (failCount == 0) {
      addResult("🎉 All tests passing!");
    } else {
      addResult("$failCount tests failed.");
    }
  }

  Future<void> testGetSetCustomerUserId() async {
    var testValue = "testCustomerUserId";

    await Apptimize.setCustomerUserId(testValue);
    var result = await Apptimize.customerUserId;

    assertEqual(testValue, result);
  }

  Future<void> testClearCustomerUserId() async {
    var testValue = "goomba";

    await Apptimize.setCustomerUserId(testValue);
    var result = await Apptimize.customerUserId;
    assertEqual(testValue, result);

    await Apptimize.setCustomerUserId(null);
    result = await Apptimize.customerUserId;
    assertNull(result);
  }

  Future<void> testApptimizeAnonUserId() async {
    var result = await Apptimize.apptimizeAnonUserId;
    assertNotNull(result);
  }

  Future<void> testSetOffline() async {
    await Apptimize.setOffline(true);
    var result = await Apptimize.offline;
    assertTrue(result, "Offline flag should be true");

    await Apptimize.setOffline(false);
    result = await Apptimize.offline;
    assertFalse(result, "Offline flag should be false");
  }

  Future<void> testMetadataState() async {
    var result = await Apptimize.metadataState;
    assertNotNull(result, "Metadata state failed to retrieve");
    assertTrue(result.isAvailable, "Metadata is not available");
  }

  Future<void> testTrack() async {
    await Apptimize.track("testTrack");
  }

  Future<void> testTrackValue() async {
    await Apptimize.track("trackTrackValue", 1.234);
  }

  Future<void> testLibraryVersion() async {
    var result = await Apptimize.libraryVersion;
    assertNotNull(result);
  }

  Future<void> testGetSetPilotTargetingId() async {
    var testValue = "ptid-42";
    await Apptimize.setPilotTargetingId(testValue);
    var result = await Apptimize.pilotTargetingId;

    assertEqual(testValue, result);
  }

  Future<void> testRunTestExpectBaseline() async {
    String variation;
    String expected = 'baseline';

    await Apptimize.runTest("invalidTestName", () => {variation = 'baseline'}, {
      'variation1': () => {variation = 'variation1'},
    });

    assertEqual(expected, variation);
  }

  Future<void> testRunTestExpectVariant() async {
    String variation;
    String expected = 'variation1';

    await Apptimize.setCustomerUserId("fooman");

    await Apptimize.runTest(
        "FlutterCodeBlockTest", () => {variation = 'baseline'}, {
      'variation1': () => {variation = 'variation1'},
      'variation2': () => {variation = 'variation2'},
    });

    await Apptimize.setCustomerUserId(null);

    assertEqual(expected, variation);
  }

  Future<void> testFeatureFlagIsOn() async {
    var result = await Apptimize.isFeatureFlagOn('new_feature_flag_variable_4');
    assertTrue(result, "Feature flag should be on");
  }

  Future<void> testFeatureFlagIsOff() async {
    var result = await Apptimize.isFeatureFlagOn('feature_flag_does_not_exist');
    assertFalse(result, "Feature flag should be off");
  }

  Future<void> testGetApptimizeTestInfo() async {
    var result = await Apptimize.apptimizeTestInfo;

    assertFalse(result.isEmpty, "There were no result in apptimize test info");

    var firstEntry = result.entries.first;
    assertEqual(firstEntry.key, firstEntry.value.testName,
        "Key does not match test name");
    assertTrue(result.containsKey('FlutterFeatureFlagOn'),
        "Result expected to contain 'FlutterFeatureFlagOn'");
  }

  Future<void> testGetInstantUpdateAndWinnerInfo() async {
    var result = await Apptimize.instantUpdateAndWinnerInfo;
    assertFalse(result.isEmpty,
        "There were no result in apptimize instant update and winner info");
    assertTrue(result.containsKey('FlutterCodeBlockTest'),
        "Result expected to contain 'FlutterCodeBlockTest'");

    var fcbt = result['FlutterCodeBlockTest'];
    assertFalse(fcbt.isInstantUpdate, "isInstantUpdate");
    assertTrue(fcbt.instantUpdateName == null || fcbt.instantUpdateName.isEmpty,
        "instantUpdateName is not empty");
    assertEqual(1599869, fcbt.winningExperimentId, "winningExperimentId");
    assertEqual('FlutterCodeBlockTest', fcbt.winningExperimentName,
        "winningExperimentName");
    assertEqual(5259302, fcbt.winningVariantId, "winningVariantId");
    assertEqual('Variant B', fcbt.winningVariantName, "winningVariantName");
  }

  Future<void> testGetSetUserAttribute() async {
    var expectBool = true;
    var expectDouble = 492.312;
    var expectInt = 42;
    var expectStr = "The Hitchiker's Guide to the Galaxy";

    await Apptimize.setUserAttributeBool("uabool", expectBool);
    await Apptimize.setUserAttributeDouble("uadbl", expectDouble);
    await Apptimize.setUserAttributeInteger("uaint", expectInt);
    await Apptimize.setUserAttributeString("uastr", expectStr);

    var resultBool = await Apptimize.getUserAttributeBool("uabool");
    var resultDouble = await Apptimize.getUserAttributeDouble("uadbl");
    var resultInt = await Apptimize.getUserAttributeInteger("uaint");
    var resultStr = await Apptimize.getUserAttributeString("uastr");

    await Apptimize.removeUserAttribute("uabool");
    await Apptimize.removeUserAttribute("uadbl");
    await Apptimize.removeUserAttribute("uaint");
    await Apptimize.removeUserAttribute("uastr");

    assertEqual(expectBool, resultBool);
    assertEqual(expectDouble, resultDouble);
    assertEqual(expectInt, resultInt);
    assertEqual(expectStr, resultStr);
  }

  Future<void> testRemoveUserAttribute() async {
    var expectBool = true;
    var expectDouble = 492.312;
    var expectInt = 42;
    var expectStr = "The Hitchiker's Guide to the Galaxy";

    await Apptimize.setUserAttributeBool("uabool", expectBool);
    await Apptimize.setUserAttributeDouble("uadbl", expectDouble);
    await Apptimize.setUserAttributeInteger("uaint", expectInt);
    await Apptimize.setUserAttributeString("uastr", expectStr);

    // Make sure they got set
    {
      var resultBool = await Apptimize.getUserAttributeBool("uabool");
      var resultDouble = await Apptimize.getUserAttributeDouble("uadbl");
      var resultInt = await Apptimize.getUserAttributeInteger("uaint");
      var resultStr = await Apptimize.getUserAttributeString("uastr");

      assertEqual(expectBool, resultBool);
      assertEqual(expectDouble, resultDouble);
      assertEqual(expectInt, resultInt);
      assertEqual(expectStr, resultStr);
    }

    // Remove one and test.
    {
      await Apptimize.removeUserAttribute("uastr");
      var resultBool = await Apptimize.getUserAttributeBool("uabool");
      var resultDouble = await Apptimize.getUserAttributeDouble("uadbl");
      var resultInt = await Apptimize.getUserAttributeInteger("uaint");
      var resultStr = await Apptimize.getUserAttributeString("uastr");

      assertEqual(true, resultBool);
      assertFalse(0 == resultDouble, "Double should not be zero");
      assertFalse(0 == resultInt, "Int should not be zero");
      assertNull(resultStr);
    }

    await Apptimize.removeUserAttribute("uabool");
    await Apptimize.removeUserAttribute("uadbl");
    await Apptimize.removeUserAttribute("uaint");
    await Apptimize.removeUserAttribute("uastr");
  }

  Future<void> testRemoveAllUserAttributes() async {
    if (Platform.isAndroid) {
      addResult(
          "🟠 Skipped: removeAllUserAttributes is not available on Android");
      return;
    }

    var expectBool = true;
    var expectDouble = 492.312;
    var expectInt = 42;
    var expectStr = "The Hitchiker's Guide to the Galaxy";

    await Apptimize.setUserAttributeBool("uabool", expectBool);
    await Apptimize.setUserAttributeDouble("uadbl", expectDouble);
    await Apptimize.setUserAttributeInteger("uaint", expectInt);
    await Apptimize.setUserAttributeString("uastr", expectStr);

    // Make sure they got set
    {
      var resultBool = await Apptimize.getUserAttributeBool("uabool");
      var resultDouble = await Apptimize.getUserAttributeDouble("uadbl");
      var resultInt = await Apptimize.getUserAttributeInteger("uaint");
      var resultStr = await Apptimize.getUserAttributeString("uastr");

      assertEqual(expectBool, resultBool);
      assertEqual(expectDouble, resultDouble);
      assertEqual(expectInt, resultInt);
      assertEqual(expectStr, resultStr);
    }

    // Remove all and test.
    {
      await Apptimize.removeAllUserAttributes();
      var resultBool = await Apptimize.getUserAttributeBool("uabool");
      var resultDouble = await Apptimize.getUserAttributeDouble("uadbl");
      var resultInt = await Apptimize.getUserAttributeInteger("uaint");
      var resultStr = await Apptimize.getUserAttributeString("uastr");

      assertEqual(false, resultBool);
      assertEqual(0, resultDouble);
      assertEqual(0, resultInt);
      assertNull(resultStr);
    }
  }

  Future<void> testGetVariants() async {
    var variants = await Apptimize.getVariants();
    if (!variants.keys.contains(5259307)) throw "Variants must contain 5259307";
    if (!variants.keys.contains(5259308)) throw "Variants must contain 5259308";
    if (!variants.keys.contains(5259309)) throw "Variants must contain 5259309";

    assertEqual(
        "Forced", variants[5259309].variantName, "Unexpected variantName");
    assertEqual(5259309, variants[5259309].variantId, "Unexpected variantId");
    assertEqual("FlutterForceVariantTest", variants[5259309].experimentName,
        "Unexpected experimentName");
    assertEqual(
        1599871, variants[5259309].experimentId, "Unexpected experimentId");
  }

  Future<void> testForceVariant() async {
    await Apptimize.clearAllForcedVariants();
    var originalVariation = "error";
    await Apptimize.runTest(
        "FlutterForceVariantTest", () => {originalVariation = 'baseline'}, {
      'variation1': () => {originalVariation = 'variation1'},
      'variation2': () => {originalVariation = 'variation2'},
    });

    await Apptimize.forceVariant(5259307);

    var firstVariation = "error";
    await Apptimize.runTest(
        "FlutterForceVariantTest", () => {firstVariation = 'baseline'}, {
      'variation1': () => {firstVariation = 'variation1'},
      'variation2': () => {firstVariation = 'variation2'},
    });

    await Apptimize.clearAllForcedVariants();
    await Apptimize.forceVariant(5259308);

    var secondVariation = "error";
    await Apptimize.runTest(
        "FlutterForceVariantTest", () => {secondVariation = 'baseline'}, {
      'variation1': () => {secondVariation = 'variation1'},
      'variation2': () => {secondVariation = 'variation2'},
    });

    await Apptimize.clearAllForcedVariants();
    var thirdVariation = "error";
    await Apptimize.runTest(
        "FlutterForceVariantTest", () => {thirdVariation = 'baseline'}, {
      'variation1': () => {thirdVariation = 'variation1'},
      'variation2': () => {thirdVariation = 'variation2'},
    });

    assertEqual("baseline", firstVariation, "Couldn't force baseline");
    assertEqual("variation1", secondVariation, "Couldn't force variation2");
    assertEqual(
        originalVariation, thirdVariation, "Clear forced variants didn't work");
  }

  Future<void> testDeclareVariables() async {
    var boolValue = await ApptimizeVariable.declareBool("flutterBool", false);
    var boolArrayValue =
        await ApptimizeVariable.declareBoolArray("flutterBoolArray", []);
    var boolDictValue =
        await ApptimizeVariable.declareBoolDictionary("flutterBoolDict", {});

    var intValue = await ApptimizeVariable.declareInteger("flutterInt", -99);
    var intArrayValue =
        await ApptimizeVariable.declareIntegerArray("flutterIntArray", []);
    var intDictValue =
        await ApptimizeVariable.declareIntegerDictionary("flutterIntDict", {});

    var doubleValue =
        await ApptimizeVariable.declareDouble("flutterDouble", -99.99);
    var doubleArrayValue =
        await ApptimizeVariable.declareDoubleArray("flutterDoubleArray", []);
    var doubleDictValue = await ApptimizeVariable.declareDoubleDictionary(
        "flutterDoubleDict", {});

    var stringValue =
        await ApptimizeVariable.declareString("flutterString", "default");
    var stringArrayValue =
        await ApptimizeVariable.declareStringArray("flutterStringArray", []);
    var stringDictValue = await ApptimizeVariable.declareStringDictionary(
        "flutterStringDict", {});

    assertNotNull(boolValue, "boolValue");
    assertNotNull(boolArrayValue, "boolArrayValue");
    assertNotNull(boolDictValue, "boolDictValue");

    assertNotNull(intValue, "intValue");
    assertNotNull(intArrayValue, "intArrayValue");
    assertNotNull(intDictValue, "intDictValue");

    assertNotNull(doubleValue, "doubleValue");
    assertNotNull(doubleArrayValue, "doubleArrayValue");
    assertNotNull(doubleDictValue, "doubleDictValue");

    assertNotNull(stringValue, "stringValue");
    assertNotNull(stringArrayValue, "stringArrayValue");
    assertNotNull(stringDictValue, "stringDictValue");
  }

  Future<void> testGetVariables() async {
    var boolValue = await ApptimizeVariable.getBool("flutterBool");
    var boolArrayValue =
        await ApptimizeVariable.getBoolArray("flutterBoolArray");
    var boolDictValue =
        await ApptimizeVariable.getBoolDictionary("flutterBoolDict");

    var intValue = await ApptimizeVariable.getInteger("flutterInt");
    var intArrayValue =
        await ApptimizeVariable.getIntegerArray("flutterIntArray");
    var intDictValue =
        await ApptimizeVariable.getIntegerDictionary("flutterIntDict");

    var doubleValue = await ApptimizeVariable.getDouble("flutterDouble");
    var doubleArrayValue =
        await ApptimizeVariable.getDoubleArray("flutterDoubleArray");
    var doubleDictValue =
        await ApptimizeVariable.getDoubleDictionary("flutterDoubleDict");

    var stringValue = await ApptimizeVariable.getString("flutterString");
    var stringArrayValue =
        await ApptimizeVariable.getStringArray("flutterStringArray");
    var stringDictValue =
        await ApptimizeVariable.getStringDictionary("flutterStringDict");

    var boolValueInvalid =
        await ApptimizeVariable.getBool("flutterBoolInvalidName");

    assertNotNull(boolValue, "boolValue");
    assertNotNull(boolArrayValue, "boolArrayValue");
    assertNotNull(boolDictValue, "boolDictValue");

    assertNotNull(intValue, "intValue");
    assertNotNull(intArrayValue, "intArrayValue");
    assertNotNull(intDictValue, "intDictValue");

    assertNotNull(doubleValue, "doubleValue");
    assertNotNull(doubleArrayValue, "doubleArrayValue");
    assertNotNull(doubleDictValue, "doubleDictValue");

    assertNotNull(stringValue, "stringValue");
    assertNotNull(stringArrayValue, "stringArrayValue");
    assertNotNull(stringDictValue, "stringDictValue");

    assertNull(boolValueInvalid,
        "flutterBoolInvalidName should not return a variable");
  }

  Future<void> testGetVariableValues() async {
    // Force a variant we know the values of.
    Apptimize.clearAllForcedVariants();
    Apptimize.forceVariant(5259311);

    var boolValue = await ApptimizeVariable.getBool("flutterBool");
    var boolArrayValue =
        await ApptimizeVariable.getBoolArray("flutterBoolArray");
    var boolDictValue =
        await ApptimizeVariable.getBoolDictionary("flutterBoolDict");

    var intValue = await ApptimizeVariable.getInteger("flutterInt");
    var intArrayValue =
        await ApptimizeVariable.getIntegerArray("flutterIntArray");
    var intDictValue =
        await ApptimizeVariable.getIntegerDictionary("flutterIntDict");

    var doubleValue = await ApptimizeVariable.getDouble("flutterDouble");
    var doubleArrayValue =
        await ApptimizeVariable.getDoubleArray("flutterDoubleArray");
    var doubleDictValue =
        await ApptimizeVariable.getDoubleDictionary("flutterDoubleDict");

    var stringValue = await ApptimizeVariable.getString("flutterString");
    var stringArrayValue =
        await ApptimizeVariable.getStringArray("flutterStringArray");
    var stringDictValue =
        await ApptimizeVariable.getStringDictionary("flutterStringDict");

    assertEqual(true, await boolValue.value, "flutterBool");
    assertEqualElements(
        [true, true, false], await boolArrayValue.value, "flutterBoolArray");
    assertEqualMaps({"red": false, "green": true}, await boolDictValue.value,
        "flutterBoolDict");

    assertEqual(98, await intValue.value, "flutterInt");
    assertEqualElements(
        [1, 2, 3], await intArrayValue.value, "flutterIntArray");
    assertEqualMaps({"games": 55, "movies": 22}, await intDictValue.value,
        "flutterIntDict");

    assertEqual(42.0, await doubleValue.value, "flutterDouble");
    assertEqualElements(
        [123.321, 321.123], await doubleArrayValue.value, "flutterDoubleArray");
    assertEqualMaps({"c": 0.1, "f": 32.1}, await doubleDictValue.value,
        "flutterDoubleDict");

    assertEqual("galaxy", await stringValue.value, "flutterString");
    assertEqualElements(["one", "two", "three"], await stringArrayValue.value,
        "flutterBoolArray");
    assertEqualMaps({"game": "Final Fantasy", "movie": "Star Trek"},
        await stringDictValue.value, "flutterDictArray");
  }

  Future<void> testApptimizeInitializedEvent() async {
    assertAny(_events, (x) => x is ApptimizeInitializedEvent);
  }

  Future<void> testApptimizeResumedEvent() async {
    if (Platform.isAndroid) {
      addResult(
          "🟠 Skipped: ApptimizeResumedEvent is not fired on Android until application is backgrounded");
      return;
    }

    assertAny(_events, (x) => x is ApptimizeResumedEvent);
  }

  Future<void> testApptimizeTestsProcessedEvent() async {
    assertAny(_events, (x) => x is ApptimizeTestsProcessedEvent);
  }

  Future<void> testApptimizeMetadataStateChangedEvent() async {
    assertAny(_events, (x) => x is ApptimizeMetadataStateChangedEvent);
  }

  Future<void> testApptimizeEnrolledInExperimentEvent() async {
    assertAny(_events, (x) => x is ApptimizeEnrolledInExperimentEvent);
  }

  Future<void> testApptimizeParticipatedInExperimentEvent() async {
    assertAny(_events, (x) => x is ApptimizeParticipatedInExperimentEvent);
  }

  Future<void> testApptimizeUnenrolledInExperimentEvent() async {
    assertAny(_events, (x) => x is ApptimizeUnenrolledInExperimentEvent);
  }

  Future<void> testDisable() async {
    await Apptimize.disable();
  }

  void assertAny<T>(List<T> list, bool Function(T) test, [String message]) {
    if (!list.any(test)) {
      var error = "$message\n" ?? "";
      throw "$error❌ List did not contain expected element.\n";
    }
  }

  void assertTrue(bool actual, [String message]) {
    if (!actual) {
      var error = "$message\n" ?? "";
      throw "$error❌ Value should be true.\n";
    }
  }

  void assertFalse(bool actual, [String message]) {
    if (actual) {
      var error = "$message\n" ?? "";
      throw "$error❌ Value should be false.\n";
    }
  }

  void assertEqual<T>(T expected, T actual, [String message]) {
    if (expected != actual) {
      var error =
          "❌ ${expected.runtimeType}s not equal.\n  Expected: $expected\n  Got: $actual\n";

      if (message != null) {
        error = "$message\n$error";
      }

      throw error;
    }
  }

  void assertEqualElements<T>(List<T> expected, List<T> actual,
      [String message]) {
    if (expected.length != actual.length) {
      var error = "$message\n" ?? "";
      throw "$error❌ Lists not of equal length.\n  Expected: ${expected.length}\n  Got: ${actual.length}\n";
    }

    for (int i = 0; i < expected.length; i++) {
      if (expected[i] != actual[i]) {
        var error = "$message\n" ?? "";
        throw "$error❌ Lists do not contain same elements.\n  Expected: ${expected.join(", ")}\n  Got: ${actual.join(", ")}\n";
      }
    }
  }

  void assertEqualMaps<T>(Map<String, T> expected, Map<String, T> actual,
      [String message]) {
    if (expected.length != actual.length) {
      var error = "$message\n" ?? "";
      throw "$error❌ Maps not of equal length.\n  Expected: ${expected.length}\n  Got: ${actual.length}\n";
    }

    for (var key in expected.keys) {
      if (expected[key] != actual[key]) {
        var error = "$message\n" ?? "";
        throw "$error❌ Maps do not contain same elements.\n  Expected: ${expected.entries.join(", ")}\n  Got: ${actual.entries.join(", ")}\n";
      }
    }
  }

  void assertNotNull<T>(T actual, [String message]) {
    if (actual == null) {
      var error = "❌ Value was null.\n  Expected: Not null";

      if (message != null) {
        error = "$message\n$error";
      }

      throw error;
    }
  }

  void assertNull<T>(T actual, [String message]) {
    if (actual != null) {
      var error = "❌ Value was not null.\n  Expected: Null\n  Actual: $actual";

      if (message != null) {
        error = "$message\n$error";
      }

      throw error;
    }
  }
}
