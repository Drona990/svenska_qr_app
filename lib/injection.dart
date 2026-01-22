import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'features/main/injection_main.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo(sl<Connectivity>()));
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<Dio>(), sl<NetworkInfo>()));

  await initScanningInjection(sl);

}
