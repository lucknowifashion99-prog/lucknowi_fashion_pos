import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product.dart';
import '../../../models/product_variant.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/color_provider.dart';
import '../../../providers/size_provider.dart';
import '../../../services/printer_service.dart';
import 'variant_dialog.dart';

class VariantScreen extends StatefulWidget {
  final Product product;

  const VariantScreen({
    super.key,
    required this.product,
  });

  @override
  State<VariantScreen> createState() => _VariantScreenState();
}

class _VariantScreenState extends State<VariantScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ProductProvider>().loadVariants(
        widget.product.id!,
      );

      context.read<ColorProvider>().loadColors();
      context.read<SizeProvider>().loadSizes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // ADD VARIANT
  // =========================================================

  Future<void> _showAddDialog() async {
    final provider = context.read<ProductProvider>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return VariantDialog(
          productId: widget.product.id!,
          onSave: (variant) async {
            await provider.addVariant(variant);
          },
        );
      },
    );

    if (!mounted) return;

    await provider.loadVariants(
      widget.product.id!,
    );
  }

  // =========================================================
  // EDIT VARIANT
  // =========================================================

  Future<void> _showEditDialog(
      ProductVariant variant,
      ) async {
    final provider = context.read<ProductProvider>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return VariantDialog(
          productId: widget.product.id!,
          variant: variant,
          onSave: (updatedVariant) async {
            await provider.updateVariant(
              updatedVariant,
            );
          },
        );
      },
    );

    if (!mounted) return;

    // Database se fresh data load.
    await provider.loadVariants(
      widget.product.id!,
    );
  }

  // =========================================================
  // DELETE VARIANT
  // =========================================================

  Future<void> _deleteVariant(
      ProductVariant variant,
      ) async {
    if (variant.id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Variant'),
          content: Text(
            'Are you sure you want to delete '
                '${variant.color} / ${variant.size}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    final provider = context.read<ProductProvider>();

    await provider.deleteVariant(variant);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Variant deleted successfully'),
      ),
    );
  }

  // =========================================================
  // PRINT BARCODE
  // =========================================================

  Future<void> _printBarcode(
      ProductVariant variant,
      ) async {
    final printer = PrinterService.instance;

    int? quantity;

    quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        final quantityController =
        TextEditingController(
          text: variant.stock > 0
              ? variant.stock.toString()
              : '1',
        );

        bool printAllStock =
            variant.stock > 0;

        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.print),
                  SizedBox(width: 10),
                  Text('Print Barcode'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Color: ${variant.color}',
                  ),

                  Text(
                    'Size: ${variant.size}',
                  ),

                  Text(
                    'SKU: ${variant.sku}',
                  ),

                  Text(
                    'Barcode: ${variant.barcode}',
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller:
                    quantityController,
                    enabled: !printAllStock,
                    keyboardType:
                    TextInputType.number,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Number of Labels',
                      border:
                      OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  CheckboxListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    value: printAllStock,
                    onChanged: (value) {
                      setDialogState(() {
                        printAllStock =
                            value ?? false;
                      });
                    },
                    title: const Text(
                      'Print all available stock',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    int labelQuantity;

                    if (printAllStock) {
                      labelQuantity =
                          variant.stock;
                    } else {
                      labelQuantity =
                          int.tryParse(
                            quantityController
                                .text
                                .trim(),
                          ) ??
                              0;
                    }

                    if (labelQuantity <= 0) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter valid quantity',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      labelQuantity,
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
              ],
            );
          },
        );
      },
    );

    if (quantity == null) return;

    if (!printer.hasSelectedPrinter) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a printer first',
          ),
        ),
      );
      return;
    }

    final bool success =
    await printer.printBarcodeLabel(
      productName: widget.product.name,
      color: variant.color,
      size: variant.size,
      sku: variant.sku,
      barcode: variant.barcode,
      sellingPrice: variant.sellingPrice,
      quantity: quantity,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Barcode printed successfully'
              : 'Barcode printing failed',
        ),
      ),
    );
  }

  // =========================================================
  // SEARCH
  // =========================================================

  List<ProductVariant> _filteredVariants(
      List<ProductVariant> variants,
      ) {
    final query = _searchQuery
        .trim()
        .toLowerCase();

    if (query.isEmpty) {
      return variants;
    }

    return variants.where((variant) {
      return variant.color
          .toLowerCase()
          .contains(query) ||
          variant.size
              .toLowerCase()
              .contains(query) ||
          variant.sku
              .toLowerCase()
              .contains(query) ||
          variant.barcode
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  // =========================================================
  // VARIANT CARD
  // =========================================================

  Widget _buildVariantCard(
      ProductVariant variant,
      ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${variant.color} / ${variant.size}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(
                        variant,
                      );
                    }

                    if (value == 'delete') {
                      _deleteVariant(
                        variant,
                      );
                    }

                    if (value == 'print') {
                      _printBarcode(
                        variant,
                      );
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'print',
                        child: Row(
                          children: [
                            Icon(Icons.print),
                            SizedBox(width: 10),
                            Text(
                              'Print Barcode',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),

            const Divider(),

            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _infoItem(
                  'SKU',
                  variant.sku,
                ),
                _infoItem(
                  'Barcode',
                  variant.barcode,
                ),
                _infoItem(
                  'Purchase Price',
                  '₹${variant.purchasePrice.toStringAsFixed(2)}',
                ),
                _infoItem(
                  'Selling Price',
                  '₹${variant.sellingPrice.toStringAsFixed(2)}',
                ),
                _infoItem(
                  'Stock',
                  variant.stock.toString(),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showEditDialog(
                        variant,
                      );
                    },
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'Edit',
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _printBarcode(
                        variant,
                      );
                    },
                    icon: const Icon(
                      Icons.print,
                    ),
                    label: const Text(
                      'Print Barcode',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(
      String title,
      String value,
      ) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        title: Text(
          '${widget.product.name} - Variants',
        ),
      ),

      body: Consumer<ProductProvider>(
        builder: (
            context,
            provider,
            child,
            ) {
          final variants =
          _filteredVariants(
            provider.variants,
          );

          return Column(
            children: [
              // SEARCH
              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  8,
                ),
                child: TextField(
                  controller:
                  _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration:
                  InputDecoration(
                    hintText:
                    'Search color, size, SKU or barcode',
                    prefixIcon:
                    const Icon(
                      Icons.search,
                    ),
                    suffixIcon:
                    _searchQuery.isEmpty
                        ? null
                        : IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(() {
                          _searchQuery =
                          '';
                        });
                      },
                      icon: const Icon(
                        Icons.clear,
                      ),
                    ),
                    border:
                    const OutlineInputBorder(),
                  ),
                ),
              ),

              // HEADER
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Variants (${variants.length})',
                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed:
                      _showAddDialog,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        'Add Variant',
                      ),
                    ),
                  ],
                ),
              ),

              // LIST
              Expanded(
                child: variants.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 60,
                        color: Colors
                            .grey
                            .shade400,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        _searchQuery
                            .isEmpty
                            ? 'No variants found'
                            : 'No matching variants',
                        style:
                        TextStyle(
                          fontSize: 16,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: () {
                    return provider
                        .loadVariants(
                      widget.product.id!,
                    );
                  },
                  child: ListView.builder(
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      16,
                      8,
                      16,
                      100,
                    ),
                    itemCount:
                    variants.length,
                    itemBuilder:
                        (context, index) {
                      return _buildVariantCard(
                        variants[index],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Variant',
        ),
      ),
    );
  }
}