final class StationCashBalanceSnapshot {
  const StationCashBalanceSnapshot({
    required this.todayAmount,
    required this.yesterdayAmount,
  });

  final double todayAmount;
  final double yesterdayAmount;
}
