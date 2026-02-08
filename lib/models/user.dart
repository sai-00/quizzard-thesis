class User {
  final int? profileID;
  final String name;
  final String? avatar;
  final bool isAdmin;
  final String? adminPasscode;

  User({
    this.profileID,
    required this.name,
    this.avatar,
    this.isAdmin = false,
    this.adminPasscode,
  });

  factory User.fromMap(Map<String, dynamic> m) => User(
    profileID: m['profileID'] as int?,
    name: m['name'] as String,
    avatar: m['avatar'] as String?,
    isAdmin: (m['isAdmin'] is int)
        ? (m['isAdmin'] as int) == 1
        : (m['isAdmin'] == true),
    adminPasscode: m['adminPasscode'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (profileID != null) 'profileID': profileID,
    'name': name,
    'avatar': avatar ?? '',
    'isAdmin': isAdmin ? 1 : 0,
    if (adminPasscode != null) 'adminPasscode': adminPasscode,
  };
}
