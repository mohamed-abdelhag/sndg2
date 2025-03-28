abstract class BaseGroupMetadata {
  final String id;
  final String groupId;
  final double totalSavingsGoal;
  final double actualPoolAmount;
  final String holderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseGroupMetadata({
    required this.id,
    required this.groupId,
    required this.totalSavingsGoal,
    required this.actualPoolAmount,
    required this.holderId,
    required this.createdAt,
    required this.updatedAt,
  });
}

class StandardGroupMetadata extends BaseGroupMetadata {
  final double currentWithdrawals;

  StandardGroupMetadata({
    required super.id,
    required super.groupId,
    required super.totalSavingsGoal,
    required super.actualPoolAmount,
    required super.holderId,
    required super.createdAt,
    required super.updatedAt,
    required this.currentWithdrawals,
  });

  factory StandardGroupMetadata.fromJson(Map<String, dynamic> json) {
    return StandardGroupMetadata(
      id: json['id'],
      groupId: json['group_id'],
      totalSavingsGoal: json['total_savings_goal'].toDouble(),
      actualPoolAmount: json['actual_pool_amount'].toDouble(),
      holderId: json['holder_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      currentWithdrawals: json['current_withdrawals'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'total_savings_goal': totalSavingsGoal,
      'actual_pool_amount': actualPoolAmount,
      'holder_id': holderId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'current_withdrawals': currentWithdrawals,
    };
  }
}

class LotteryGroupMetadata extends BaseGroupMetadata {
  final DateTime nextDrawDate;
  final double currentPoolAmount;

  LotteryGroupMetadata({
    required super.id,
    required super.groupId,
    required super.totalSavingsGoal,
    required super.actualPoolAmount,
    required super.holderId,
    required super.createdAt,
    required super.updatedAt,
    required this.nextDrawDate,
    required this.currentPoolAmount,
  });

  factory LotteryGroupMetadata.fromJson(Map<String, dynamic> json) {
    return LotteryGroupMetadata(
      id: json['id'],
      groupId: json['group_id'],
      totalSavingsGoal: json['total_savings_goal'].toDouble(),
      actualPoolAmount: json['actual_pool_amount'].toDouble(),
      holderId: json['holder_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      nextDrawDate: DateTime.parse(json['next_draw_date']),
      currentPoolAmount: json['current_pool_amount'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'total_savings_goal': totalSavingsGoal,
      'actual_pool_amount': actualPoolAmount,
      'holder_id': holderId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'next_draw_date': nextDrawDate.toIso8601String(),
      'current_pool_amount': currentPoolAmount,
    };
  }
} 