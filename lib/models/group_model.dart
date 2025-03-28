class GroupModel {
  final String id;
  final String name;
  final String type; // 'standard' or 'lottery'
  final double savingsGoal;
  final String holderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String groupCode;

  GroupModel({
    required this.id,
    required this.name,
    required this.type,
    required this.savingsGoal,
    required this.holderId,
    required this.createdAt,
    required this.updatedAt,
    required this.groupCode,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      savingsGoal: json['savings_goal'].toDouble(),
      holderId: json['holder_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      groupCode: json['group_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'savings_goal': savingsGoal,
      'holder_id': holderId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'group_code': groupCode,
    };
  }
} 