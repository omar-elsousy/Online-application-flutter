import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/api_item.dart';
import '../utils/search_utils.dart';
import '../widgets/app_search_field.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final ApiItem category;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  bool _loading = true;
  List<ApiItem> _items = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final state = AppScope.of(context);
    final items = await state.loadProductsByCategory(widget.category);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = _items
        .where((item) => matchesApiItemSearch(item, _query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: AppSearchField(
                    value: _query,
                    onChanged: (value) => setState(() => _query = value),
                    hintText: 'Search products',
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? 'No products for this category yet.'
                                : 'No products match your search.',
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(18),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: .68,
                              ),
                          itemCount: items.length,
                          itemBuilder: (_, index) {
                            final product = items[index];
                            return ProductCard(
                              product: product,
                              quantity: state.getProductQuantity(product.id),
                              onUpdateQuantity: (delta) =>
                                  state.updateCartQuantity(product, delta),
                              onAdd: () => state.addToCart(product),
                              onFavourite: () async {
                                if (state.isFavourite(product.id)) {
                                  await state.removeFromFavourites(product);
                                } else {
                                  await state.addToFavourites(product);
                                }
                              },
                              isFavourite: state.isFavourite(product.id),
                              onOpen: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsScreen(product: product),
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
