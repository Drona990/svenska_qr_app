
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/routes_name.dart';
import '../../features/main/presentation/bloc/scan_bloc.dart';
import '../../features/main/presentation/pages/customer_details_screen.dart';
import '../../features/main/presentation/pages/scan_history_screen.dart';
import '../../features/main/presentation/pages/scanner_page.dart';
import '../../features/main/presentation/pages/single_desktop_dispatch_workstation.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';

import '../../injection.dart' as di;


class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),

      GoRoute(
        path: AppRoutes.desktopDispatchWorkstation,
        builder: (_, __) => const DesktopDispatchWorkstation(),
      ),

      GoRoute(
        path: AppRoutes.customerDetailsScreen,
        builder: (context, state) {
          return BlocProvider.value(
            value: di.sl<ScanBloc>(),
            child: const CustomerDetailsPage(),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.scanHistory,
        name: AppRoutes.scanHistory,
        builder: (context, state) => const ScanHistoryScreen(),
      ),

      GoRoute(
        path: '/scanner',
        name: AppRoutes.scanScreen,
        builder: (context, state) {
          return ScannerScreen(
            billNo: state.uri.queryParameters['billNo'] ?? '',
            targetPin: state.uri.queryParameters['pin'] ?? '',
            totalBoxes: int.tryParse(state.uri.queryParameters['boxes'] ?? '0') ?? 0,
            qty: state.uri.queryParameters['qty'] ?? '0',
            loose: state.uri.queryParameters['loose'] ?? '0',
          );
        },
      ),













]
  );
}
