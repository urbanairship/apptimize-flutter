package com.apptimize.apptimize_flutter;

import android.content.Context;
import android.util.Log;

import com.apptimize.Apptimize;
import com.apptimize.ApptimizeInstantUpdateOrWinnerInfo;
import com.apptimize.ApptimizeOptions;
import com.apptimize.ApptimizeTest;
import com.apptimize.ApptimizeTestInfo;
import com.apptimize.ApptimizeTestType;
import com.apptimize.ApptimizeVar;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

class InvalidPluginArgumentException extends Exception {
  public InvalidPluginArgumentException(String argument, String value) {
    super("Invalid ApptimizeFlutterPlugin argument value '" + value + "' for '" + argument + "'");
  }
}
class MissingPluginArgumentException extends Exception {
  public MissingPluginArgumentException(String argument) {
    super("Missing ApptimizeFlutterPlugin argument '" + argument + "'");
  }
}

/** ApptimizeFlutterPlugin */
public class ApptimizeFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context context = null;

  private static boolean isOffline = false;
  private static final String TAG = "ApptimizeFlutterPlugin";
  private static ConcurrentHashMap<String, Object> declaredApptimizeVariables = new ConcurrentHashMap<String, Object>();
  private static CopyOnWriteArrayList<MethodChannel> allChannels = new CopyOnWriteArrayList<>();

  static {
    Apptimize.addMetadataStateChangedListener(new Apptimize.MetadataStateChangedListener() {
      @Override
      public void onMetadataStateChanged(EnumSet<Apptimize.ApptimizeMetadataStateFlags> enumSet) {
        HashMap arguments = new HashMap();
        arguments.put("isAvailable", enumSet.contains(Apptimize.ApptimizeMetadataStateFlags.AVAILABLE));
        arguments.put("isUpToDate", enumSet.contains(Apptimize.ApptimizeMetadataStateFlags.UP_TO_DATE));
        arguments.put("isRefreshing", enumSet.contains(Apptimize.ApptimizeMetadataStateFlags.REFRESHING));
        for (MethodChannel channel : allChannels) {
          channel.invokeMethod("ApptimizeMetadataStateChanged", arguments, null);
        }
      }

      @Override
      public void onApptimizeForegrounded(boolean b) {
        HashMap arguments = new HashMap();
        arguments.put("willRefreshMetadata", b);
        for (MethodChannel channel : allChannels) {
          channel.invokeMethod("ApptimizeResumed", arguments, null);
        }
      }
    });

    Apptimize.addOnExperimentsProcessedListener(new Apptimize.OnExperimentsProcessedListener() {
      @Override
      public void onExperimentsProcessed() {
        for (MethodChannel channel : allChannels) {
          channel.invokeMethod("ApptimizeTestsProcessed", null, null);
        }
      }
    });

    Apptimize.setOnApptimizeInitializedListener(new Apptimize.OnApptimizeInitializedListener() {
      @Override
      public void onApptimizeInitialized() {
        for (MethodChannel channel : allChannels) {
          channel.invokeMethod("ApptimizeInitialized", null, null);
        }
      }
    });

    Apptimize.setOnTestEnrollmentChangedListener(new Apptimize.OnTestEnrollmentChangedListener() {
      @Override
      public void onEnrolledInTest(ApptimizeTestInfo apptimizeTestInfo) {
        HashMap arguments = new HashMap();
        arguments.put("testInfo", serializeApptimizeTestInfo(apptimizeTestInfo));
        for (MethodChannel channel : allChannels) {
          channel.invokeMethod("ApptimizeEnrolledInExperiment", arguments, null);
        }
      }

      @Override
      public void onUnenrolledInTest(ApptimizeTestInfo apptimizeTestInfo, Apptimize.UnenrollmentReason unenrollmentReason) {
        HashMap arguments = new HashMap();
        arguments.put("testInfo", serializeApptimizeTestInfo(apptimizeTestInfo));
        arguments.put("unenrollmentReason", serializeUnenrollmentReason(unenrollmentReason));
        for (MethodChannel channel : allChannels) {
          channel.invokeMethod("ApptimizeUnenrolledInExperiment", arguments, null);
        }
      }
    });

    Apptimize.setOnTestRunListener(new Apptimize.OnTestRunListener() {
      @Override
      public void onTestRun(ApptimizeTestInfo apptimizeTestInfo, Apptimize.IsFirstTestRun isFirstTestRun) {
        HashMap arguments = new HashMap();
        arguments.put("testInfo", serializeApptimizeTestInfo(apptimizeTestInfo));
        arguments.put("firstParticipation", isFirstTestRun == Apptimize.IsFirstTestRun.YES);
        for (MethodChannel channel : allChannels) {
          channel.invokeMethod("ApptimizeParticipatedInExperiment", arguments, null);
        }
      }
    });
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "apptimize_flutter");
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.getApplicationContext();
    allChannels.add(channel);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    allChannels.remove(channel);
    channel = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
  }

  @Override
  public void onDetachedFromActivity() {
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Object resultValue = null;

    try {
      switch (call.method) {
        case "startApptimize":
          startApptimize(call);
          break;

        case "setCustomerUserId":
          guardArgumentPresent(call, "customerUserId");
          String customerUserId = call.argument("customerUserId");
          Apptimize.setCustomerUserId(customerUserId);
          break;

        case "getCustomerUserId":
          resultValue = Apptimize.getCustomerUserId();
          break;

        case "getApptimizeAnonUserId":
          resultValue = Apptimize.getApptimizeAnonUserId();
          break;

        case "disable":
          Apptimize.disable();
          break;

        case "setOffline":
          guardArgumentPresent(call, "isOffline");
          Boolean isOffline = call.argument("isOffline");
          Apptimize.setOffline(isOffline);
          break;

        case "getOffline":
          resultValue = Apptimize.isOffline();
          break;

        case "getMetadataState":
          EnumSet<Apptimize.ApptimizeMetadataStateFlags> metadataState = Apptimize.getMetadataState();
          HashMap metadataStateResult = new HashMap();
          metadataStateResult.put("isAvailable", metadataState.contains(Apptimize.ApptimizeMetadataStateFlags.AVAILABLE));
          metadataStateResult.put("isUpToDate", metadataState.contains(Apptimize.ApptimizeMetadataStateFlags.UP_TO_DATE));
          metadataStateResult.put("isRefreshing", metadataState.contains(Apptimize.ApptimizeMetadataStateFlags.REFRESHING));
          resultValue = metadataStateResult;
          break;

        case "track":
          guardArgumentPresent(call, "eventName");
          String eventName = call.argument("eventName");
          Object value = null;

          if (call.hasArgument("value")) {
            value = call.argument("value");
          }

          if (value != null) {
            Apptimize.track(eventName, (double)value);
          } else {
            Apptimize.track(eventName);
          }
          break;

        case "getLibraryVersion":
          String version = Apptimize.class.getPackage().getImplementationVersion();
          resultValue = version + " (Android)";
          break;

        case "setPilotTargetingId":
          guardArgumentPresent(call, "pilotTargetingId");
          String pilotTargetingId = call.argument("pilotTargetingId");
          Apptimize.setPilotTargetingId(pilotTargetingId);
          break;

        case "getPilotTargetingId":
          resultValue = Apptimize.getPilotTargetingId();
          break;

        case "runTest":
          resultValue = runTest(call);
          break;

        case "isFeatureFlagOn":
          guardArgumentPresent(call, "featureFlagName");
          String isFeatureFlagOn = call.argument("featureFlagName");
          resultValue = Apptimize.isFeatureFlagOn(isFeatureFlagOn);
          break;

        case "getApptimizeTestInfo":
          Map<String, ApptimizeTestInfo> testInfo = Apptimize.getTestInfo();
          HashMap testInfoResult = new HashMap();
          for (Map.Entry<String, ApptimizeTestInfo> entry : testInfo.entrySet()) {
            testInfoResult.put(entry.getKey(), serializeApptimizeTestInfo(entry.getValue()));
          }
          resultValue = testInfoResult;
          break;

        case "getInstantUpdateAndWinnerInfo":
          Map<String, ApptimizeInstantUpdateOrWinnerInfo> winnerInfo = Apptimize.getInstantUpdateOrWinnerInfo();
          HashMap winnerInfoResult = new HashMap();
          for (Map.Entry<String, ApptimizeInstantUpdateOrWinnerInfo> entry : winnerInfo.entrySet()) {
            winnerInfoResult.put(entry.getKey(), serializeApptimizeInstantUpdateOrWinnerInfo(entry.getValue()));
          }
          resultValue = winnerInfoResult;
          break;

        case "setUserAttribute": {
          guardArgumentPresent(call, "type");
          guardArgumentPresent(call, "attributeName");
          guardArgumentPresent(call, "attributeValue");

          String type = call.argument("type");
          String attributeName = call.argument("attributeName");
          Object attributeValue = call.argument("attributeValue");

          switch (type) {
            case "string":
              Apptimize.setUserAttribute(attributeName, (String) attributeValue);
              break;
            case "int":
              Apptimize.setUserAttribute(attributeName, (int) attributeValue);
              break;
            case "double":
              Apptimize.setUserAttribute(attributeName, (double) attributeValue);
              break;
            case "bool":
              Apptimize.setUserAttribute(attributeName, (Boolean) attributeValue);
              break;
            default:
              throw new InvalidPluginArgumentException("type", type);
          }
          break;
        }

        case "removeUserAttribute": {
          guardArgumentPresent(call, "attributeName");
          String attributeName = call.argument("attributeName");
          Apptimize.clearUserAttribute(attributeName);
          break;
        }

        case "removeAllUserAttributes":
          Apptimize.clearAllUserAttributes();
          break;

        case "getUserAttribute": {
          guardArgumentPresent(call, "type");
          guardArgumentPresent(call, "attributeName");
          String type = call.argument("type");
          String attributeName = call.argument("attributeName");

          switch (type) {
            case "string":
              resultValue = Apptimize.getUserAttributeString(attributeName);
              break;
            case "int":
              resultValue = Apptimize.getUserAttributeInteger(attributeName);
              // To ensure consistent behaviour with iOS, return default values.
              if (resultValue == null) { resultValue = 0; }
              break;
            case "double":
              resultValue = Apptimize.getUserAttributeDouble(attributeName);
              // To ensure consistent behaviour with iOS, return default values.
              if (resultValue == null) { resultValue = 0.0; }
              break;
            case "bool":
              resultValue = Apptimize.getUserAttributeBoolean(attributeName);
              // To ensure consistent behaviour with iOS, return default values.
              if (resultValue == null) resultValue = false;
              break;
            default:
              throw new InvalidPluginArgumentException("type", type);
          }
          break;
        }

        case "forceVariant": {
          guardArgumentPresent(call, "variantId");

          Object variantId = call.argument("variantId");
          if (variantId instanceof Integer) {
            Integer v = (Integer) variantId;
            Apptimize.forceVariant(v.longValue());
          } else if (variantId instanceof Long) {
            Long v = (Long) variantId;
            Apptimize.forceVariant(v.longValue());
          }
          break;
        }

        case "clearForcedVariant":{
          guardArgumentPresent(call, "variantId");
          Long variantId = call.argument("variantId");
          Apptimize.clearForcedVariant(variantId);
          break;
        }

        case "clearAllForcedVariants":
          Apptimize.clearAllForcedVariants();
          break;

        case "getVariants": {
          Map<Long, Map<String, Object>> variants = Apptimize.getVariants();
          ArrayList<Object> variantResult = new ArrayList<Object>();
          for (Map.Entry<Long, Map<String, Object>> entry : variants.entrySet()) {
            variantResult.add(entry.getValue());
          }
          resultValue = variantResult;
          break;
        }

        case "declareDynamicVariable":
          resultValue = declareDynamicVariable(call);
          break;

        case "isDynamicVariableDeclared":
          resultValue = isDynamicVariableDeclared(call);
          break;

        case "getDynamicVariableValue":
          resultValue = getDynamicVariableValue(call);
          break;

        default:
          result.notImplemented();
          return;
      }

      result.success(resultValue);
    }
    catch (InvalidPluginArgumentException e) {
      result.error("INVALID_ARGUMENT", e.getMessage(), e);
    }
    catch (MissingPluginArgumentException e) {
      result.error("ARGUMENT_MISSING", e.getMessage(), e);
    }
    catch (Exception e) {
      result.error("UNKNOWN", e.getMessage(), e);
    }
  }

  private void startApptimize(@NonNull MethodCall call) throws MissingPluginArgumentException, InvalidPluginArgumentException {
    guardArgumentPresent(call, "appKey");

    final String appKey = call.argument("appKey");
    final ApptimizeOptions options = new ApptimizeOptions();
    options.setupInBackground(true);

    if (call.hasArgument("options")) {
      HashMap optionsArgs = call.argument("options");
      if (optionsArgs != null) {

        if (optionsArgs.containsKey("devicePairingEnabled"))
          options.setIsDevicePairingEnabled((boolean) optionsArgs.get("devicePairingEnabled"));

        if (optionsArgs.containsKey("delayUntilTestsAreAvailable")) {
          Object delayUntilTestsAreAvailable = optionsArgs.get("delayUntilTestsAreAvailable");
          if (delayUntilTestsAreAvailable instanceof Long) {
            options.setUpdateMetadataTimeout(((Long)delayUntilTestsAreAvailable).longValue());
          } else if (delayUntilTestsAreAvailable instanceof Integer) {
            options.setUpdateMetadataTimeout(((Integer)delayUntilTestsAreAvailable).longValue());
          }
        }

        if (optionsArgs.containsKey("enableThirdPartyEventImporting"))
          options.setThirdPartyEventImportingEnabled((boolean) optionsArgs.get("enableThirdPartyEventImporting"));

        if (optionsArgs.containsKey("enableThirdPartyEventExporting"))
          options.setThirdPartyEventExportingEnabled((boolean) optionsArgs.get("enableThirdPartyEventExporting"));

        if (optionsArgs.containsKey("forceVariantsShowWinnersAndInstantUpdates"))
          options.setForceVariantsShowWinnersAndInstantUpdates((boolean) optionsArgs.get("forceVariantsShowWinnersAndInstantUpdates"));

        if (optionsArgs.containsKey("refreshMetaDataOnSetup"))
          options.setIsRefreshingMetadataOnSetup((boolean) optionsArgs.get("refreshMetaDataOnSetup"));

        if (optionsArgs.containsKey("logLevel")) {
          String logLevel = (String) optionsArgs.get("logLevel");
          switch (logLevel) {
            case "Verbose":
              options.setLogLevel(ApptimizeOptions.LogLevel.VERBOSE);
              break;
            case "Debug":
              options.setLogLevel(ApptimizeOptions.LogLevel.DEBUG);
              break;
            case "Info":
              options.setLogLevel(ApptimizeOptions.LogLevel.INFO);
              break;
            case "Warn":
              options.setLogLevel(ApptimizeOptions.LogLevel.WARNING);
              break;
            case "Error":
              options.setLogLevel(ApptimizeOptions.LogLevel.ERROR);
              break;
            case "Off":
              options.setLogLevel(ApptimizeOptions.LogLevel.OFF);
              break;
            default:
              throw new InvalidPluginArgumentException("logLevel", logLevel);
          }
        }

        if (optionsArgs.containsKey("serverRegion")) {
          String serverRegion = (String) optionsArgs.get("serverRegion");
          switch (serverRegion) {
            case "Default":
              options.setServerRegion(ApptimizeOptions.ServerRegion.DEFAULT);
              break;
            case "EUCS":
              options.setServerRegion(ApptimizeOptions.ServerRegion.EUCS);
              break;
            default:
              throw new InvalidPluginArgumentException("serverRegion",  serverRegion);
          }
        }
      }
    }

    final Runnable setupRunnable = new Runnable() {
      public void run() {
        Apptimize.setup(context, appKey, options);
      }
    };

    new Thread(setupRunnable).start(); // Runs setup on a different thread
  }

  private String runTest(@NonNull MethodCall call) throws MissingPluginArgumentException {
    guardArgumentPresent(call, "testName");
    guardArgumentPresent(call, "codeBlocks");

    ApptimizeOptions options = null;
    if (call.hasArgument("updateMetadataTimeout")) {
      Object updateMetadataTimeout = call.argument("updateMetadataTimeout");
      if (updateMetadataTimeout != null) {
        options = new ApptimizeOptions().setUpdateMetadataTimeout((int) call.argument("updateMetadataTimeout"));
      }
    }

    String testName = call.argument("testName");
    List<String> codeBlocks = call.argument("codeBlocks");
    final int[] result = new int[1];
    result[0] = -1;

    ApptimizeTest test = new ApptimizeTest() {
      @Override
      public void baseline() { result[0] = 0; }
      @SuppressWarnings("unused")
      public void variation1() { result[0] = 1; }
      @SuppressWarnings("unused")
      public void variation2() { result[0] = 2; }
      @SuppressWarnings("unused")
      public void variation3() { result[0] = 3; }
      @SuppressWarnings("unused")
      public void variation4() { result[0] = 4; }
      @SuppressWarnings("unused")
      public void variation5() { result[0] = 5; }
      @SuppressWarnings("unused")
      public void variation6() { result[0] = 6; }
      @SuppressWarnings("unused")
      public void variation7() { result[0] = 7; }
      @SuppressWarnings("unused")
      public void variation8() { result[0] = 8; }
      @SuppressWarnings("unused")
      public void variation9() { result[0] = 9; }
    };

    if (options != null) {
      Apptimize.runTest(testName, test, options);
    } else {
      Apptimize.runTest(testName, test);
    }

    if (result[0] < 0) {
      Log.w(TAG, "Test " + testName + " did not execute");
      return null; // Baseline
    }

    if (result[0] == 0) {
      return null; // Baseline
    }

    if (result[0] >= codeBlocks.size()) {
      Log.e(TAG, "Test executed unexpected variation");
      return null; // Baseline
    }

    return codeBlocks.get(result[0] - 1);
  }

  private static boolean declareDynamicVariable(@NonNull MethodCall call) throws MissingPluginArgumentException, InvalidPluginArgumentException {
    guardArgumentPresent(call, "name");
    guardArgumentPresent(call, "type");
    guardArgumentPresent(call, "defaultValue");

    String name = call.argument("name");
    String type = call.argument("type");
    Object defaultValue = call.argument("defaultValue");
    String key = name + "$$" + type;

    if (type == "bool" || type == "integer" || type == "double") {
      if (defaultValue == null) throw new InvalidPluginArgumentException("defaultValue", "<null>");
    }

    Object apptimizeVar = null;

    switch(type)
    {
      case "string":
        apptimizeVar = ApptimizeVar.createString(name, (String)defaultValue);
        break;

      case "bool":
        apptimizeVar = ApptimizeVar.createBoolean(name, (boolean)defaultValue);
        break;

      case "integer":
        if (defaultValue instanceof Integer) {
          apptimizeVar = ApptimizeVar.createInteger(name, ((Integer) defaultValue).intValue());
          break;
        } else if (defaultValue instanceof Long) {
          // Value is out of range - has to be an integer.
          throw new InvalidPluginArgumentException("defaultValue", defaultValue.toString());
        }

      case "double":
        apptimizeVar = ApptimizeVar.createDouble(name, (Double)defaultValue);
        break;

      case "array.string":
        apptimizeVar = ApptimizeVar.createListOfStrings(name, (List<String>)defaultValue);
        break;

      case "array.bool":
        apptimizeVar = ApptimizeVar.createListOfBooleans(name, (List<Boolean>)defaultValue);
        break;

      case "array.integer":
        // Can we test to see if it's a list of Integers?
        apptimizeVar = ApptimizeVar.createListOfIntegers(name, (List<Integer>)defaultValue);
        break;

      case "array.double":
        apptimizeVar = ApptimizeVar.createListOfDoubles(name, (List<Double>)defaultValue);
        break;

      case "dictionary.string":
        apptimizeVar = ApptimizeVar.createMapOfStrings(name, (HashMap<String, String>)defaultValue);
        break;

      case "dictionary.bool":
        apptimizeVar = ApptimizeVar.createMapOfBooleans(name, (HashMap<String, Boolean>)defaultValue);
        break;

      case "dictionary.integer":
        apptimizeVar = ApptimizeVar.createMapOfIntegers(name, (HashMap<String, Integer>)defaultValue);
        break;

      case "dictionary.double":
        apptimizeVar = ApptimizeVar.createMapOfDoubles(name, (HashMap<String, Double>)defaultValue);
        break;

      default:
        throw new InvalidPluginArgumentException("type", type);
    }

    if (apptimizeVar != null) {
      declaredApptimizeVariables.put(key, apptimizeVar);
      return true;
    }

    return false;
  }

  private static boolean isDynamicVariableDeclared(@NonNull MethodCall call) throws MissingPluginArgumentException, InvalidPluginArgumentException {
    guardArgumentPresent(call, "name");
    guardArgumentPresent(call, "type");

    String name = call.argument("name");
    String type = call.argument("type");
    String key = name + "$$" + type;

    return declaredApptimizeVariables.containsKey(key);
  }

  private static Object getDynamicVariableValue(@NonNull MethodCall call) throws MissingPluginArgumentException, InvalidPluginArgumentException {
    guardArgumentPresent(call, "name");
    guardArgumentPresent(call, "type");

    String name = call.argument("name");
    String type = call.argument("type");
    String key = name + "$$" + type;

    if (!declaredApptimizeVariables.containsKey(key)) return null;

    Object dynamicVariable = declaredApptimizeVariables.get(key);

    switch(type)
    {
      case "string":
        ApptimizeVar<String> s = (ApptimizeVar<String>)dynamicVariable;
        return s.value();

      case "bool":
        ApptimizeVar<Boolean> b = (ApptimizeVar<Boolean>)dynamicVariable;
        return b.value();

      case "integer":
        ApptimizeVar<Integer> i = (ApptimizeVar<Integer>)dynamicVariable;
        return i.value();

      case "double":
        ApptimizeVar<Double> d = (ApptimizeVar<Double>)dynamicVariable;
        return d.value();

      case "array.string":
        ApptimizeVar<List<String>> ls = (ApptimizeVar<List<String>>)dynamicVariable;
        return ls.value();

      case "array.bool":
        ApptimizeVar<List<Boolean>> lb = (ApptimizeVar<List<Boolean>>)dynamicVariable;
        return lb.value();

      case "array.integer":
        // Can we test to see if it's a list of Integers?
        ApptimizeVar<List<Integer>> li = (ApptimizeVar<List<Integer>>)dynamicVariable;
        return li.value();

      case "array.double":
        ApptimizeVar<List<Double>> ld = (ApptimizeVar<List<Double>>)dynamicVariable;
        return ld.value();

      case "dictionary.string":
        ApptimizeVar<Map<String, String>> ds = (ApptimizeVar<Map<String, String>>)dynamicVariable;
        return ds.value();

      case "dictionary.bool":
        ApptimizeVar<Map<String, Boolean>> db = (ApptimizeVar<Map<String, Boolean>>)dynamicVariable;
        return db.value();

      case "dictionary.integer":
        ApptimizeVar<Map<String, Integer>> di = (ApptimizeVar<Map<String, Integer>>)dynamicVariable;
        return di.value();

      case "dictionary.double":
        ApptimizeVar<Map<String, Double>> dd = (ApptimizeVar<Map<String, Double>>)dynamicVariable;
        return dd.value();

      default:
        throw new InvalidPluginArgumentException("type", type);
    }
  }

  private static void guardArgumentPresent(@NonNull MethodCall call, String argumentName) throws MissingPluginArgumentException {
    if (!call.hasArgument(argumentName)) throw new MissingPluginArgumentException(argumentName);
  }

  private static HashMap serializeApptimizeTestInfo(ApptimizeTestInfo testInfo) {
    HashMap result = new HashMap();
    result.put("testName", testInfo.getTestName());
    result.put("enrolledVariantName", testInfo.getEnrolledVariantName());
    result.put("testId", testInfo.getTestId());
    result.put("enrolledVariantId", testInfo.getEnrolledVariantId());
    result.put("testStartedDate", toIso8601Date(testInfo.getTestStartedDate()));
    result.put("testEnrolledDate", toIso8601Date(testInfo.getTestEnrolledDate()));
    result.put("cycle", testInfo.getCycle());
    result.put("currentPhase", testInfo.getCurrentPhase());
    result.put("participationPhase", testInfo.getParticipationPhase());
    result.put("userHasParticipated", testInfo.userHasParticipated());
    result.put("userId", testInfo.getCustomerUserId());
    result.put("anonymousUserId", testInfo.getAnonymousUserId());
    result.put("experimentType", serializeApptimizeTestType(testInfo.getApptimizeTestType()));
    return result;
  }

  private static HashMap serializeApptimizeInstantUpdateOrWinnerInfo(ApptimizeInstantUpdateOrWinnerInfo winnerInfo) {
    HashMap result = new HashMap();
    result.put("isInstantUpdate", false); // TODO: ApptimizeInstantUpdateOrWinnerInfo.getType() does not return a public type
    result.put("winningExperimentName", winnerInfo.getWinningTestName());
    result.put("winningExperimentId", winnerInfo.getWinningTestId());
    result.put("instantUpdateName", winnerInfo.getInstantUpdateName());
    result.put("instantUpdateId", winnerInfo.getInstantUpdateId());
    result.put("winningVariantName", winnerInfo.getWinningVariantName());
    result.put("winningVariantId", winnerInfo.getWinningVariantId());
    result.put("startDate", toIso8601Date(new Date())); // TODO: Value not supported on android
    result.put("userId", winnerInfo.getCustomerUserId());
    result.put("anonymousUserId", winnerInfo.getAnonymousUserId());
    return result;
  }

  private static String toIso8601Date(Date date) {
    if (date == null) return null;
    TimeZone tz = TimeZone.getTimeZone("UTC");
    DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm'Z'"); // Quoted "Z" to indicate UTC, no timezone offset
    df.setTimeZone(tz);
    return df.format(date);
  }

  private static String serializeApptimizeTestType(ApptimizeTestType testType) {
    switch (testType) {
      case VISUAL:
        return "Visual";
      case CODE_BLOCK:
        return "CodeBlock";
      case DYNAMIC_VARIABLES:
        return "DynamicVariables";
      case FEATURE_FLAG:
        return "FeatureFlag";
      default:
        return "Unknown";
    }
  }

  private static String serializeUnenrollmentReason(Apptimize.UnenrollmentReason unenrollmentReason) {
    switch (unenrollmentReason) {
      case CUSTOMER_USER_ID_CHANGED:
        return "UserIdChanged";
      case EXPERIMENT_STOPPED:
        return "ExperimentStopped";
      case EXPERIMENT_WINNER_SELECTED:
        return "ExperimentWinnerSelected";
      case VARIANT_CHANGED:
        return "VariantChanged";
      case OTHER:
        return "Other";
      case REASON_UNKNOWN:
      default:
        return "Unknown";
    }
  }
}
