import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/supplier.dart';
import '../../../providers/supplier_provider.dart';
import 'supplier_dialog.dart';
import 'widgets/supplier_tile.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  List<Supplier> _filteredSuppliers = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSuppliers(
      List<Supplier> suppliers,
      String keyword,
      ) {
    setState(() {
      final search = keyword.trim().toLowerCase();

      _filteredSuppliers = suppliers.where((supplier) {
        return supplier.name.toLowerCase().contains(search) ||
            supplier.phone.toLowerCase().contains(search) ||
            (supplier.email?.toLowerCase().contains(search) ?? false);
      }).toList();
    });
  }

  Future<void> _addSupplier(
      String name,
      String phone,
      String? email,
      String? address,
      ) async {
    final provider = context.read<SupplierProvider>();

    try {
      await provider.addSupplier(
        Supplier(
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
          content: Text('Supplier Added Successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add supplier: $e'),
        ),
      );
    }
  }

  Future<void> _updateSupplier(
      Supplier supplier,
      String name,
      String phone,
      String? email,
      String? address,
      ) async {
    final provider = context.read<SupplierProvider>();

    try {
      await provider.updateSupplier(
        Supplier(
          id: supplier.id,
          name: name,
          phone: phone,
          email: email,
          address: address,
          createdAt: supplier.createdAt,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supplier Updated Successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update supplier: $e'),
        ),
      );
    }
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    if (supplier.id == null) return;

    final provider = context.read<SupplierProvider>();

    try {
      await provider.deleteSupplier(supplier.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supplier Deleted Successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete supplier: $e'),
        ),
      );
    }
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (_) => SupplierDialog(
        onSave: (
            name,
            phone,
            email,
            address,
            ) {
          _addSupplier(
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
      Supplier supplier,
      ) async {
    await showDialog(
      context: context,
      builder: (_) => SupplierDialog(
        initialName: supplier.name,
        initialPhone: supplier.phone,
        initialEmail: supplier.email,
        initialAddress: supplier.address,
        onSave: (
            name,
            phone,
            email,
            address,
            ) {
          _updateSupplier(
            supplier,
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
      Supplier supplier,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text(
          "Are you sure you want to delete '${supplier.name}'?",
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
      await _deleteSupplier(supplier);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(
      builder: (context, provider, child) {
        final suppliers = provider.suppliers;

        if (_searchController.text.isEmpty) {
          _filteredSuppliers = suppliers;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Suppliers'),
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
                    hintText: 'Search Supplier',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterSuppliers(
                          suppliers,
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
                    _filterSuppliers(
                      suppliers,
                      value,
                    );
                  },
                ),
              ),

              Expanded(
                child: _filteredSuppliers.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Suppliers Found',
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
                  _filteredSuppliers.length,
                  itemBuilder:
                      (context, index) {
                    final supplier =
                    _filteredSuppliers[index];

                    return SupplierTile(
                      supplier: supplier,
                      onEdit: () {
                        _showEditDialog(
                          supplier,
                        );
                      },
                      onDelete: () {
                        _confirmDelete(
                          supplier,
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