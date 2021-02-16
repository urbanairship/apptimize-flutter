# apptimize_flutter

This project provides access to the Apptimize platform SDK for
both Android and iOS flutter apps.

## Getting Started

1. Add the dependency to your `pubspec.yaml` adding `apptimize_flutter`:

    **Using pub.dev**
    ```yml
    dependencies:
        apptimize_flutter: ^1.0    # Any 1.x version where x >= 0 works.
    ```

    **Using git**
    ```yml
    dependencies:
        apptimize_flutter:
            git: git://github.com/urbanairship/apptimize_flutter.git
    ```

    **Using the release from the official website**
    * Download the latest SDK from the [SDK Download](https://apptimize.com/docs/sdk-information.html) page.
    * Copy the SDK to a new directory outside of your project, such as apptimize_flutter.
    * Reference the SDK in your pubspec.yaml as follows:
        ```yml
        dependencies:
            apptimize_flutter:
                path: ../apptimize_flutter/
        ```
2. Install it.

    * From the terminal: Run `flutter pub get`.
    
        **OR**

    * From *Android Studio/IntelliJ*: Click **Packages** get in the action ribbon at the top of `pubspec.yaml`.
    * From *VS Code*: Click **Get Packages** located in right side of the action ribbon at the top of `pubspec.yaml`.

3. In each dart files you wish to use apptimize, add the following import statement:

    ```dart
    import 'package:apptimize_flutter/apptimize_flutter.dart';
    ```

4. Add the code to start Apptimize to your project.
    
    Create a listener so you know when it is safe to start executing tests.
    ```dart
    // Create a function that will be executed whenever new Apptimize metadata is downloaded
    Future<void> onApptimizeInitialized(ApptimizeInitializedEvent e) async {
        print("Apptimize setup and initialization complete");
        Apptimize.track("Apptimize Initialized");
        // Set a flag to indicate Apptimize data is available and content can be displayed
    }
    ```

    In your startup code add a listener for Apptimize initialization (and any other events
    that you might need) then start Apptimize using your AppKey (which you can find in the
    Apptimize dashboard).
    ```dart
    Apptimize.apptimizeInitializedStream.listen((event) => {onApptimizeInitialized(event)});
    Apptimize.startApptimize("<appkey>");
    ```

5. (If your app is running) Stop and restart the app. This package brings platform-specific
   code for iOS and Android and that code must be built into your app. Hot reload and hot restart
   only update the Dart code, so a full restart of the app might be required to avoid errors like `MissingPluginException` when using the package.

6. After that return to the [Apptimize dashboard](https://apptimize.com/admin/) to configure
   your tests.

## Documentation

See the [official documentation](https://apptimize.com/docs/installation/flutter-installation.html) on the Apptimize website for more information on getting started.

See the [plugin documentation](https://pub.dev/packages/apptimize_flutter) at pub.dev.