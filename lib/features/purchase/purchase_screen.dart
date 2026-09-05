import 'purchase_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../models/supplier.dart';
import '../../providers/product_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../repositories/purchase_repository.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final TextEditingController _invoiceController =
  TextEditingController();

  final TextEditingController _discountController =
  TextEditingController(text: '0');

  DateTime _purchaseDate = DateTime.now();

  Supplier? _selectedSupplier;

  final List<_PurchaseLine> _items = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<SupplierProvider>().loadSuppliers();

      _invoiceController.text =
      'PUR-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // =========================================================
  // TOTALS
  // =========================================================

  double get subtotal {
    return _items.fold(
      0,
          (sum, item) => sum + item.total,
    );
  }

  double get discount {
    return double.tryParse(
      _discountController.text.trim(),
    ) ??
        0;
  }

  double get gst {
    return _items.fold(
      0,
          (sum, item) => sum + item.gstAmount,
    );
  }

  double get grandTotal {
    final value = subtotal + gst - discount;

    return value < 0 ? 0 : value;
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _purchaseDate = date;
      });
    }
  }

  // =========================================================
  // ADD ITEM
  // =========================================================

  Future<void> _addItem() async {
    final productProvider =
    context.read<ProductProvider>();

    if (productProvider.products.isEmpty) {
      _showMessage(
        'Pehle Product add karein.',
        isError: true,
      );
      return;
    }

    final result = await showDialog<_PurchaseLine>(
      context: context,
      builder: (_) => _AddPurchaseItemDialog(
        products: productProvider.products,
      ),
    );

    if (result == null) return;

    setState(() {
      _items.add(result);
    });
  }

  // =========================================================
  // REMOVE ITEM
  // =========================================================

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  // =========================================================
  // SAVE PURCHASE
  // =========================================================

  Future<void> _savePurchase() async {
    if (_saving) return;

    if (_selectedSupplier == null) {
      _showMessage(
        'Supplier select karein.',
        isError: true,
      );
      return;
    }

    if (_invoiceController.text.trim().isEmpty) {
      _showMessage(
        'Invoice number enter karein.',
        isError: true,
      );
      return;
    }

    if (_items.isEmpty) {
      _showMessage(
        'Kam se kam ek item add karein.',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final provider =
      context.read<PurchaseProvider>();

      final purchaseItems = _items.map((item) {
        return PurchaseItemData(
          variantId: item.variant.id!,
          productName: item.product.name,
          color: item.variant.color,
          size: item.variant.size,
          sku: item.variant.sku,
          barcode: item.variant.barcode,
          quantity: item.quantity,
          purchasePrice: item.purchasePrice,
          gst: item.gstAmount,
          discount: 0,
          total: item.total,
        );
      }).toList();

      await provider.savePurchase(
        invoiceNumber:
        _invoiceController.text.trim(),
        supplierId: _selectedSupplier!.id,
        subtotal: subtotal,
        discount: discount,
        gst: gst,
        grandTotal: grandTotal,
        paymentMethod: 'Cash',
        paymentStatus: 'Paid',
        createdAt: _purchaseDate.toIso8601String(),
        items: purchaseItems,
      );

      if (!mounted) return;

      _showMessage(
        'Purchase saved successfully.',
      );

      setState(() {
        _items.clear();
        _selectedSupplier = null;
        _discountController.text = '0';

        _invoiceController.text =
        'PUR-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Purchase save failed: $e',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? Colors.red : Colors.green,
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const PurchaseHistoryScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.history,
            ),
            tooltip: 'Purchase History',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // =================================================
                // PURCHASE DETAILS
                // =================================================

                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _invoiceController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Number',
                            prefixIcon:
                            Icon(Icons.receipt_long),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Consumer<SupplierProvider>(
                          builder:
                              (context, provider, child) {
                            return DropdownButtonFormField<
                                Supplier>(
                              value: _selectedSupplier,
                              decoration:
                              const InputDecoration(
                                labelText: 'Supplier',
                                prefixIcon:
                                Icon(Icons.person),
                                border:
                                OutlineInputBorder(),
                              ),
                              items:
                              provider.suppliers.map(
                                    (supplier) {
                                  return DropdownMenuItem<
                                      Supplier>(
                                    value: supplier,
                                    child: Text(
                                      supplier.name,
                                    ),
                                  );
                                },
                              ).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSupplier =
                                      value;
                                });
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        InkWell(
                          onTap: _selectDate,
                          borderRadius:
                          BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration:
                            const InputDecoration(
                              labelText: 'Purchase Date',
                              prefixIcon:
                              Icon(Icons.calendar_today),
                              border:
                              OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('dd-MM-yyyy')
                                  .format(_purchaseDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // ITEMS HEADER
                // =================================================

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Purchase Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                      _saving ? null : _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // =================================================
                // EMPTY
                // =================================================

                if (_items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 60,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No purchase items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add product/variant to continue.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // =================================================
                // ITEMS
                // =================================================

                ..._items.asMap().entries.map(
                      (entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return Card(
                      margin:
                      const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            '${item.quantity}',
                          ),
                        ),
                        title: Text(
                          item.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${item.variant.color} / '
                              '${item.variant.size}\n'
                              'SKU: ${item.variant.sku}\n'
                              '₹${item.purchasePrice.toStringAsFixed(2)} × '
                              '${item.quantity}',
                        ),
                        isThreeLine: true,
                        trailing: SizedBox(
                          width: 90,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '₹${item.total.toStringAsFixed(2)}',
                                  textAlign:
                                  TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _saving
                                    ? null
                                    : () {
                                  _removeItem(index);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // =================================================
                // SUMMARY
                // =================================================

                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _summaryRow(
                          'Subtotal',
                          subtotal,
                        ),
                        const SizedBox(height: 8),
                        _summaryRow(
                          'GST',
                          gst,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller:
                          _discountController,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                          const InputDecoration(
                            labelText: 'Discount',
                            prefixText: '₹ ',
                            border:
                            OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 8),
                        _summaryRow(
                          'GRAND TOTAL',
                          grandTotal,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // =======================================================
          // SAVE BUTTON
          // =======================================================

          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .scaffoldBackgroundColor,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black12,
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                _saving ? null : _savePurchase,
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _saving
                      ? 'SAVING...'
                      : 'SAVE PURCHASE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY ROW
  // =========================================================

  Widget _summaryRow(
      String title,
      double amount, {
        bool bold = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: bold ? 18 : 15,
              fontWeight:
              bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: bold ? 18 : 15,
            fontWeight:
            bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// PURCHASE LINE
// =============================================================

class _PurchaseLine {
  final Product product;
  final ProductVariant variant;
  final int quantity;
  final double purchasePrice;

  const _PurchaseLine({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.purchasePrice,
  });

  double get total {
    return quantity * purchasePrice;
  }

  double get gstAmount {
    return total * product.gst / 100;
  }
}

// =============================================================
// ADD PURCHASE ITEM DIALOG
// =============================================================

class _AddPurchaseItemDialog extends StatefulWidget {
  final List<Product> products;

  const _AddPurchaseItemDialog({
    required this.products,
  });

  @override
  State<_AddPurchaseItemDialog> createState() =>
      _AddPurchaseItemDialogState();
}

class _AddPurchaseItemDialogState
    extends State<_AddPurchaseItemDialog> {
  Product? _selectedProduct;

  ProductVariant? _selectedVariant;

  final TextEditingController _quantityController =
  TextEditingController(text: '1');

  final TextEditingController _priceController =
  TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadVariants(
      Product product,
      ) async {
    await context
        .read<ProductProvider>()
        .loadVariants(product.id!);

    if (!mounted) return;

    setState(() {
      _selectedVariant = null;
      _priceController.clear();
    });
  }

  void _selectVariant(ProductVariant? variant) {
    setState(() {
      _selectedVariant = variant;

      if (variant != null) {
        _priceController.text =
            variant.purchasePrice.toStringAsFixed(2);
      } else {
        _priceController.clear();
      }
    });
  }

  void _save() {
    final product = _selectedProduct;
    final variant = _selectedVariant;

    final quantity =
        int.tryParse(
          _quantityController.text.trim(),
        ) ??
            0;

    final price =
        double.tryParse(
          _priceController.text.trim(),
        ) ??
            0;

    if (product == null) {
      _showError('Product select karein.');
      return;
    }

    if (variant == null) {
      _showError('Variant select karein.');
      return;
    }

    if (quantity <= 0) {
      _showError('Quantity 1 ya usse zyada honi chahiye.');
      return;
    }

    if (price <= 0) {
      _showError('Purchase price enter karein.');
      return;
    }

    Navigator.pop(
      context,
      _PurchaseLine(
        product: product,
        variant: variant,
        quantity: quantity,
        purchasePrice: price,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Purchase Item'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PRODUCT
              DropdownButtonFormField<Product>(
                value: _selectedProduct,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  prefixIcon:
                  Icon(Icons.inventory_2),
                  border: OutlineInputBorder(),
                ),
                items: widget.products.map(
                      (product) {
                    return DropdownMenuItem<Product>(
                      value: product,
                      child: Text(product.name),
                    );
                  },
                ).toList(),
                onChanged: (product) {
                  if (product == null) return;

                  setState(() {
                    _selectedProduct = product;
                  });

                  _loadVariants(product);
                },
              ),

              const SizedBox(height: 14),

              // VARIANT
              Consumer<ProductProvider>(
                builder:
                    (context, provider, child) {
                  final variants =
                      provider.variants;

                  return DropdownButtonFormField<
                      ProductVariant>(
                    value: _selectedVariant,
                    decoration:
                    const InputDecoration(
                      labelText: 'Variant',
                      prefixIcon:
                      Icon(Icons.style),
                      border:
                      OutlineInputBorder(),
                    ),
                    items: variants
                        .where(
                          (variant) =>
                      variant.isActive,
                    )
                        .map(
                          (variant) {
                        return DropdownMenuItem<
                            ProductVariant>(
                          value: variant,
                          child: Text(
                            '${variant.color} / '
                                '${variant.size} '
                                '(${variant.sku})',
                          ),
                        );
                      },
                    ).toList(),
                    onChanged:
                    _selectVariant,
                  );
                },
              ),

              const SizedBox(height: 14),

              // QUANTITY
              TextField(
                controller: _quantityController,
                keyboardType:
                TextInputType.number,
                decoration:
                const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon:
                  Icon(Icons.numbers),
                  border:
                  OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              // PURCHASE PRICE
              TextField(
                controller: _priceController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                const InputDecoration(
                  labelText: 'Purchase Price',
                  prefixText: '₹ ',
                  prefixIcon:
                  Icon(Icons.currency_rupee),
                  border:
                  OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('CANCEL'),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.add),
          label: const Text('ADD'),
        ),
      ],
    );
  }
}