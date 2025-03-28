class LotteryWinnerModel {
  final String id;
  final String groupId;
  final String userId;
  final String month; // Format: "MM-YYYY" 
  final double amount;
  final DateTime drawDate;
  final bool collected;
  final DateTime? collectionDate;

  LotteryWinnerModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.month,
    required this.amount,
    required this.drawDate,
    required this.collected,
    this.collectionDate,
  });

  factory LotteryWinnerModel.fromJson(Map<String, dynamic> json) {
    return LotteryWinnerModel(
      id: json['id'],
      groupId: json['group_id'],
      userId: json['user_id'],
      month: json['month'],
      amount: json['amount'].toDouble(),
      drawDate: DateTime.parse(json['draw_date']),
      collected: json['collected'],
      collectionDate: json['collection_date'] != null ? DateTime.parse(json['collection_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'month': month,
      'amount': amount,
      'draw_date': drawDate.toIso8601String(),
      'collected': collected,
      'collection_date': collectionDate?.toIso8601String(),
    };
  }
} 