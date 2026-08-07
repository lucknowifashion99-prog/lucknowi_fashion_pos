import 'package:flutter/material.dart';

class BrandDialog extends StatefulWidget {
  final String? initialName;
  final Function(String) onSave;

  const BrandDialog({
    super.key,
    this.initialName,
    required this.onSave,
  });

  @override
  State<BrandDialog> createState() => _BrandDialogState();
}

class _BrandDialogState extends State<BrandDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName == null
            ? "Add Brand"
            : "Edit Brand",
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Brand Name",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.branding_watermark),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Please enter brand name";
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(_nameController.text.trim());
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.save),
          label: const Text("Save"),
        ),
      ],
    );
  }
}