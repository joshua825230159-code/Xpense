class User {
  final int? id;
  final String username;
  final String password;
  final bool isPremium;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.isPremium,
  });

  User copyWith({
    int? id,
    String? username,
    String? password,
    bool? isPremium,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'isPremium': isPremium ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      isPremium: map['isPremium'] == 1,
    );
  }
}
