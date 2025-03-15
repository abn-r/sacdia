class UserModel {
  final String id;
  final String email;
  final bool postRegisterComplete;

  UserModel({
    required this.id,
    required this.email,
    required this.postRegisterComplete,
  });

  // Métodos para serializar / deserializar si lo requieres...
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      postRegisterComplete: json['postRegisterComplete'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'postRegisterComplete': postRegisterComplete,
    };
  }
}