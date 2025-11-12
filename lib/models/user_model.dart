class User {
  final int? id;
  final String username;
  final String password; // This will store the hashed password

  User({
    this.id,
    required this.username,
    required this.password,
  });

  // Helper to create a new instance with an ID, e.g., after DB insert
  User copyWith({int? id}) {
    return User(
      id: id ?? this.id,
      username: username,
      password: password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
    );
  }
}
