import 'package:flutter/material.dart';
import '../controllers/app_scope.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Favourites')),
      body: state.favourites.isEmpty
          ? const Center(child: Text('Your favourites list is empty.'))
          : GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .68,
              ),
              itemCount: state.favourites.length,
              itemBuilder: (_, index) {
                final product = state.favourites[index];
                return ProductCard(
                  product: product,
                  isFavourite: true,
                  quantity: state.getProductQuantity(product.id),
                  onUpdateQuantity: (delta) => state.updateCartQuantity(product, delta),
                  onFavourite: () => state.removeFromFavourites(product),
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
