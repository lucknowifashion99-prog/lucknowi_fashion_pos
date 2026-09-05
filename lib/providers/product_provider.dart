import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/product_variant.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  List<Product> _products = [];

  List<ProductVariant> _variants = [];

  List<Product> get products => _products;

  List<ProductVariant> get variants => _variants;

  // =========================
  // PRODUCT
  // =========================

  Future<void> loadProducts() async {
    _products = await _repository.getAllProducts();
    notifyListeners();
  }

  Future<void> addProduct(
      Product product,
      ) async {
    await _repository.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(
      Product product,
      ) async {
    await _repository.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(
      int id,
      ) async {
    await _repository.deleteProduct(id);

    _variants.removeWhere(
          (variant) => variant.productId == id,
    );

    await loadProducts();
  }

  // =========================
  // VARIANTS
  // =========================

  Future<void> loadVariants(
      int productId,
      ) async {
    _variants = await _repository.getVariants(
      productId,
    );

    notifyListeners();
  }

  Future<void> addVariant(
      ProductVariant variant,
      ) async {
    await _repository.insertVariant(
      variant,
    );

    await loadVariants(
      variant.productId,
    );
  }

  Future<void> updateVariant(
      ProductVariant variant,
      ) async {
    await _repository.updateVariant(
      variant,
    );

    await loadVariants(
      variant.productId,
    );
  }

  Future<void> deleteVariant(
      ProductVariant variant,
      ) async {
    await _repository.deleteVariant(
      variant.id!,
    );

    await loadVariants(
      variant.productId,
    );
  }

  Future<void> updateStock(
      ProductVariant variant,
      int stock,
      ) async {
    await _repository.updateVariantStock(
      variant.id!,
      stock,
    );

    await loadVariants(
      variant.productId,
    );
  }

  Future<List<ProductVariant>> loadVariantsForSearch(
      int productId,
      ) async {
    return await _repository.getVariants(productId);
  }

  // =========================
// SEARCH VARIANT BY SKU / BARCODE
// =========================

  Future<ProductVariant?> searchVariantBySkuOrBarcode(
      String query,
      ) async {
    return await _repository
        .searchVariantBySkuOrBarcode(
      query,
    );
  }

  Future<void> clearVariants() async {
    _variants = [];
    notifyListeners();
  }
}