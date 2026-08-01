/// DailyUsageHistory entity — mirrors `daily_usage_history` table from SCHEMA.md.
class DailyUsageHistory {
  final int? id;
  final int accountId;
  final int dateEpoch; // Unix epoch ms (start of day)
  final double consumptionKwh;
  final double cost;

  const DailyUsageHistory({
    this.id,
    required this.accountId,
    required this.dateEpoch,
    required this.consumptionKwh,
    required this.cost,
  });

  DailyUsageHistory copyWith({
    int? id,
    int? accountId,
    int? dateEpoch,
    double? consumptionKwh,
    double? cost,
  }) {
    return DailyUsageHistory(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      dateEpoch: dateEpoch ?? this.dateEpoch,
      consumptionKwh: consumptionKwh ?? this.consumptionKwh,
      cost: cost ?? this.cost,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'account_id': accountId,
      'date_epoch': dateEpoch,
      'consumption_kwh': consumptionKwh,
      'cost': cost,
    };
  }

  factory DailyUsageHistory.fromMap(Map<String, dynamic> map) {
    return DailyUsageHistory(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      dateEpoch: map['date_epoch'] as int,
      consumptionKwh: (map['consumption_kwh'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
    );
  }
}
