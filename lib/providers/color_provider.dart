import 'package:flutter/material.dart';

import '../models/color_model.dart';
import '../repositories/color_repository.dart';

class ColorProvider extends ChangeNotifier {
  final ColorRepository _repository = ColorRepository();

  List<ColorModel> _colors = [];

  List<ColorModel> get colors => _colors;

  Future<void> loadColors() async {
    _colors = await _repository.getAll();
    notifyListeners();
  }

  Future<void> addColor(ColorModel color) async {
    await _repository.insert(color);
    await loadColors();
  }

  Future<void> updateColor(ColorModel color) async {
    await _repository.update(color);
    await loadColors();
  }

  Future<void> deleteColor(int id) async {
    await _repository.delete(id);
    await loadColors();
  }
}