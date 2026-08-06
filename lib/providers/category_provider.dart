import 'package:flutter/material.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  List<Category> _categories = [];

  List<Category> get categories => _categories;

  Future<void> loadCategories() async {
    _categories = await _repository.getAll();
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _repository.insert(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.update(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _repository.delete(id);
    await loadCategories();
  }
}