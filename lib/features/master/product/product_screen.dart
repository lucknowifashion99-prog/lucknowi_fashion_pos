import 'variant_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product.dart';
import '../../../providers/product_provider.dart';
import 'product_dialog.dart';
import 'widgets/product_tile.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(
      List<Product> products,
      String keyword,
      ) {
    setState(() {
      final search = keyword.trim().toLowerCase();

      _filteredProducts = products.where((product) {
        return product.name
            .toLowerCase()
            .contains(search);
      }).toList();
    });
  }

  Future<void> _addProduct(Product product) async {
    final provider = context.read<ProductProvider>();

    try {
      await provider.addProduct(product);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product Added Successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add product: $e',
          ),
        ),
      );
    }
  }

  Future<void> _updateProduct(Product product) async {
    final provider = context.read<ProductProvider>();

    try {
      await provider.updateProduct(product);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product Updated Successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update product: $e',
          ),
        ),
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    if (product.id == null) return;

    final provider = context.read<ProductProvider>();

    try {
      await provider.deleteProduct(product.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product Deleted Successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete product: $e',
          ),
        ),
      );
    }
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (_) {
        return ProductDialog(
          onSave: (product) {
            _addProduct(product);
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(Product product) async {
    await showDialog(
      context: context,
      builder: (_) {
        return ProductDialog(
          product: product,
          onSave: (updatedProduct) {
            _updateProduct(updatedProduct);
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Delete Product',
          ),
          content: Text(
            "Are you sure you want to delete '${product.name}'?",
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
        );
      },
    );

    if (confirm == true) {
      await _deleteProduct(product);
    }
  }

  void _openVariants(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VariantScreen(
          product: product,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final products = provider.products;

        if (_searchController.text.isEmpty) {
          _filteredProducts = products;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Products',
            ),
            centerTitle: true,
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: _showAddDialog,
            child: const Icon(
              Icons.add,
            ),
          ),

          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Product',
                    prefixIcon: const Icon(
                      Icons.search,
                    ),
                    suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();

                        _filterProducts(
                          products,
                          '',
                        );
                      },
                      icon: const Icon(
                        Icons.clear,
                      ),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (value) {
                    _filterProducts(
                      products,
                      value,
                    );
                  },
                ),
              ),

              Expanded(
                child: _filteredProducts.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Products Found',
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
                  _filteredProducts.length,
                  itemBuilder:
                      (context, index) {
                    final product =
                    _filteredProducts[index];

                    return ProductTile(
                      product: product,
                      onEdit: () {
                        _showEditDialog(
                          product,
                        );
                      },
                      onDelete: () {
                        _confirmDelete(
                          product,
                        );
                      },
                      onVariants: () {
                        _openVariants(
                          product,
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