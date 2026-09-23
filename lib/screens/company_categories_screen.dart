import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/api_item.dart';
import '../utils/search_utils.dart';
import '../widgets/app_search_field.dart';
import 'category_products_screen.dart';

class CompanyCategoriesScreen extends StatefulWidget {
  const CompanyCategoriesScreen({super.key, required this.company});

  final ApiItem company;

  @override
  State<CompanyCategoriesScreen> createState() =>
      _CompanyCategoriesScreenState();
}

class _CompanyCategoriesScreenState extends State<CompanyCategoriesScreen> {
  bool _loading = true;
  List<ApiItem> _categories = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final state = AppScope.of(context);
      final results = await state.loadCategoriesByCompany(widget.company.id);
      if (mounted) {
        setState(() {
          _categories = results;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading company categories: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories
        .where((category) => matchesApiItemSearch(category, _query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.company.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: AppSearchField(
                    value: _query,
                    onChanged: (value) => setState(() => _query = value),
                    hintText: 'Search categories',
                  ),
                ),
                Expanded(
                  child: categories.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? 'No categories found for this company.'
                                : 'No categories match your search.',
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(18),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                          itemCount: categories.length,
                          itemBuilder: (_, index) {
                            final category = categories[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CategoryProductsScreen(
                                    category: category,
                                  ),
                                ),
                              ),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child:
                                            category.imageUrl == null ||
                                                category.imageUrl!.isEmpty
                                            ? const Icon(
                                                Icons.category_outlined,
                                                size: 28,
                                                color: Colors.grey,
                                              )
                                            : Image.network(
                                                category.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      size: 28,
                                                      color: Colors.grey,
                                                    ),
                                              ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Text(
                                          category.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
