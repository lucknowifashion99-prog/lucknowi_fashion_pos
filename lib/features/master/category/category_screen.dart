import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/category.dart';
import '../../../providers/category_provider.dart';
import 'category_dialog.dart';
import 'category_tile.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
final TextEditingController _searchController =
TextEditingController();

List<Category> _filteredCategories = [];

@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
context.read<CategoryProvider>().loadCategories();
});
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

void _filterCategories(
List<Category> categories,
String keyword,
) {
setState(() {
_filteredCategories = categories
.where(
(e) => e.name
.toLowerCase()
.contains(keyword.toLowerCase()),
)
.toList();
});
}
Future<void> _addCategory(String name) async {
final provider = context.read<CategoryProvider>();

await provider.addCategory(
Category(
name: name,
image: null,
createdAt: DateTime.now().toIso8601String(),
),
);

await provider.loadCategories();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Category Added Successfully"),
),
);
}

Future<void> _updateCategory(
Category category,
String name,
) async {
final provider = context.read<CategoryProvider>();

await provider.updateCategory(
Category(
id: category.id,
name: name,
image: category.image,
createdAt: category.createdAt,
),
);

await provider.loadCategories();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Category Updated Successfully"),
),
);
}

Future<void> _deleteCategory(Category category) async {
final provider = context.read<CategoryProvider>();

await provider.deleteCategory(category.id!);

await provider.loadCategories();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Category Deleted Successfully"),
),
);
}
@override
Widget build(BuildContext context) {
return Consumer<CategoryProvider>(
builder: (context, provider, child) {
final categories = provider.categories;

if (_searchController.text.isEmpty) {
_filteredCategories = categories;
}

return Scaffold(
appBar: AppBar(
title: const Text("Categories"),
centerTitle: true,
),

floatingActionButton: FloatingActionButton(
onPressed: () {
showDialog(
context: context,
builder: (_) => CategoryDialog(
onSave: (name) {
_addCategory(name);
},
),
);
},
child: const Icon(Icons.add),
),

body: Column(
children: [
Padding(
padding: const EdgeInsets.all(16),
child: TextField(
controller: _searchController,
decoration: InputDecoration(
hintText: "Search Category",
prefixIcon: const Icon(Icons.search),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
),
),
onChanged: (value) {
_filterCategories(categories, value);
},
),
),
Expanded(
child: _filteredCategories.isEmpty
? const Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.category,
size: 80,
color: Colors.grey,
),
SizedBox(height: 16),
Text(
"No Categories Found",
style: TextStyle(
fontSize: 18,
color: Colors.grey,
),
),
],
),
)
: ListView.builder(
itemCount: _filteredCategories.length,
itemBuilder: (context, index) {
final category = _filteredCategories[index];

return CategoryTile(
category: category,

onEdit: () {
showDialog(
context: context,
builder: (_) => CategoryDialog(
initialName: category.name,
onSave: (name) {
_updateCategory(category, name);
},
),
);
},

onDelete: () async {
final confirm =
await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
title: const Text("Delete Category"),
content: Text(
"Delete '${category.name}' ?",
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(
context, false);
},
child:
const Text("Cancel"),
),
ElevatedButton(
onPressed: () {
Navigator.pop(
context, true);
},
child:
const Text("Delete"),
),
],
),
);

if (confirm == true) {
_deleteCategory(category);
}
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