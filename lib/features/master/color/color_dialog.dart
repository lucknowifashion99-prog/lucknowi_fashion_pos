import 'package:flutter/material.dart';

class ColorDialog extends StatefulWidget {
  final String? initialName;
  final String? initialCode;
  final Function(String, String?) onSave;

  const ColorDialog({
    super.key,
    this.initialName,
    this.initialCode,
    required this.onSave,
  });

  @override
  State<ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<ColorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.initialName ?? '');

    _codeController =
        TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName == null
            ? "Add Color"
            : "Edit Color",
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Color Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.palette),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Enter color name";
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Hex Code (Optional)",
                hintText: "#FF0000",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.colorize),
              ),
            ),
          ],
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
              widget.onSave(
                _nameController.text.trim(),
                _codeController.text.trim().isEmpty
                    ? null
                    : _codeController.text.trim(),
              );

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