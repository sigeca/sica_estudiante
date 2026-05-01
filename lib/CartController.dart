import 'package:flutter/material.dart';
import 'api_service.dart';

class CartController {
  // Singleton pattern
  static final CartController _instance = CartController._internal();
  factory CartController() => _instance;
  CartController._internal();

  final ValueNotifier<int> cartCount = ValueNotifier<int>(0);

  Future<void> updateCartCount(String idpersona) async {
    try {
      final productos = await ApiService.fetchProductosCarrito(idpersona);
      cartCount.value = productos.length;
    } catch (e) {
      debugPrint('Error updating cart count: $e');
    }
  }

  void incrementLocally(int count) {
    cartCount.value += count;
  }

  void decrementLocally(int count) {
    cartCount.value = (cartCount.value - count).clamp(0, 999);
  }
}
