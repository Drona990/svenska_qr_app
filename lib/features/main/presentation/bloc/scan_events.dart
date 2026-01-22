import '../../domain/entities/dispatch_entity.dart';

abstract class ScanEvent {
  const ScanEvent();
}

class OnItemScanned extends ScanEvent {
  final String code;
  final String method;
  const OnItemScanned(this.code, this.method);
}

class OnProceedPressed extends ScanEvent {
  final DispatchEntry entry;
  const OnProceedPressed(this.entry);
}