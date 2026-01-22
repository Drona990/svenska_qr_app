class ScanItem {
  final String code;
  final String method;
  final DateTime timestamp;

  ScanItem({
    required this.code,
    required this.method,
    required this.timestamp
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ScanItem &&
              runtimeType == other.runtimeType &&
              code == other.code &&
              method == other.method;

  @override
  int get hashCode => code.hashCode ^ method.hashCode;
}