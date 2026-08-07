import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/brand.dart';
import '../../../providers/brand_provider.dart';
import 'brand_dialog.dart';
import 'widgets/brand_tile.dart';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
final TextEditingController _searchController =
TextEditingController();

List<Brand> _filteredBrands = [];

@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
context.read<BrandProvider>().loadBrands();
});
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

void _filterBrands(
List<Brand> brands,
String keyword,
) {
setState(() {
_filteredBrands = brands
.where(
(e) => e.name
.toLowerCase()
.contains(keyword.toLowerCase()),
)
.toList();
});
}
Future<void> _addBrand(String name) async {
final provider = context.read<BrandProvider>();

await provider.addBrand(
Brand(
name: name,
createdAt: DateTime.now().toIso8601String(),
),
);

await provider.loadBrands();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Brand Added Successfully"),
),
);
}

Future<void> _updateBrand(
Brand brand,
String name,
) async {
final provider = context.read<BrandProvider>();

await provider.updateBrand(
Brand(
id: brand.id,
name: name,
createdAt: brand.createdAt,
),
);

await provider.loadBrands();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Brand Updated Successfully"),
),
);
}

Future<void> _deleteBrand(Brand brand) async {
final provider = context.read<BrandProvider>();

await provider.deleteBrand(brand.id!);

await provider.loadBrands();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Brand Deleted Successfully"),
),
);
}
@override
Widget build(BuildContext context) {
return Consumer<BrandProvider>(
builder: (context, provider, child) {
final brands = provider.brands;

if (_searchController.text.isEmpty) {
_filteredBrands = brands;
}

return Scaffold(
appBar: AppBar(
title: const Text("Brands"),
centerTitle: true,
),

floatingActionButton: FloatingActionButton(
onPressed: () {
showDialog(
context: context,
builder: (_) => BrandDialog(
onSave: (name) {
_addBrand(name);
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
hintText: "Search Brand",
prefixIcon: const Icon(Icons.search),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
),
),
onChanged: (value) {
_filterBrands(brands, value);
},
),
),
Expanded(
child: _filteredBrands.isEmpty
? const Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.branding_watermark,
size: 80,
color: Colors.grey,
),
SizedBox(height: 16),
Text(
"No Brands Found",
style: TextStyle(
fontSize: 18,
color: Colors.grey,
),
),
],
),
)
: ListView.builder(
itemCount: _filteredBrands.length,
itemBuilder: (context, index) {
final brand = _filteredBrands[index];

return BrandTile(
brand: brand,

onEdit: () {
showDialog(
context: context,
builder: (_) => BrandDialog(
initialName: brand.name,
onSave: (name) {
_updateBrand(brand, name);
},
),
);
},

onDelete: () async {
final confirm =
await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
title: const Text("Delete Brand"),
content: Text(
"Delete '${brand.name}' ?",
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(
context,
false,
);
},
child: const Text("Cancel"),
),
ElevatedButton(
onPressed: () {
Navigator.pop(
context,
true,
);
},
child: const Text("Delete"),
),
],
),
);

if (confirm == true) {
_deleteBrand(brand);
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