class User {
  final int? profileID;
  final String name;
  final String? avatar;

  User({this.profileID, required this.name, this.avatar});

  factory User.fromMap(Map<String, dynamic> m) => User(
    profileID: m['profileID'] as int?,
    name: m['name'] as String,
    avatar: m['avatar'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (profileID != null) 'profileID': profileID,
    'name': name,
    'avatar': avatar ?? '',
  };
}
