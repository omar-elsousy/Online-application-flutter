import 'package:flutter/material.dart';
import '../models/api_item.dart';
import '../models/cart_line.dart';

class AppDialogs {
  const AppDialogs._();

  static void showQuantityDialog(
    BuildContext context,
    dynamic state,
    ApiItem product,
    double currentQty,
  ) {
    final controller = TextEditingController(
      text: formatCartQuantity(currentQty),
    );
    showDialog(
      context: context,
      builder: (context) {
        String? validationError;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Edit Quantity'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter quantity (e.g. 0.5)',
                errorText: validationError,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  final normalized = controller.text.trim().replaceAll(
                    ',',
                    '.',
                  );
                  final newQty = double.tryParse(normalized);
                  if (newQty == null || !newQty.isFinite || newQty <= 0) {
                    setDialogState(
                      () => validationError =
                          'Enter a quantity greater than zero.',
                    );
                    return;
                  }
                  state.setCartQuantity(product, newQty);
                  Navigator.pop(context);
                },
                child: const Text('UPDATE'),
              ),
            ],
          ),
        );
      },
    );
  }
}
