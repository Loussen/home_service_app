class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.slug,
    required this.nameAz,
    this.parentId,
    this.nameEn,
    this.icon,
    this.children = const [],
  });

  final int id;
  final int? parentId;
  final String slug;
  final String nameAz;
  final String? nameEn;
  final String? icon;
  final List<CategoryModel> children;

  bool get isRoot => parentId == null;
  bool get hasChildren => children.isNotEmpty;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    return CategoryModel(
      id: json['id'] as int,
      parentId: json['parent_id'] as int?,
      slug: json['slug'] as String,
      nameAz: json['name_az'] as String,
      nameEn: json['name_en'] as String?,
      icon: json['icon'] as String?,
      children: childrenJson
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<(CategoryModel category, int depth, String path)> flatten(
    List<CategoryModel> nodes, {
    int depth = 0,
    String prefix = '',
  }) {
    final out = <(CategoryModel, int, String)>[];
    for (final node in nodes) {
      final path = prefix.isEmpty ? node.nameAz : '$prefix → ${node.nameAz}';
      out.add((node, depth, path));
      out.addAll(flatten(node.children, depth: depth + 1, prefix: path));
    }
    return out;
  }

  static bool matchesQuery(CategoryModel category, String path, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return category.nameAz.toLowerCase().contains(q) ||
        (category.nameEn?.toLowerCase().contains(q) ?? false) ||
        category.slug.toLowerCase().contains(q) ||
        path.toLowerCase().contains(q);
  }

  static CategoryModel? firstLeaf(List<CategoryModel> nodes) {
    for (final node in nodes) {
      if (node.children.isEmpty) return node;
      final nested = firstLeaf(node.children);
      if (nested != null) return nested;
    }
    return nodes.isEmpty ? null : nodes.first;
  }
}
