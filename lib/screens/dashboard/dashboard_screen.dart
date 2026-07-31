import 'package:flutter/material.dart';
import '../../widgets/header_card.dart';
import '../products/add_product_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Widget buildCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 34),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget menuButton(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductScreen(),
            ),
          );
        },
        child: SizedBox(
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(.15),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
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
        title: const Text("Lucknowi Fashion POS"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const HeaderCard(),

            const SizedBox(height: 20),

            Row(
              children: [
                buildCard(
                  "Today's Sales",
                  "₹0",
                  Icons.currency_rupee,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                buildCard(
                  "Bills",
                  "0",
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                buildCard(
                  "Products",
                  "0",
                  Icons.inventory_2,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                buildCard(
                  "Customers",
                  "0",
                  Icons.people,
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: [

                  menuButton(
                    context,
                    "Billing",
                    Icons.point_of_sale,
                    Colors.green,
                  ),

                  menuButton(
                    context,
                    "Products",
                    Icons.inventory,
                    Colors.orange,
                  ),

                  menuButton(
                    context,
                    "Customers",
                    Icons.people,
                    Colors.blue,
                  ),

                  menuButton(
                    context,
                    "Reports",
                    Icons.bar_chart,
                    Colors.red,
                  ),

                  menuButton(
                    context,
                    "Expenses",
                    Icons.account_balance_wallet,
                    Colors.purple,
                  ),

                  menuButton(
                    context,
                    "Settings",
                    Icons.settings,
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}