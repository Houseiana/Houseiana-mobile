import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required by the Google Maps SDK for iOS before any GoogleMap widget is
    // created. Mirrors the key set in android/app/src/main/AndroidManifest.xml.
    // Without this call the app crashes natively when the property details map
    // renders (GMSException: API key must be supplied).
    GMSServices.provideAPIKey("AIzaSyB-j9eljyNW0HUccE15yxhgt70aiHNuC-k")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
