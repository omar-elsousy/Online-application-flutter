import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../utils/search_utils.dart';
import '../widgets/app_search_field.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final favourites = state.favourites
        .where((product) => matchesApiItemSearch(product, _query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Favourites')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: AppSearchField(
              value: _query,
              onChanged: (value) => setState(() => _query = value),
              hintText: 'Search favourites',
            ),
          ),
          Expanded(
            child: favourites.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty
                          ? 'Your favourites list is empty.'
                          : 'No favourites match your search.',
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
                    itemCount: favourites.length,
                    itemBuilder: (_, index) {
                      final product = favourites[index];
                      return ProductCard(
                        product: product,
                        isFavourite: true,
                        quantity: state.getProductQuantity(product.id),
                        onUpdateQuantity: (delta) =>
                            state.updateCartQuantity(product, delta),
                        onFavourite: () => state.removeFromFavourites(product),
                        onAdd: () => state.addToCart(product),
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
