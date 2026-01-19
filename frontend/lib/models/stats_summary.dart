class StatsSummary {
  final double? thisMonth;
  final double? lastMonth;
  final double? percentChange;

  const StatsSummary({
    this.thisMonth,
    this.lastMonth,
    this.percentChange
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    return StatsSummary(
      thisMonth: (json['this_month'] as num?)?.toDouble(),
      lastMonth: (json['last_month'] as num?)?.toDouble(),
      percentChange: (json['percent_change'] as num?)?.toDouble(),
    );
  }
}