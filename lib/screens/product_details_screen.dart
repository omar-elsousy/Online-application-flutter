import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/api_item.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final ApiItem product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _loading = true;
  ApiItem? _details;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetails());
  }

  Future<void> _loadDetails() async {
    try {
      final state = AppScope.of(context);
      final result = await state.loadProductDetails(widget.product.id);
      if (mounted) {
        setState(() {
          _details = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final item = _details ?? widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Image
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: item.imageUrl == null
                      ? Icon(Icons.inventory_2_outlined, size: 80, color: Theme.of(context).colorScheme.primary)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(item.imageUrl!, fit: BoxFit.cover),
                        ),
                ),
                const SizedBox(height: 24),

                // 2. Name
                _DetailRow(label: 'Name', value: item.title, isHeader: true),
                const Divider(),

                // 3. Code
                _DetailRow(label: 'Code', value: item.id),
                const Divider(),

                // 4. Category
                _DetailRow(label: 'Category', value: item.subtitle ?? 'N/A'),
                const Divider(),

                // 5. Price
                _DetailRow(
                  label: 'Price',
                  value: '${item.price?.toStringAsFixed(2) ?? '0.00'} EGP',
                  valueColor: Theme.of(context).colorScheme.primary,
                ),
                const Divider(),

                // 6. Tax
                _DetailRow(label: 'Tax', value: '${item.raw['tax'] ?? '0'} EGP'),
                const Divider(),

                // 7. Status
                _DetailRow(
                  label: 'Status',
                  value: item.raw['status'] ?? 'N/A',
                  valueColor: (item.raw['status']?.toString().contains('in stock') ?? false) ? Colors.green : Colors.orange,
                ),

                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: state.isInCart(item.id)
                          ? Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: state.isLoading ? null : () => state.updateCartQuantity(item, -1),
                                  ),
                                  Text(
                                    '${state.getProductQuantity(item.id)} IN CART',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: state.isLoading ? null : () => state.updateCartQuantity(item, 1),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: state.isLoading ? null : () => state.addToCart(item),
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('ADD TO CART'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isLoading ? null : () async {
                          if (state.isFavourite(item.id)) {
                            await state.removeFromFavourites(item);
                          } else {
                            await state.addToFavourites(item);
                          }
                        },
                        icon: Icon(
                          state.isFavourite(item.id) ? Icons.favorite : Icons.favorite_border,
                          color: state.isFavourite(item.id) ? Colors.red : Colors.grey,
                        ),
                        label: Text(
                          state.isFavourite(item.id) ? 'UNFAVOURITE' : 'FAVOURITE',
                          style: TextStyle(
                            color: state.isFavourite(item.id) ? Colors.red : Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: BorderSide(color: state.isFavourite(item.id) ? Colors.red : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHeader;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isHeader = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.w900 : FontWeight.w600,
                fontSize: isHeader ? 20 : 16,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
