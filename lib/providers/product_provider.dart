import 'package:flutter/material.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  List<Product> _products = [];

  List<Product> get products => _products;

  Future<void> loadProducts() async {
    _products = await _repository.getAllProducts();
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await _repository.insertProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _repository.deleteProduct(id);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _repository.updateProduct(product);
    await loadProducts();
  }
}