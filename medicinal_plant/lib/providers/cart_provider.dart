import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Simple model for a Cart Item
class CartItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final String sellerId;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
    this.quantity = 1,
  });

  double get total => price * quantity;
}

// Cart State Notifier
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Map<String, dynamic> product, String productId, String sellerId) {
    // Check if item already exists
    final existingIndex = state.indexWhere((item) => item.productId == productId);

    if (existingIndex >= 0) {
      // Update quantity
      final items = [...state];
      items[existingIndex].quantity++;
      state = items;
    } else {
      // Add new item
      final image = (product['images'] as List?)?.first ?? '';
      state = [
        ...state,
        CartItem(
          productId: productId,
          name: product['name'] ?? 'Unknown',
          price: (product['price'] as num?)?.toDouble() ?? 0.0,
          imageUrl: image,
          sellerId: sellerId,
        ),
      ];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }
  
  void decrementQuantity(String productId) {
     final existingIndex = state.indexWhere((item) => item.productId == productId);
     if (existingIndex >= 0) {
       final items = [...state];
       if (items[existingIndex].quantity > 1) {
         items[existingIndex].quantity--;
         state = items;
       } else {
         removeFromCart(productId);
       }
     }
  }

  void clearCart() {
    state = [];
  }
  
  double get subtotal => state.fold(0, (sum, item) => sum + item.total);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
