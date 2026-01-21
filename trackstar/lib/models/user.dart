class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  //final int age;
  //final int weight;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    //required this.age,
  });

  // Convert a User into a Map
  Map<String, Object?> toMap() {
    return {
      'id': id, 
      'name': name, 
      'email': email, 
      'password' : password,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, password: $password}';
  }
}