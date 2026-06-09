import 'package:flutter/material.dart';
import '../models/api_item.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    required this.onOpen,
    this.onFavourite,
    this.isFavourite = false,
    this.quantity = 0,
    this.onUpdateQuantity,
  });

  final ApiItem product;
  final VoidCallback onAdd;
  final VoidCallback onOpen;
  final VoidCallback? onFavourite;
  final bool isFavourite;
  final int quantity;
  final Function(int delta)? onUpdateQuantity;

  bool get isInCart => quantity > 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: product.imageUrl == null
                      ? Icon(
                          Icons.inventory_2_outlined,
                          size: 44,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 40,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                'ID: ${product.id}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              if (product.raw['status'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.raw['status'].toString().toLowerCase().contains('in stock')
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.raw['status'].toString().toUpperCase(),
                    style: TextStyle(
                      color: product.raw['status'].toString().toLowerCase().contains('in stock')
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                product.price == null
                    ? 'N/A'
                    : '${product.price!.toStringAsFixed(2)} EGP',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              // استخدام Row مع Expanded لضمان توزيع المساحة ومنع الأوفر فلو
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: isInCart
                        ? Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FittedBox(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: () => onUpdateQuantity?.call(-1),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () => onUpdateQuantity?.call(1),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : IconButton.filledTonal(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                  ),
                  if (onFavourite != null) ...[
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: onFavourite,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            border: Border.all(color: isFavourite ? Colors.red.withOpacity(0.5) : Colors.blue.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isFavourite ? Icons.favorite : Icons.favorite_border,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  isFavourite ? 'Remove' : 'Add Fav',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isFavourite ? Colors.red : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
