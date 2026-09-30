import 'api_item.dart';

String formatCartQuantity(double quantity) =>
    quantity == quantity.roundToDouble()
    ? quantity.toInt().toString()
    : quantity.toString();

class CartLine {
  const CartLine({required this.product, this.quantity = 1});

  final ApiItem product;
  final double quantity;

  double get total => (product.price ?? 0) * quantity;

  CartLine copyWith({double? quantity}) {
    return CartLine(product: product, quantity: quantity ?? this.quantity);
  }
}
