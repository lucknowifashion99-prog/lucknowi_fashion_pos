import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();

  List<Customer> _customers = [];

  List<Customer> get customers => List.unmodifiable(_customers);

  Future<void> loadCustomers() async {
    _customers = await _repository.getAll();
    notifyListeners();
  }

  Future<int> addCustomer(Customer customer) async {
    final id = await _repository.insert(customer);
    await loadCustomers();
    return id;
  }

  Future<void> updateCustomer(Customer customer) async {
    await _repository.update(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _repository.delete(id);
    await loadCustomers();
  }
}