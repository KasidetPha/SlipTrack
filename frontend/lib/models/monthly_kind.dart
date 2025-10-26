enum MonthlyKind {income, expense, net}
extension MonthlyKindX on MonthlyKind {
  String get wire => switch (this) {
    MonthlyKind.income => 'income',
    MonthlyKind.expense => 'expense',
    MonthlyKind.net => 'net'
  };
}