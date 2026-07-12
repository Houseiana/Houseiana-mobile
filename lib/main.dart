import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:houseiana_mobile_app/app.dart';
import 'package:houseiana_mobile_app/bloc_observer.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart' as di;
import 'package:houseiana_mobile_app/core/services/fcm_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Readex Pro is bundled under assets/google_fonts/ — never fetch fonts
  // over the network (removes a request + font swap from the first paint).
  GoogleFonts.config.allowRuntimeFetching = false;

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

  // Firebase and DI are independent — initialize them concurrently so
  // cold-start latency is the max of the two, not the sum.
  final firebaseReady = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) => true).catchError((Object e) {
    // Firebase not yet configured — continue without push notifications
    debugPrint('[Firebase] Not configured: $e');
    return false;
  });
  await Future.wait([firebaseReady, di.init()]);

  // Set up BLoC observer for debugging (debug builds only — it stringifies
  // every state emit, which is pure overhead in release)
  if (kDebugMode) {
    Bloc.observer = AppBlocObserver();
  }

  runApp(const HouseianaApp());

  // FCM must not block the first frame: requestPermission shows a modal OS
  // dialog on iOS and getToken/upload hit the network. It needs Firebase and
  // DI (UserSession/ApiConsumer), both ready by this point.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (await firebaseReady) {
      try {
        await FCMService.instance.initialize();
      } catch (e) {
        debugPrint('[FCM] Initialization failed: $e');
      }
    }
  });
}


