class WithdrawalModel {
  final String id;
  final String groupId;
  final String userId;
  final double amount;
  final String status; // 'pending', 'approved', 'rejected', 'cashed', 'being paid back', 'paid back in full'
  final DateTime requestDate;
  final DateTime? approvalDate;
  final int paybackDuration; // in months
  final double paybackAmount; // monthly amount to pay back

  WithdrawalModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.requestDate,
    this.approvalDate,
    required this.paybackDuration,
    required this.paybackAmount,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'],
      groupId: json['group_id'],
      userId: json['user_id'],
      amount: json['amount'].toDouble(),
      status: json['status'],
      requestDate: DateTime.parse(json['request_date']),
      approvalDate: json['approval_date'] != null ? DateTime.parse(json['approval_date']) : null,
      paybackDuration: json['payback_duration'],
      paybackAmount: json['payback_amount'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'amount': amount,
      'status': status,
      'request_date': requestDate.toIso8601String(),
      'approval_date': approvalDate?.toIso8601String(),
      'payback_duration': paybackDuration,
      'payback_amount': paybackAmount,
    };
  }
} 