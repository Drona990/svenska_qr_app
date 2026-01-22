// lib/features/presentation/bloc/scan_state.dart
abstract class ScanState {
  const ScanState();
}

class ScanInitial extends ScanState {}

class ScanValidated extends ScanState {
  final List<String> scannedItems;
  final int totalTarget;
  const ScanValidated(this.scannedItems, this.totalTarget);
}

class ScanWarning extends ScanState {
  final String error;
  final List<String> currentScans;
  const ScanWarning({required this.error, required this.currentScans});
}