import 'package:flutter/material.dart';

class SizeDialog extends StatefulWidget {
  final String? initialName;
  final Function(String) onSave;

  const SizeDialog({
    super.key,
    this.initialName,
    required this.onSave,
  });

  @override
  State<SizeDialog> createState() => _SizeDialogState();
}

class _SizeDialogState extends State<SizeDialog> {
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
    final isEdit = widget.initialName != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Size' : 'Add Size',
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Size Name',
            hintText: 'Example: M, L, XL, 32, 34',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.straighten),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter size';
            }

            return null;
          },
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
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nameController.text.trim().toUpperCase(),
              );

              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }
}