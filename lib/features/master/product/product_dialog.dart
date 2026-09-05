import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/brand_provider.dart';

class ProductDialog extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductDialog({
    super.key,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _hsnController;
  late final TextEditingController _gstController;
  late final TextEditingController _descriptionController;

  int? _categoryId;
  int? _brandId;
  String? _department;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _nameController = TextEditingController(
      text: product?.name ?? '',
    );

    _hsnController = TextEditingController(
      text: product?.hsn ?? '',
    );

    _gstController = TextEditingController(
      text: product?.gst.toString() ?? '0',
    );

    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );

    _categoryId = product?.categoryId;
    _brandId = product?.brandId;
    _department = product?.department;

    // Category aur Brand database se load karo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<BrandProvider>().loadBrands();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hsnController.dispose();
    _gstController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select category'),
        ),
      );
      return;
    }

    final now = DateTime.now().toIso8601String();

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      categoryId: _categoryId!,
      brandId: _brandId,
      department: _department,
      hsn: _hsnController.text.trim().isEmpty
          ? null
          : _hsnController.text.trim(),
      gst: double.tryParse(
        _gstController.text.trim(),
      ) ??
          0,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(product);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final brands = context.watch<BrandProvider>().brands;

    final isEdit = widget.product != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Product' : 'Add Product',
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PRODUCT NAME
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    prefixIcon: Icon(Icons.inventory_2),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // CATEGORY
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select category';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // BRAND
                DropdownButtonFormField<int>(
                  initialValue: _brandId,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    prefixIcon: Icon(Icons.sell),
                    border: OutlineInputBorder(),
                  ),
                  items: brands.map((brand) {
                    return DropdownMenuItem<int>(
                      value: brand.id,
                      child: Text(brand.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _brandId = value;
                    });
                  },
                ),

                const SizedBox(height: 14),

                // DEPARTMENT
                DropdownButtonFormField<String>(
                  initialValue: _department,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Men',
                      child: Text('Men'),
                    ),
                    DropdownMenuItem(
                      value: 'Women',
                      child: Text('Women'),
                    ),
                    DropdownMenuItem(
                      value: 'Kids',
                      child: Text('Kids'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _department = value;
                    });
                  },
                ),

                const SizedBox(height: 14),

                // HSN
                TextFormField(
                  controller: _hsnController,
                  decoration: const InputDecoration(
                    labelText: 'HSN Code',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                // GST
                TextFormField(
                  controller: _gstController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'GST %',
                    prefixIcon: Icon(Icons.percent),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final gst = double.tryParse(
                      value?.trim() ?? '',
                    );

                    if (gst == null) {
                      return 'Enter valid GST';
                    }

                    if (gst < 0 || gst > 100) {
                      return 'GST must be between 0 and 100';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // DESCRIPTION
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
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