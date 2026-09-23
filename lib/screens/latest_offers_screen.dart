import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../utils/search_utils.dart';
import '../widgets/app_search_field.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class LatestOffersScreen extends StatefulWidget {
  const LatestOffersScreen({super.key});

  @override
  State<LatestOffersScreen> createState() => _LatestOffersScreenState();
}

class _LatestOffersScreenState extends State<LatestOffersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final offers = state.latestOffers
        .where((product) => matchesApiItemSearch(product, _query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Latest Offers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: AppSearchField(
              value: _query,
              onChanged: (value) => setState(() => _query = value),
              hintText: 'Search offers',
            ),
          ),
          Expanded(
            child: offers.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty
                          ? 'No offers available at the moment.'
                          : 'No offers match your search.',
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
                    itemCount: offers.length,
                    itemBuilder: (_, index) {
                      final product = offers[index];
                      return ProductCard(
                        product: product,
                        quantity: state.getProductQuantity(product.id),
                        onUpdateQuantity: (delta) =>
                            state.updateCartQuantity(product, delta),
                        isFavourite: state.isFavourite(product.id),
                        onFavourite: () async {
                          if (state.isFavourite(product.id)) {
                            await state.removeFromFavourites(product);
                          } else {
                            await state.addToFavourites(product);
                          }
                        },
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
