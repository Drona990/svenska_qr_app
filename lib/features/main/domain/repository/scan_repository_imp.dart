import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:svenska_qr/features/main/domain/repository/scan_repository.dart';

import '../entities/dispatch_entity.dart';
import '../entities/scan_entity.dart';

class ScanRepositoryImpl implements ScanRepository {
  final FirebaseFirestore firestore;

  ScanRepositoryImpl(this.firestore);

  @override
  Future<void> saveToTable(ScanItem item) async {
    await firestore.collection('scanned_items').add({
      'code': item.code,
      'method': item.method,
      'timestamp': Timestamp.fromDate(item.timestamp),
    });
  }

  @override
  Future<void> saveDispatch(DispatchEntry entry) async {
    try {
      await firestore.collection('dispatch_records').add({
        'customer_pin': entry.customerPin,
        'bill_no': entry.billNo,
        'qty': entry.qty,
        'nos_of_box': entry.nosOfBox,
        'loose_boxes': entry.looseBoxes,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'verified',
      });
    } catch (e) {
      throw Exception("Failed to save dispatch: $e");
    }
  }

  @override
  Future<void> saveIndividualBox(String qrCode) async {
    try {
      await firestore.collection('scanned_boxes').add({
        'qr_code': qrCode,
        'scanned_at': FieldValue.serverTimestamp(),
        'status': 'verified',
      });
    } catch (e) {
      throw Exception("Failed to save box scan: $e");
    }
  }


}
