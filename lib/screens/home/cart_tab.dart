import 'package:flutter/material.dart';
import '../../controllers/app_scope.dart';
import '../../models/cart_line.dart';
import '../../widgets/app_error_banner.dart';
import '../../utils/app_dialogs.dart';
import '../../utils/search_utils.dart';
import '../../widgets/app_search_field.dart';

class CartTab extends StatefulWidget {
  const CartTab({super.key, this.onCheckoutSuccess});

  final ValueChanged<String>? onCheckoutSuccess;

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cartSummaryReady =
        state.isCartPreviewReady &&
        state.isWalletCreditsReady &&
        state.cartPricingError == null;
    final filteredCart = state.cart
        .where((line) => matchesApiItemSearch(line.product, _query))
        .toList();
    if (state.cart.isEmpty)
      return const _EmptyState(message: 'Your cart is empty.');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: AppSearchField(
            value: _query,
            onChanged: (value) => setState(() => _query = value),
            hintText: 'Search cart',
          ),
        ),
        // 1. قسم التنبيهات في الأعلى تماماً
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppErrorBanner(message: state.error!),
          ),

        if (state.cartGiftItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: state.cartGiftItems
                  .map(
                    (gift) => Card(
                      color: Colors.green.withValues(alpha: 0.08),
                      child: ListTile(
                        leading: const Icon(
                          Icons.card_giftcard,
                          color: Colors.green,
                        ),
                        title: Text(gift['name']?.toString() ?? 'Gift'),
                        subtitle: Text(
                          'Code: ${gift['product_id'] ?? '—'}\n'
                          'Quantity: ${gift['quantity']} • '
                          '${gift['unit_price'] ?? 0} EGP (Free)',
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove gift',
                          onPressed: state.isLoading
                              ? null
                              : () => state.removeGiftIncentive(
                                  int.tryParse(
                                        gift['source_incentive_id']
                                                ?.toString() ??
                                            '',
                                      ) ??
                                      0,
                                ),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        // 2. قائمة المنتجات (تأخذ المساحة المتاحة فقط بين التنبيه والزرار)
        Expanded(
          child: filteredCart.isEmpty
              ? const _EmptyState(message: 'No products match your search.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  itemCount: filteredCart.length,
                  itemBuilder: (context, index) {
                    final line = filteredCart[index];
                    final product = line.product;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: state.isLoading
                                              ? null
                                              : () => state.updateCartQuantity(
                                                  product,
                                                  -1,
                                                ),
                                          icon: Icon(
                                            Icons.remove_circle_outline,
                                            color: state.isLoading
                                                ? Colors.grey
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            size: 28,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: state.isLoading
                                              ? null
                                              : () =>
                                                    AppDialogs.showQuantityDialog(
                                                      context,
                                                      state,
                                                      product,
                                                      line.quantity,
                                                    ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Text(
                                              formatCartQuantity(line.quantity),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: state.isLoading
                                              ? null
                                              : () => state.updateCartQuantity(
                                                  product,
                                                  1,
                                                ),
                                          icon: Icon(
                                            Icons.add_circle_outline,
                                            color: state.isLoading
                                                ? Colors.grey
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: product.imageUrl == null
                                          ? const Icon(
                                              Icons.inventory_2_outlined,
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                product.imageUrl!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Code: ${product.id}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Price: ${product.price?.toStringAsFixed(2)} EGP',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (state.incentiveBannerFor(
                                            product.id,
                                          ) !=
                                          null)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            state.incentiveBannerFor(
                                              product.id,
                                            )!,
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      if (product.raw['unit_tax'] != null &&
                                          product.raw['unit_tax'] != 0)
                                        Text(
                                          'Unit Tax: ${product.raw['unit_tax']} EGP',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      if (product.raw['unit_price_after_tax'] !=
                                          null)
                                        Text(
                                          'After Tax: ${product.raw['unit_price_after_tax']} EGP',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      state.removeFromCart(product),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Total Item',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${(product.raw['total_price'] ?? (product.price! * line.quantity)).toStringAsFixed(2)} EGP',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        if (state.isCartDataRefreshing)
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Expanded(child: Text('Checking available incentives...')),
              ],
            ),
          )
        else if (!state.isWalletCreditsReady && state.cartPricingError != null)
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: Text(
              'Could not load available incentives. Refresh to try again.',
              style: TextStyle(color: Colors.red),
            ),
          )
        else if (state.walletCredits.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available wallet credits',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...state.walletCredits.map((credit) {
                  final selected = state.isWalletCreditSelected(credit);
                  final value =
                      double.tryParse(
                        credit['incentive_value']?.toString() ?? '0',
                      ) ??
                      0;
                  return Card(
                    color: selected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: CheckboxListTile(
                      value: selected,
                      secondary: state.isWalletCreditUpdating(credit)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onChanged: state.isLoading || state.isCartPricingLoading
                          ? null
                          : (_) => state.toggleWalletCredit(credit),
                      title: Text('${value.toStringAsFixed(2)} EGP credit'),
                      subtitle: Text('Valid until ${credit['to_date'] ?? ''}'),
                    ),
                  );
                }),
              ],
            ),
          ),
        // 3. قسم الدفع (Checkout) مثبت دائماً في الأسفل وبدون تداخل
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false, // لضمان الالتصاق بأسفل الشاشة الحقيقي
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Number of Products',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    Text(
                      '${state.serverCartCount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (state.isCartPricingLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Calculating final total and incentives...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (cartSummaryReady) ...[
                  const SizedBox(height: 10),
                  _MoneyRow(
                    label: 'Subtotal',
                    value: state.cartTotals['subtotal'],
                  ),
                  _MoneyRow(
                    label: 'Discounts',
                    value: state.cartTotals['total_discount'],
                    negative: true,
                  ),
                  _MoneyRow(label: 'Tax', value: state.cartTotals['total_tax']),
                  if ((double.tryParse(
                            state.cartTotals['wallet_used']?.toString() ?? '0',
                          ) ??
                          0) >
                      0)
                    _MoneyRow(
                      label: 'Wallet used',
                      value: state.cartTotals['wallet_used'],
                      negative: true,
                    ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      state.cartPricingError ??
                          'The final total is not ready yet. Refresh to retry.',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (state.isCartPricingLoading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (cartSummaryReady)
                      Text(
                        '${state.cartTotal.toStringAsFixed(2)} EGP',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else
                      const Text('—'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (state.cart.isEmpty ||
                            state.isLoading ||
                            state.isCartPricingLoading ||
                            !cartSummaryReady)
                        ? null
                        : () async {
                            final orderId = await state.checkout();
                            if (context.mounted && orderId != null) {
                              await state.loadOrders();
                              if (context.mounted) {
                                widget.onCheckoutSuccess?.call(orderId);
                              }
                            }
                            // لاحظ: حذفنا الـ SnackBar هنا لأن الرسالة تظهر بالفعل في الأعلى تلقائياً
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'CHECKOUT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.negative = false,
  });
  final String label;
  final dynamic value;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text('${negative ? '-' : ''}${amount.toStringAsFixed(2)} EGP'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
