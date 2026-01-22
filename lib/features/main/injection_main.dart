import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:svenska_qr/features/main/presentation/bloc/scan_bloc.dart';
import 'domain/repository/scan_repository.dart';
import 'domain/repository/scan_repository_imp.dart';


Future<void> initScanningInjection(GetIt sl) async {
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  sl.registerLazySingleton<ScanRepository>(
        () => ScanRepositoryImpl(sl()),
  );

  sl.registerFactory(() => ScanBloc(sl()));

}