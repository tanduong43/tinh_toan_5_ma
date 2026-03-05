class HistorySession {
  final int sessionNo; // Phiên N
  final List<double> numbers; // các số đã nhập trong phiên
  final double rawSum; // tổng trong phiên
  final double multiplier; // hệ số
  final double finalTotal; // rawSum * multiplier
  final int createdAtMs; // thời gian tạo (dùng làm ID ổn định)

  const HistorySession({
    required this.sessionNo,
    required this.numbers,
    required this.rawSum,
    required this.multiplier,
    required this.finalTotal,
    required this.createdAtMs,
  });

  Map<String, dynamic> toMap() => {
    'sessionNo': sessionNo,
    'numbers': numbers,
    'rawSum': rawSum,
    'multiplier': multiplier,
    'finalTotal': finalTotal,
    'createdAtMs': createdAtMs,
  };

  factory HistorySession.fromMap(Map<String, dynamic> map) {
    final raw = (map['numbers'] as List?) ?? const [];
    final nums = raw.map((e) => (e as num).toDouble()).toList();

    final rawSum = (map['rawSum'] as num?)?.toDouble() ?? _sumList(nums);
    final multiplier = (map['multiplier'] as num?)?.toDouble() ?? 0.0;

    return HistorySession(
      sessionNo: (map['sessionNo'] as num?)?.toInt() ?? 1,
      numbers: nums,
      rawSum: rawSum,
      multiplier: multiplier,
      finalTotal:
          (map['finalTotal'] as num?)?.toDouble() ?? (rawSum * multiplier),
      createdAtMs:
          (map['createdAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static double _sumList(List<double> list) =>
      list.isEmpty ? 0.0 : list.reduce((a, b) => a + b);
}
