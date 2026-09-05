import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product_variant.dart';
import '../../../providers/color_provider.dart';
import '../../../providers/size_provider.dart';

class VariantDialog extends StatefulWidget {
  final int productId;
  final ProductVariant? variant;
  final Future<void> Function(ProductVariant) onSave;

  const VariantDialog({
    super.key,
    required this.productId,
    this.variant,
    required this.onSave,
  });

  @override
  State<VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<VariantDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _stockController;

  String? _selectedColor;
  String? _selectedSize;

  @override
  void initState() {
    super.initState();

    final variant = widget.variant;

    _skuController = TextEditingController(
      text: variant?.sku ?? '',
    );

    _barcodeController = TextEditingController(
      text: variant?.barcode ?? '',
    );

    _purchasePriceController = TextEditingController(
      text: variant?.purchasePrice.toString() ?? '',
    );

    _sellingPriceController = TextEditingController(
      text: variant?.sellingPrice.toString() ?? '',
    );

    _stockController = TextEditingController(
      text: variant?.stock.toString() ?? '0',
    );

    _selectedColor = variant?.color;
    _selectedSize = variant?.size;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ColorProvider>().loadColors();
      context.read<SizeProvider>().loadSizes();
    });
  }

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select color'),
        ),
      );
      return;
    }

    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select size'),
        ),
      );
      return;
    }

    final variant = ProductVariant(
      id: widget.variant?.id,
      productId: widget.productId,
      sku: _skuController.text.trim(),
      barcode: _barcodeController.text.trim(),
      color: _selectedColor!,
      size: _selectedSize!,
      purchasePrice:
      double.tryParse(
        _purchasePriceController.text.trim(),
      ) ??
          0,
      sellingPrice:
      double.tryParse(
        _sellingPriceController.text.trim(),
      ) ??
          0,
      stock:
      int.tryParse(
        _stockController.text.trim(),
      ) ??
          0,
      image: widget.variant?.image,
      isActive: widget.variant?.isActive ?? true,
    );

    widget.onSave(variant);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        context.watch<ColorProvider>().colors;

    final sizes =
        context.watch<SizeProvider>().sizes;

    final isEdit = widget.variant != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Variant' : 'Add Variant',
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // COLOR
                DropdownButtonFormField<String>(
                  initialValue: _selectedColor,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    prefixIcon: Icon(
                      Icons.palette,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: colors.map((color) {
                    return DropdownMenuItem<String>(
                      value: color.name,
                      child: Text(color.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedColor = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select color';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // SIZE
                DropdownButtonFormField<String>(
                  initialValue: _selectedSize,
                  decoration: const InputDecoration(
                    labelText: 'Size',
                    prefixIcon: Icon(
                      Icons.straighten,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: sizes.map((size) {
                    return DropdownMenuItem<String>(
                      value: size.name,
                      child: Text(size.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSize = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select size';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // SKU
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU',
                    prefixIcon: Icon(
                      Icons.qr_code_2,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter SKU';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // BARCODE
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    prefixIcon: Icon(
                      Icons.barcode_reader,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter barcode';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // PURCHASE PRICE
                TextFormField(
                  controller: _purchasePriceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price',
                    prefixIcon: Icon(
                      Icons.shopping_cart,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final price = double.tryParse(
                      value?.trim() ?? '',
                    );

                    if (price == null || price < 0) {
                      return 'Enter valid purchase price';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // SELLING PRICE
                TextFormField(
                  controller: _sellingPriceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Selling Price',
                    prefixIcon: Icon(
                      Icons.sell,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final price = double.tryParse(
                      value?.trim() ?? '',
                    );

                    if (price == null || price < 0) {
                      return 'Enter valid selling price';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // STOCK
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening Stock',
                    prefixIcon: Icon(
                      Icons.inventory,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final stock = int.tryParse(
                      value?.trim() ?? '',
                    );

                    if (stock == null || stock < 0) {
                      return 'Enter valid stock';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: Text(
            isEdit ? 'Update' : 'Save',
          ),
        ),
      ],
    );
  }
}