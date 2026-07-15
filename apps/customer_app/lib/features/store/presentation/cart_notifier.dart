import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/features/store/data/repositories/products_repository.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addProduct(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void removeProduct(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final currentQty = state[index].quantity;
      if (currentQty > 1) {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index)
              state[i].copyWith(quantity: currentQty - 1)
            else
              state[i]
        ];
      } else {
        state = List<CartItem>.from(state)..removeAt(index);
      }
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalPrice {
    return state.fold(
        0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
