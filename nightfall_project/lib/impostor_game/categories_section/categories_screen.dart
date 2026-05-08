import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/impostor_game/offline_db/category_service.dart';
import 'package:nightfall_project/impostor_game/offline_db/words_service.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  final WordsService _wordsService = WordsService();
  List<Category> _allCategories = [];
  Set<int> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = _categoryService.getAllCategories();
    final selected = await _categoryService.loadSelectedCategoryIds();
    setState(() {
      _allCategories = categories;
      _selectedCategoryIds = selected;
    });
  }

  Future<void> _toggleCategory(int categoryId) async {
    await _categoryService.toggleCategory(
      categoryId,
      onUpdate: (updatedSelection) {
        setState(() {
          _selectedCategoryIds = updatedSelection;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const PixelStarfieldBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      PixelButton(
                        label: languageService.translate('back'),
                        color: const Color(0xFF415A77),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Center(
                          child: Text(
                            languageService.translate('categories_title'),
                            style: GoogleFonts.pressStart2p(
                              color: const Color(0xFFE0E1DD),
                              fontSize: 20,
                              shadows: [
                                const Shadow(
                                  color: Colors.black,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Main Content
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(8, 8),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF778DA9),
                          border: Border.symmetric(
                            vertical: BorderSide(
                              color: Color(0xFF415A77),
                              width: 6,
                            ),
                            horizontal: BorderSide(
                              color: Color(0xFFE0E1DD),
                              width: 6,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B2A).withOpacity(0.95),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.8),
                              width: 4,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFF778DA9),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  languageService.translate(
                                    'select_categories_title',
                                  ),
                                  style: GoogleFonts.vt323(
                                    color: Colors.white70,
                                    fontSize: 24,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _allCategories.length,
                                  separatorBuilder: (ctx, i) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final category = _allCategories[index];
                                    final isSelected = _selectedCategoryIds
                                        .contains(category.id);
                                    final wordCount = _wordsService
                                        .getWordCountForCategory(category.id);

                                    return GestureDetector(
                                      onTap: () => _toggleCategory(category.id),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(
                                                  0xFF1B263B,
                                                ).withOpacity(0.9)
                                              : Colors.black.withOpacity(0.5),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF415A77)
                                                : Colors.grey.withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Custom Pixel Checkbox
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                border: Border.all(
                                                  color: Colors.white70,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: Colors.greenAccent,
                                                      size: 24,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    category.name,
                                                    style: GoogleFonts.vt323(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.white54,
                                                      fontSize: 28,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${wordCount} ${languageService.translate('words_count')}',
                                                    style: GoogleFonts.vt323(
                                                      color: Colors.white38,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
