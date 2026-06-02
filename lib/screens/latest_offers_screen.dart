import 'package:flutter/material.dart';
import '../controllers/app_scope.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class LatestOffersScreen extends StatelessWidget {
  const LatestOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Latest Offers')),
      body: state.latestOffers.isEmpty
          ? const Center(child: Text('No offers available at the moment.'))
          : GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .68,
              ),
              itemCount: state.latestOffers.length,
              itemBuilder: (_, index) {
                final product = state.latestOffers[index];
                return ProductCard(
                  product: product,
                  quantity: state.getProductQuantity(product.id),
                  onUpdateQuantity: (delta) => state.updateCartQuantity(product, delta),
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
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
