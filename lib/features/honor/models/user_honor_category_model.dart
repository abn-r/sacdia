import 'package:sacdia/features/honor/models/user_honor_model.dart';

class UserHonorCategory {
  final int categoryId;
  final String categoryName;
  final List<UserHonor> honors;

  UserHonorCategory({
    required this.categoryId,
    required this.categoryName,
    this.honors = const [],
  });

  factory UserHonorCategory.fromJson(Map<String, dynamic> json) {
    return UserHonorCategory(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      honors: json['honors'] != null
          ? List<UserHonor>.from(
              (json['honors'] as List).map((x) => UserHonor.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'category_name': categoryName,
        'honors': honors.map((x) => x.toJson()).toList(),
      };
} 