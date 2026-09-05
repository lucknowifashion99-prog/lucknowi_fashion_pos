import 'package:flutter/material.dart';

class SupplierDialog extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final String? initialEmail;
  final String? initialAddress;

  final Function(
      String name,
      String phone,
      String? email,
      String? address,
      ) onSave;

  const SupplierDialog({
    super.key,
    this.initialName,
    this.initialPhone,
    this.initialEmail,
    this.initialAddress,
    required this.onSave,
  });

  @override
  State<SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<SupplierDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialName ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.initialPhone ?? '',
    );

    _emailController = TextEditingController(
      text: widget.initialEmail ?? '',
    );

    _addressController = TextEditingController(
      text: widget.initialAddress ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Supplier' : 'Add Supplier',
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Supplier Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter supplier name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }

                    if (value.trim().length < 10) {
                      return 'Please enter a valid phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value != null &&
                        value.trim().isNotEmpty &&
                        !value.contains('@')) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Address (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            widget.onSave(
              _nameController.text.trim(),
              _phoneController.text.trim(),
              _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
            );

            Navigator.pop(context);
          },
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }
}