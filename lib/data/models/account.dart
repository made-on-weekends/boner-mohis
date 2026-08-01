/// Account entity — mirrors the Room `accounts` table from SCHEMA.md.
class Account {
  final int? id;
  final String nickname;
  final String distributor;
  final String accountNo;
  final String meterNo;
  final double balance;
  final int lastUpdated; // Unix epoch ms
  final int currentSlab;
  final double slabUsage;
  final double yesterdayUsage;
  final double monthlyKwh;

  const Account({
    this.id,
    required this.nickname,
    required this.distributor,
    required this.accountNo,
    required this.meterNo,
    required this.balance,
    required this.lastUpdated,
    required this.currentSlab,
    required this.slabUsage,
    required this.yesterdayUsage,
    required this.monthlyKwh,
  });

  Account copyWith({
    int? id,
    String? nickname,
    String? distributor,
    String? accountNo,
    String? meterNo,
    double? balance,
    int? lastUpdated,
    int? currentSlab,
    double? slabUsage,
    double? yesterdayUsage,
    double? monthlyKwh,
  }) {
    return Account(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      distributor: distributor ?? this.distributor,
      accountNo: accountNo ?? this.accountNo,
      meterNo: meterNo ?? this.meterNo,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentSlab: currentSlab ?? this.currentSlab,
      slabUsage: slabUsage ?? this.slabUsage,
      yesterdayUsage: yesterdayUsage ?? this.yesterdayUsage,
      monthlyKwh: monthlyKwh ?? this.monthlyKwh,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nickname': nickname,
      'distributor': distributor,
      'account_no': accountNo,
      'meter_no': meterNo,
      'balance': balance,
      'last_updated': lastUpdated,
      'current_slab': currentSlab,
      'slab_usage': slabUsage,
      'yesterday_usage': yesterdayUsage,
      'monthly_kwh': monthlyKwh,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      nickname: map['nickname'] as String,
      distributor: map['distributor'] as String,
      accountNo: map['account_no'] as String,
      meterNo: map['meter_no'] as String,
      balance: (map['balance'] as num).toDouble(),
      lastUpdated: map['last_updated'] as int,
      currentSlab: map['current_slab'] as int,
      slabUsage: (map['slab_usage'] as num).toDouble(),
      yesterdayUsage: (map['yesterday_usage'] as num).toDouble(),
      monthlyKwh: (map['monthly_kwh'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Account && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
