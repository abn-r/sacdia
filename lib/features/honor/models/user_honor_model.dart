class UserHonor {
  final int userHonorId;
  final int honorId;
  final String honorName;
  final bool validate;
  final String? certificate;
  final List<String> images;
  final String? honorImage;

  UserHonor({
    required this.userHonorId,
    required this.honorId,
    required this.honorName,
    this.validate = false,
    this.certificate,
    this.images = const [],
    this.honorImage,
  });

  factory UserHonor.fromJson(Map<String, dynamic> json) {
    return UserHonor(
      userHonorId: json['user_honor_id'] ?? 0,
      honorId: json['honor_id'] ?? 0,
      honorName: json['honor_name'] ?? '',
      validate: json['validate'] ?? false,
      certificate: json['certificate'],
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : [],
      honorImage: json['honor_image'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_honor_id': userHonorId,
        'honor_id': honorId,
        'honor_name': honorName,
        'validate': validate,
        'certificate': certificate,
        'images': images,
        'honor_image': honorImage,
      };
} 