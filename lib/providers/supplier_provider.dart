import 'package:flutter/material.dart';

import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierRepository _repository = SupplierRepository();

  List<Supplier> _suppliers = [];

  List<Supplier> get suppliers => _suppliers;

  Future<void> loadSuppliers() async {
    _suppliers = await _repository.getAll();
    notifyListeners();
  }

  Future<void> addSupplier(Supplier supplier) async {
    await _repository.insert(supplier);
    await loadSuppliers();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _repository.update(supplier);
    await loadSuppliers();
  }

  Future<void> deleteSupplier(int id) async {
    await _repository.delete(id);
    await loadSuppliers();
  }
}