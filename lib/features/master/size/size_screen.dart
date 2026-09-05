import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/size.dart';
import '../../../providers/size_provider.dart';
import 'size_dialog.dart';
import 'widgets/size_tile.dart';

class SizeScreen extends StatefulWidget {
  const SizeScreen({super.key});

  @override
  State<SizeScreen> createState() => _SizeScreenState();
}

class _SizeScreenState extends State<SizeScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  List<SizeModel> _filteredSizes = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SizeProvider>().loadSizes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSizes(
      List<SizeModel> sizes,
      String keyword,
      ) {
    setState(() {
      _filteredSizes = sizes
          .where(
            (size) => size.name
            .toLowerCase()
            .contains(keyword.toLowerCase()),
      )
          .toList();
    });
  }

  Future<void> _addSize(String name) async {
    final provider = context.read<SizeProvider>();

    try {
      await provider.addSize(
        SizeModel(
          name: name,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Size Added Successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add size: $e'),
        ),
      );
    }
  }

  Future<void> _updateSize(
      SizeModel size,
      String name,
      ) async {
    final provider = context.read<SizeProvider>();

    try {
      await provider.updateSize(
        SizeModel(
          id: size.id,
          name: name,
          createdAt: size.createdAt,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Size Updated Successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update size: $e'),
        ),
      );
    }
  }

  Future<void> _deleteSize(SizeModel size) async {
    final provider = context.read<SizeProvider>();

    try {
      await provider.deleteSize(size.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Size Deleted Successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete size: $e'),
        ),
      );
    }
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (_) => SizeDialog(
        onSave: (name) {
          _addSize(name);
        },
      ),
    );
  }

  Future<void> _showEditDialog(SizeModel size) async {
    await showDialog(
      context: context,
      builder: (_) => SizeDialog(
        initialName: size.name,
        onSave: (name) {
          _updateSize(size, name);
        },
      ),
    );
  }

  Future<void> _confirmDelete(SizeModel size) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Size'),
        content: Text(
          "Are you sure you want to delete '${size.name}'?",
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
      ),
    );

    if (confirm == true) {
      await _deleteSize(size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SizeProvider>(
      builder: (context, provider, child) {
        final sizes = provider.sizes;

        if (_searchController.text.isEmpty) {
          _filteredSizes = sizes;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sizes'),
            centerTitle: true,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddDialog,
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Size',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterSizes(sizes, '');
                      },
                      icon: const Icon(Icons.clear),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (value) {
                    _filterSizes(sizes, value);
                  },
                ),
              ),
              Expanded(
                child: _filteredSizes.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Sizes Found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredSizes.length,
                  itemBuilder: (context, index) {
                    final size = _filteredSizes[index];

                    return SizeTile(
                      size: size,
                      onEdit: () {
                        _showEditDialog(size);
                      },
                      onDelete: () {
                        _confirmDelete(size);
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