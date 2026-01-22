import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:svenska_qr/features/main/presentation/bloc/scan_events.dart';
import '../../domain/repository/scan_repository.dart';
import 'scan_state.dart';
import '../../domain/entities/dispatch_entity.dart';


class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final ScanRepository repository;
  final List<String> _validScans = [];
  DispatchEntry? _currentEntry;

  ScanBloc(this.repository) : super(ScanInitial()) {

    on<OnProceedPressed>((event, emit) {
      _currentEntry = event.entry;
      _validScans.clear();
      emit(ScanInitial());
    });
  }
}