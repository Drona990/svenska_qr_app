
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'injection.dart' as di;
import 'package:window_manager/window_manager.dart';
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await windowManager.ensureInitialized();
        final FlutterView? view = PlatformDispatcher.instance.implicitView;

        if (view != null) {
          final double screenWidth = view.physicalSize.width / view.devicePixelRatio;
          final double screenHeight = view.physicalSize.height / view.devicePixelRatio;

          Size lockedSize = Size(screenWidth, screenHeight);

          WindowOptions windowOptions = WindowOptions(
            size: lockedSize,
            center: true,
            backgroundColor: Colors.transparent,
            skipTaskbar: false,
            titleBarStyle: TitleBarStyle.normal,
            title: "Dispatch Workstation",
          );

          await windowManager.waitUntilReadyToShow(windowOptions, () async {
            await windowManager.setMinimumSize(lockedSize);
            await windowManager.setMaximumSize(lockedSize);
            await windowManager.setResizable(false);
            await windowManager.setMinimizable(true);
            await windowManager.setClosable(true);
            await windowManager.show();
            await windowManager.focus();
          });
        }
      }
    }

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await dotenv.load(fileName: ".env");
    await di.init();

    runApp(const MyApp());
  } catch (e) {
    debugPrint("INITIALIZATION ERROR: $e");
    runApp(const MyApp());
  }
}