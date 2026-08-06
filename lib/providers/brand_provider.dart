import 'package:flutter/material.dart';

import '../models/brand.dart';
import '../repositories/brand_repository.dart';

class BrandProvider extends ChangeNotifier {
  final BrandRepository _repository = BrandRepository();

  List<Brand> _brands = [];

  List<Brand> get brands => _brands;

  Future<void> loadBrands() async {
    _brands = await _repository.getAll();
    notifyListeners();
  }

  Future<void> addBrand(Brand brand) async {
    await _repository.insert(brand);
    await loadBrands();
  }

  Future<void> updateBrand(Brand brand) async {
    await _repository.update(brand);
    await loadBrands();
  }

  Future<void> deleteBrand(int id) async {
    await _repository.delete(id);
    await loadBrands();
  }
}