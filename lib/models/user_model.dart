class UserModel {
  final String id;
  final String email;
  final String role; // 'normal', 'holder', 'admin'
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool requestedHolder;
  final bool requestedJoinGroup;
  final String? requestedGroupId;

  UserModel({
    required this.id, 
    required this.email, 
    required this.role,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.requestedHolder = false,
    this.requestedJoinGroup = false,
    this.requestedGroupId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      groupId: json['group_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      requestedHolder: json['requested_holder'] ?? false,
      requestedJoinGroup: json['requested_join_group'] ?? false,
      requestedGroupId: json['requested_group_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'group_id': groupId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'requested_holder': requestedHolder,
      'requested_join_group': requestedJoinGroup,
      'requested_group_id': requestedGroupId,
    };
  }
} 