import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:houseiana_mobile_app/app.dart';
import 'package:houseiana_mobile_app/bloc_observer.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart' as di;
import 'package:houseiana_mobile_app/core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make system nav bar transparent so SafeArea insets work correctly.
  // Icons are forced dark because the app paints a light scaffold background
  // behind the (transparent) system nav bar — see `app.dart`.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Firebase (requires google-services.json / GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
    await FCMService.instance.initialize();
  } catch (e) {
    // Firebase not yet configured — continue without push notifications
    debugPrint('[Firebase] Not configured: $e');
  }

  // Initialize dependency injection
  await di.init();

  // Set up BLoC observer for debugging
  Bloc.observer = AppBlocObserver();

  runApp(const HouseianaApp());
}


