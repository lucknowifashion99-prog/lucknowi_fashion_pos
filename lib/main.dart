import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';

import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/brand_provider.dart';
import 'providers/color_provider.dart';
import 'providers/size_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/report_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/staff_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================================================
  // WINDOWS / LINUX DATABASE INITIALIZATION
  // =========================================================

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // =========================================================
  // RUN APP
  // =========================================================

  runApp(
    MultiProvider(
      providers: [
        // =====================================================
        // PRODUCT
        // =====================================================

        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
        ),

        // =====================================================
        // CATEGORY
        // =====================================================

        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(),
        ),

        // =====================================================
        // BRAND
        // =====================================================

        ChangeNotifierProvider<BrandProvider>(
          create: (_) => BrandProvider(),
        ),

        // =====================================================
        // COLOR
        // =====================================================

        ChangeNotifierProvider<ColorProvider>(
          create: (_) => ColorProvider(),
        ),

        // =====================================================
        // SIZE
        // =====================================================

        ChangeNotifierProvider<SizeProvider>(
          create: (_) => SizeProvider(),
        ),

        // =====================================================
        // SUPPLIER
        // =====================================================

        ChangeNotifierProvider<SupplierProvider>(
          create: (_) => SupplierProvider(),
        ),

        // =====================================================
        // CUSTOMER
        // =====================================================

        ChangeNotifierProvider<CustomerProvider>(
          create: (_) => CustomerProvider(),
        ),

        // =====================================================
        // PURCHASE
        // =====================================================

        ChangeNotifierProvider<PurchaseProvider>(
          create: (_) => PurchaseProvider(),
        ),

        // =====================================================
        // REPORT
        // =====================================================

        ChangeNotifierProvider<ReportProvider>(
          create: (_) => ReportProvider(),
        ),

        // =====================================================
        // CART
        // =====================================================

        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),

        // =====================================================
        // STAFF / LOGIN
        // =====================================================

        ChangeNotifierProvider<StaffProvider>(
          create: (_) => StaffProvider(),
        ),
      ],

      // =======================================================
      // MAIN APP
      // =======================================================

      child: const LucknowiFashionApp(),
    ),
  );
}