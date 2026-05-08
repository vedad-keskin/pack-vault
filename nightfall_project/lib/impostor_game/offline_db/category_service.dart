import 'package:shared_preferences/shared_preferences.dart';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});
}

class CategoryService {
  // Use a new key to avoid conflicts with old string-based IDs
  static const String _selectedCategoryIdsKey =
      'impostor_selected_category_ids_v2';

  // --- Seed Data ---

  static final List<Category> _categories = [
    Category(id: 1, name: 'Lokacije'),
    Category(id: 2, name: 'Hrana'),
    Category(id: 3, name: 'Crtani'),
    Category(id: 4, name: 'Poznati'),
    Category(id: 5, name: 'Predmeti'),
    Category(id: 6, name: 'Anime'),
    Category(id: 7, name: 'Islam'),
    Category(id: 8, name: 'Znamenitosti'),
    Category(id: 9, name: 'Borci'),
    Category(id: 10, name: 'Brendovi'),
    Category(id: 11, name: 'Igre'),
    Category(id: 12, name: 'Sportovi'),
    Category(id: 13, name: 'Životinje'),
    Category(id: 14, name: 'Filmovi'),
  ];

  // --- Methods ---

  List<Category> getAllCategories() {
    return _categories;
  }

  Future<Set<int>> loadSelectedCategoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedList = prefs.getStringList(
      _selectedCategoryIdsKey,
    );

    if (savedList == null || savedList.isEmpty) {
      // Default: Select All
      final allIds = _categories.map((c) => c.id).toSet();
      await saveSelectedCategoryIds(allIds);
      return allIds;
    }

    // Convert stored strings back to integers
    return savedList
        .map((idStr) => int.tryParse(idStr) ?? 0)
        .where((id) => id != 0)
        .toSet();
  }

  Future<void> saveSelectedCategoryIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences only supports String lists, so convert ints to strings
    final stringList = ids.map((id) => id.toString()).toList();
    await prefs.setStringList(_selectedCategoryIdsKey, stringList);
  }

  Future<void> toggleCategory(
    int categoryId, {
    required Function(Set<int>) onUpdate,
  }) async {
    final selected = await loadSelectedCategoryIds();

    if (selected.contains(categoryId)) {
      if (selected.length > 1) {
        selected.remove(categoryId);
      } else {
        // Prevent removing the last one
        return;
      }
    } else {
      selected.add(categoryId);
    }

    await saveSelectedCategoryIds(selected.toSet());
    onUpdate(selected);
  }
}
