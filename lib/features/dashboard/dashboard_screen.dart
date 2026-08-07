import 'package:flutter/material.dart';

import '../master/master_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
          height: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
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
        title: const Text("Lucknowi Fashion POS"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: [

            menuCard(
              context,
              "Billing",
              Icons.point_of_sale,
              Colors.green,
                  () {},
            ),

            menuCard(
              context,
              "Products",
              Icons.inventory_2,
              Colors.orange,
                  () {},
            ),

            menuCard(
              context,
              "Master Data",
              Icons.dashboard_customize,
              Colors.blue,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MasterScreen(),
                  ),
                );
              },
            ),

            menuCard(
              context,
              "Purchase",
              Icons.shopping_cart,
              Colors.purple,
                  () {},
            ),

            menuCard(
              context,
              "Reports",
              Icons.bar_chart,
              Colors.red,
                  () {},
            ),

            menuCard(
              context,
              "Settings",
              Icons.settings,
              Colors.grey,
                  () {},
            ),
          ],
        ),
      ),
    );
  }
}