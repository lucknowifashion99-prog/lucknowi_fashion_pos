import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/admin_guard.dart';

import '../../providers/staff_provider.dart';

import '../reports/report_screen.dart';
import '../purchase/purchase_screen.dart';
import '../master/product/product_screen.dart';
import '../master/master_screen.dart';
import '../sales/billing_screen.dart';
import '../sales/sales_history_screen.dart';
import '../staff/staff_screen.dart';

import '../../screens/printer_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // =========================================================
  // MENU CARD
  // =========================================================

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
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  void _logout(BuildContext context) {
    context.read<StaffProvider>().logout();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(
      builder: (
          context,
          staffProvider,
          child,
          ) {
        final staff = staffProvider.loggedInStaff;
        final isAdmin = staffProvider.isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Lucknowi Fashion POS',
            ),
            centerTitle: true,
            actions: [
              // =================================================
              // STAFF PROFILE
              // =================================================

              PopupMenuButton<String>(
                tooltip: 'Account',
                icon: const Icon(
                  Icons.account_circle,
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String>(
                      enabled: false,
                      value: 'profile',
                      child: SizedBox(
                        width: 210,
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff?.name ?? 'Staff',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              staff?.username ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              staff?.role ?? 'Staff',
                              style: TextStyle(
                                color: isAdmin
                                    ? Colors.deepPurple
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.logout,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),

          // =====================================================
          // BODY
          // =====================================================

          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // =================================================
                // WELCOME CARD
                // =================================================

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isAdmin
                              ? Colors.deepPurple.withValues(
                            alpha: 0.12,
                          )
                              : Colors.blue.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: isAdmin
                                ? Colors.deepPurple
                                : Colors.blue,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${staff?.name ?? 'Staff'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${staff?.role ?? 'Staff'} • @${staff?.username ?? ''}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =================================================
                // MENU
                // =================================================

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [
                      // =============================================
                      // BILLING
                      // ADMIN + STAFF
                      // =============================================

                      menuCard(
                        context,
                        'Billing',
                        Icons.point_of_sale,
                        Colors.green,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const BillingScreen(),
                            ),
                          );
                        },
                      ),

                      // =============================================
                      // SALES HISTORY
                      // ADMIN + STAFF
                      // =============================================

                      menuCard(
                        context,
                        'Sales History',
                        Icons.receipt_long,
                        Colors.indigo,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const SalesHistoryScreen(),
                            ),
                          );
                        },
                      ),

                      // =============================================
                      // PRODUCTS
                      // ADMIN + STAFF
                      // =============================================

                      menuCard(
                        context,
                        'Products',
                        Icons.inventory_2,
                        Colors.orange,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const ProductScreen(),
                            ),
                          );
                        },
                      ),

                      // =============================================
                      // MASTER DATA
                      // ADMIN ONLY
                      // =============================================

                      if (isAdmin)
                        menuCard(
                          context,
                          'Master Data',
                          Icons.dashboard_customize,
                          Colors.blue,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const AdminGuard(
                                  child: MasterScreen(),
                                ),
                              ),
                            );
                          },
                        ),

                      // =============================================
                      // PURCHASE
                      // ADMIN ONLY
                      // =============================================

                      if (isAdmin)
                        menuCard(
                          context,
                          'Purchase',
                          Icons.shopping_cart,
                          Colors.purple,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const AdminGuard(
                                  child: PurchaseScreen(),
                                ),
                              ),
                            );
                          },
                        ),

                      // =============================================
                      // REPORTS
                      // ADMIN ONLY
                      // =============================================

                      if (isAdmin)
                        menuCard(
                          context,
                          'Reports',
                          Icons.bar_chart,
                          Colors.red,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const AdminGuard(
                                  child: ReportScreen(),
                                ),
                              ),
                            );
                          },
                        ),

                      // =============================================
                      // PRINTER
                      // ADMIN + STAFF
                      // =============================================

                      menuCard(
                        context,
                        'Printer',
                        Icons.print,
                        Colors.teal,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const PrinterScreen(),
                            ),
                          );
                        },
                      ),

                      // =============================================
                      // STAFF MANAGEMENT
                      // ADMIN ONLY
                      // =============================================

                      if (isAdmin)
                        menuCard(
                          context,
                          'Staff',
                          Icons.people,
                          Colors.deepPurple,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const AdminGuard(
                                  child: StaffScreen(),
                                ),
                              ),
                            );
                          },
                        ),

                      // =============================================
                      // SETTINGS
                      // ADMIN ONLY
                      // =============================================

                      if (isAdmin)
                        menuCard(
                          context,
                          'Settings',
                          Icons.settings,
                          Colors.grey,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const AdminGuard(
                                  child: SettingsScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // LOGOUT CONFIRMATION
  // =========================================================

  void _showLogoutDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );

                _logout(context);
              },
              icon: const Icon(
                Icons.logout,
              ),
              label: const Text(
                'Logout',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================
// SETTINGS SCREEN
// =============================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =================================================
          // SHOP SETTINGS
          // =================================================

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.store,
                ),
              ),
              title: const Text(
                'Shop Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Shop name, mobile number and address',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                _showComingSoon(
                  context,
                  'Shop Settings',
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // =================================================
          // PRINTER SETTINGS
          // =================================================

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.print,
                ),
              ),
              title: const Text(
                'Printer Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Bluetooth thermal printer',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const PrinterScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // =================================================
          // BILL SETTINGS
          // =================================================

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.receipt_long,
                ),
              ),
              title: const Text(
                'Bill Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Receipt and billing options',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                _showComingSoon(
                  context,
                  'Bill Settings',
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // =================================================
          // DATABASE
          // =================================================

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.storage,
                ),
              ),
              title: const Text(
                'Database',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Local database information',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                _showComingSoon(
                  context,
                  'Database Settings',
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // =================================================
          // ABOUT
          // =================================================

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.info_outline,
                ),
              ),
              title: const Text(
                'About',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Lucknowi Fashion POS',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName:
                  'Lucknowi Fashion POS',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.store,
                    size: 40,
                  ),
                  children: const [
                    Text(
                      'Professional billing and inventory management system for Lucknowi Fashion.',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // COMING SOON
  // =========================================================

  static void _showComingSoon(
      BuildContext context,
      String title,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$title - jaldi add karenge.',
          ),
        ),
      );
  }
}