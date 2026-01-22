import 'dart:io'; // Import this for Platform check
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/routes_name.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      context.go(AppRoutes.desktopDispatchWorkstation);
    }
    else if (Platform.isAndroid || Platform.isIOS) {
      context.go(AppRoutes.customerDetailsScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Image.asset(
            'assets/icons/scanner_icon.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}