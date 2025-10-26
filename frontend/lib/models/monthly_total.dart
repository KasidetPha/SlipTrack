class MonthlyTotal {
  final double amount;
  final int? month;
  final int? year;
  final String? type;
  final double? incomeTotalAmount;
  final double? expenseTotalAmount;
  final double? netTotal;

  const MonthlyTotal({
    required this.amount,
    this.month,
    this.year,
    this.type,
    this.incomeTotalAmount,
    this.expenseTotalAmount,
    this.netTotal,
  });

  factory MonthlyTotal.fromJson(Map<String, dynamic> json) {
    double _toD(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    final dynamic rawAmount =
      json['amount'] ?? json['total'] ?? json['thisMonth'];
    
    final breakdown =
      (json['breakdown'] is Map) ? (json['breakdown'] as Map) : const {};

    return MonthlyTotal(
      amount: _toD(rawAmount),
      month: json['month'] is int? json['month'] : int.tryParse('${json['month'] ?? ''}'),
      year: json['year'] is int ? json['year'] : int.tryParse('${json['year'] ?? ''}'),
      type: json['type']?.toString(),
      incomeTotalAmount: breakdown.isNotEmpty ? _toD(breakdown['income_total_amount']) : null,
      expenseTotalAmount: breakdown.isNotEmpty ? _toD(breakdown['expense_total_amount']) : null,
      netTotal: breakdown.isNotEmpty ? _toD(breakdown['net_total']) : null,
    );
  }
}