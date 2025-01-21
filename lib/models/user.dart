class UserRepresenter {
  final String userId;
  final String email;
  final String nickName;
  final String avatar;
  final List<int> importedModulesIds;

  UserRepresenter({
    required this.userId,
    required this.email,
    required this.nickName,
    required this.avatar,
    required this.importedModulesIds,
  });

  factory UserRepresenter.fromJson(Map<String, dynamic> json) {
    return UserRepresenter(
      userId: json['userIds'] as String,
      email: json['email'] as String,
      nickName: json['spritzenName'] as String,
      avatar: json['avatar'] as String,
      importedModulesIds: (json['id_importedModules'] as List<dynamic>).map((e) => e as int).toList(),
    );
  }
}