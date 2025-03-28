class ContributionModel {
  final String id;
  final String groupId;
  final String userId;
  final String month; // Format: "MM-YYYY"
  final double amount;
  final DateTime contributionDate;
  final bool isPaid;

  ContributionModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.month,
    required this.amount,
    required this.contributionDate,
    required this.isPaid,
  });

  factory ContributionModel.fromJson(Map<String, dynamic> json) {
    return ContributionModel(
      id: json['id'],
      groupId: json['group_id'],
      userId: json['user_id'],
      month: json['month'],
      amount: json['amount'].toDouble(),
      contributionDate: DateTime.parse(json['contribution_date']),
      isPaid: json['is_paid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'month': month,
      'amount': amount,
      'contribution_date': contributionDate.toIso8601String(),
      'is_paid': isPaid,
    };
  }
} 