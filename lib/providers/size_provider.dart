import 'package:flutter/material.dart';

import '../models/size.dart';
import '../repositories/size_repository.dart';

class SizeProvider extends ChangeNotifier {
  final SizeRepository _repository = SizeRepository();

  List<SizeModel> _sizes = [];

  List<SizeModel> get sizes => _sizes;

  Future<void> loadSizes() async {
    _sizes = await _repository.getAll();
    notifyListeners();
  }

  Future<void> addSize(SizeModel size) async {
    await _repository.insert(size);
    await loadSizes();
  }

  Future<void> updateSize(SizeModel size) async {
    await _repository.update(size);
    await loadSizes();
  }

  Future<void> deleteSize(int id) async {
    await _repository.delete(id);
    await loadSizes();
  }
}