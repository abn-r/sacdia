import 'package:sacdia/features/honor/models/honor_model.dart';

class HonorCategory {
  final int categoryId;
  final String categoryName;
  final String? categoryDescription;
  final int? categoryIcon;
  final List<Honor> honors;

  HonorCategory({
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription,
    this.categoryIcon,
    this.honors = const [],
  });

  factory HonorCategory.fromJson(Map<String, dynamic> json) {
    return HonorCategory(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      categoryDescription: json['category_description'],
      categoryIcon: json['category_icon'],
      honors: json['honors'] != null
          ? List<Honor>.from(
              (json['honors'] as List).map((x) => Honor.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'category_name': categoryName,
        'category_description': categoryDescription,
        'category_icon': categoryIcon,
        'honors': honors.map((x) => x.toJson()).toList(),
      };
} 