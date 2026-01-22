class DispatchEntry {
  final String customerPin;
  final String billNo;
  final int qty;
  final int nosOfBox;
  final int looseBoxes;
  final DateTime timestamp;

  DispatchEntry({
    required this.customerPin,
    required this.billNo,
    required this.qty,
    required this.nosOfBox,
    required this.looseBoxes,
    required this.timestamp,
  });
}