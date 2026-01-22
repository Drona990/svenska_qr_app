
import '../entities/dispatch_entity.dart';
import '../entities/scan_entity.dart';

abstract class ScanRepository {
  Future<void> saveToTable(ScanItem item);
  Future<void> saveDispatch(DispatchEntry entry);
  Future<void> saveIndividualBox(String qrCode);

}