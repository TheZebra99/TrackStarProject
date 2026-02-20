class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final bool isAdmin;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.isAdmin = false,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'isAdmin': isAdmin ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, isAdmin: $isAdmin}';
  }
}