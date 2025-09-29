class MonthlyTotal {
  final double amount;

  const MonthlyTotal(this.amount);

  factory MonthlyTotal.fromJson(Map<String, dynamic> json) {
    final v= json['total'] ?? json['amount'] ?? json['thisMonth'];

    if (v is num) return MonthlyTotal(v.toDouble());
    return MonthlyTotal(double.tryParse(v?.toString() ?? '' ) ?? 0.0);
  }
}