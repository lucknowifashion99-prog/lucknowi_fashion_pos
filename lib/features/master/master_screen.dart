import 'package:flutter/material.dart';

import 'category/category_screen.dart';
import 'brand/brand_screen.dart';

class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key});

  Widget menuCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Master Data"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: [
            // Category
            menuCard(
              context,
              "Category",
              Icons.category,
              Colors.blue,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoryScreen(),
                  ),
                );
              },
            ),

            // Brand
            menuCard(
              context,
              "Brand",
              Icons.sell,
              Colors.orange,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BrandScreen(),
                  ),
                );
              },
            ),

            // Color
            menuCard(
              context,
              "Color",
              Icons.palette,
              Colors.purple,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Color Module Coming Soon"),
                  ),
                );
              },
            ),

            // Size
            menuCard(
              context,
              "Size",
              Icons.straighten,
              Colors.green,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Size Module Coming Soon"),
                  ),
                );
              },
            ),

            // Supplier
            menuCard(
              context,
              "Supplier",
              Icons.local_shipping,
              Colors.red,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Supplier Module Coming Soon"),
                  ),
                );
              },
            ),

            // Customer
            menuCard(
              context,
              "Customer",
              Icons.people,
              Colors.teal,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Customer Module Coming Soon"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}