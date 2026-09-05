import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/customer.dart';
import '../../../providers/customer_provider.dart';
import 'customer_dialog.dart';
import 'widgets/customer_tile.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers(
      List<Customer> customers,
      String keyword,
      ) {
    setState(() {
      final search = keyword.trim().toLowerCase();

      _filteredCustomers = customers.where((customer) {
        return customer.name.toLowerCase().contains(search) ||
            customer.phone.toLowerCase().contains(search) ||
            (customer.email?.toLowerCase().contains(search) ?? false);
      }).toList();
    });
  }

  Future<void> _addCustomer(
      String name,
      String phone,
      String? email,
      String? address,
      ) async {
    final provider = context.read<CustomerProvider>();

    try {
      await provider.addCustomer(
        Customer(
          name: name,
          phone: phone,
          email: email,
          address: address,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Added Successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add customer: $e'),
        ),
      );
    }
  }

  Future<void> _updateCustomer(
      Customer customer,
      String name,
      String phone,
      String? email,
      String? address,
      ) async {
    final provider = context.read<CustomerProvider>();

    try {
      await provider.updateCustomer(
        Customer(
          id: customer.id,
          name: name,
          phone: phone,
          email: email,
          address: address,
          createdAt: customer.createdAt,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Updated Successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update customer: $e'),
        ),
      );
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    if (customer.id == null) return;

    final provider = context.read<CustomerProvider>();

    try {
      await provider.deleteCustomer(customer.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Deleted Successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete customer: $e'),
        ),
      );
    }
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (_) => CustomerDialog(
        onSave: (
            name,
            phone,
            email,
            address,
            ) {
          _addCustomer(
            name,
            phone,
            email,
            address,
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(
      Customer customer,
      ) async {
    await showDialog(
      context: context,
      builder: (_) => CustomerDialog(
        initialName: customer.name,
        initialPhone: customer.phone,
        initialEmail: customer.email,
        initialAddress: customer.address,
        onSave: (
            name,
            phone,
            email,
            address,
            ) {
          _updateCustomer(
            customer,
            name,
            phone,
            email,
            address,
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      Customer customer,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          "Are you sure you want to delete '${customer.name}'?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteCustomer(customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final customers = provider.customers;

        if (_searchController.text.isEmpty) {
          _filteredCustomers = customers;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customers'),
            centerTitle: true,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddDialog,
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Customer',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterCustomers(
                          customers,
                          '',
                        );
                      },
                      icon: const Icon(Icons.clear),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (value) {
                    _filterCustomers(
                      customers,
                      value,
                    );
                  },
                ),
              ),
              Expanded(
                child: _filteredCustomers.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Customers Found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount:
                  _filteredCustomers.length,
                  itemBuilder:
                      (context, index) {
                    final customer =
                    _filteredCustomers[index];

                    return CustomerTile(
                      customer: customer,
                      onEdit: () {
                        _showEditDialog(
                          customer,
                        );
                      },
                      onDelete: () {
                        _confirmDelete(
                          customer,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}