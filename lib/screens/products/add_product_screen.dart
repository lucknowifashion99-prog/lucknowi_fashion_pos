import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      brand: _brandController.text.trim(),
      size: _sizeController.text.trim(),
      color: _colorController.text.trim(),
      purchasePrice:
      double.tryParse(_purchasePriceController.text.trim()) ?? 0,
      sellingPrice:
      double.tryParse(_sellingPriceController.text.trim()) ?? 0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
      barcode: _barcodeController.text.trim(),
    );

    await context.read<ProductProvider>().addProduct(product);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Product saved successfully"),
      ),
    );

    Navigator.pop(context);
  }

  Widget buildField(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        bool required = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildField(
                "Product Name",
                _nameController,
                required: true,
              ),
              buildField("Category", _categoryController),
              buildField("Brand", _brandController),
              buildField("Size", _sizeController),
              buildField("Color", _colorController),
              buildField(
                "Purchase Price",
                _purchasePriceController,
                keyboardType: TextInputType.number,
              ),
              buildField(
                "Selling Price",
                _sellingPriceController,
                keyboardType: TextInputType.number,
              ),
              buildField(
                "Stock",
                _stockController,
                keyboardType: TextInputType.number,
              ),
              buildField("Barcode", _barcodeController),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: const Text(
                    "Save Product",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}