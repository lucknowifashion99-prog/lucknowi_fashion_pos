import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/color_model.dart';
import '../../../providers/color_provider.dart';
import 'color_dialog.dart';
import 'widgets/color_tile.dart';

class ColorScreen extends StatefulWidget {
  const ColorScreen({super.key});

  @override
  State<ColorScreen> createState() => _ColorScreenState();
}

class _ColorScreenState extends State<ColorScreen> {
final TextEditingController _searchController =
TextEditingController();

List<ColorModel> _filteredColors = [];

@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
context.read<ColorProvider>().loadColors();
});
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

void _filterColors(
List<ColorModel> colors,
String keyword,
) {
setState(() {
_filteredColors = colors
.where(
(e) => e.name
.toLowerCase()
.contains(keyword.toLowerCase()),
)
.toList();
});
}
Future<void> _addColor(
String name,
String? code,
) async {
final provider = context.read<ColorProvider>();

await provider.addColor(
ColorModel(
name: name,
code: code,
createdAt: DateTime.now().toIso8601String(),
),
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Color Added Successfully"),
),
);
}

Future<void> _updateColor(
ColorModel color,
String name,
String? code,
) async {
final provider = context.read<ColorProvider>();

await provider.updateColor(
ColorModel(
id: color.id,
name: name,
code: code,
createdAt: color.createdAt,
),
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Color Updated Successfully"),
),
);
}

Future<void> _deleteColor(
ColorModel color,
) async {
final provider = context.read<ColorProvider>();

await provider.deleteColor(color.id!);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Color Deleted Successfully"),
),
);
}
@override
Widget build(BuildContext context) {
return Consumer<ColorProvider>(
builder: (context, provider, child) {
final colors = provider.colors;

if (_searchController.text.isEmpty) {
_filteredColors = colors;
}

return Scaffold(
appBar: AppBar(
title: const Text("Colors"),
centerTitle: true,
),

floatingActionButton: FloatingActionButton(
onPressed: () {
showDialog(
context: context,
builder: (_) => ColorDialog(
onSave: (name, code) {
_addColor(name, code);
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
hintText: "Search Color",
prefixIcon: const Icon(Icons.search),
border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(14),
),
),
onChanged: (value) {
_filterColors(colors, value);
},
),
),
Expanded(
child: _filteredColors.isEmpty
? const Center(
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Icon(
Icons.palette,
size: 80,
color: Colors.grey,
),
SizedBox(height: 16),
Text(
"No Colors Found",
style: TextStyle(
fontSize: 18,
color: Colors.grey,
),
),
],
),
)
: ListView.builder(
itemCount: _filteredColors.length,
itemBuilder: (context, index) {
final color =
_filteredColors[index];

return ColorTile(
color: color,

onEdit: () {
showDialog(
context: context,
builder: (_) =>
ColorDialog(
initialName: color.name,
initialCode: color.code,
onSave:
(name, code) {
_updateColor(
color,
name,
code,
);
},
),
);
},

onDelete: () async {
final confirm =
await showDialog<bool>(
context: context,
builder: (_) =>
AlertDialog(
title: const Text(
"Delete Color",
),
content: Text(
"Delete '${color.name}' ?",
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(
context,
false,
);
},
child: const Text(
"Cancel",
),
),
ElevatedButton(
onPressed: () {
Navigator.pop(
context,
true,
);
},
child: const Text(
"Delete",
),
),
],
),
);

if (confirm == true) {
_deleteColor(color);
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