class UserCredits {
  const UserCredits({
    required this.balance,
    required this.plan,
    required this.watermarkEnabled,
  });

  final int balance;
  final String plan;
  final bool watermarkEnabled;

  bool get isFree => plan == 'free';
  bool get isPro => plan == 'pro';
  bool get isCreatorPlus => plan == 'creator_plus';

  factory UserCredits.fromMap(Map<String, dynamic> map) {
    return UserCredits(
      balance: (map['balance'] as num?)?.toInt() ?? 0,
      plan: map['plan'] as String? ?? 'free',
      watermarkEnabled: map['watermark_enabled'] as bool? ?? true,
    );
  }

  static const empty = UserCredits(balance: 0, plan: 'free', watermarkEnabled: true);
}
