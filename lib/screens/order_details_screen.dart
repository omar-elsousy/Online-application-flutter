import 'package:flutter/material.dart';
import '../controllers/app_scope.dart';
import '../models/api_item.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    // نستخدم addPostFrameCallback لضمان أن الـ context أصبح جاهزاً لاسترجاع الـ AppScope
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      // نستخدم findAncestorWidgetOfExactType أو dependOn... بحذر
      // بما أننا داخل Screen، فالأفضل استرجاع الـ state مرة واحدة
      final state = AppScope.of(context);
      final data = await state.loadOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _details = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading order details: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order #${widget.orderId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NO')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('YES, CANCEL'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final state = AppScope.of(context);
      await state.cancelOrder(widget.orderId);
      if (mounted) Navigator.pop(context); // الرجوع بعد الإلغاء
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.orderId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _details == null || _details!.isEmpty
              ? const Center(child: Text('Order details not found.'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _Row('Status', _details!['status']?.toString().toUpperCase() ?? 'N/A', bold: true),
                            _Row('Date', _details!['created_at'] ?? 'N/A'),
                            _Row('Total Price', '${_details!['final_price']} EGP', color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_details!['status']?.toString().toLowerCase() == 'placed')
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _cancelOrder,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('CANCEL ORDER'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade200)),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text('Items', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...(_details!['items'] as List? ?? []).map((item) {
                      String? imageUrl = item['image']?.toString();
                      if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                        imageUrl = 'http://10.1.104.82:8000/$imageUrl';
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: imageUrl == null || imageUrl == 'null' || imageUrl.isEmpty
                                ? const Icon(Icons.inventory_2_outlined, color: Colors.grey)
                                : Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                  ),
                          ),
                          title: Text(item['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Qty: ${item['quantity']} | Price: ${item['unit_price']} EGP'),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final product = ApiItem.fromJson(item);
                                  final state = AppScope.of(context);
                                  if (state.isFavourite(product.id)) {
                                    await state.removeFromFavourites(product);
                                  } else {
                                    await state.addToFavourites(product);
                                  }
                                  if (mounted) setState(() {});
                                },
                                child: Builder(
                                  builder: (context) {
                                    final state = AppScope.of(context);
                                    final isFav = state.isFavourite(item['product_id']?.toString() ?? '');
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isFav ? Icons.favorite : Icons.favorite_border,
                                          size: 14,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isFav ? 'Remove from Favourites' : 'Add to Favourites',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isFav ? Colors.red : Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          trailing: Text('${item['total_price']} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _Row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}
