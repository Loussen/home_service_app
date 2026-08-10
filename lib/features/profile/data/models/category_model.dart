class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.slug,
    required this.nameAz,
    this.nameEn,
    this.icon,
  });

  final int id;
  final String slug;
  final String nameAz;
  final String? nameEn;
  final String? icon;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      slug: json['slug'] as String,
      nameAz: json['name_az'] as String,
      nameEn: json['name_en'] as String?,
      icon: json['icon'] as String?,
    );
  }
}
