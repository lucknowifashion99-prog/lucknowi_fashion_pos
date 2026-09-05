import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';

import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/staff_provider.dart';

import '../../repositories/sale_repository.dart';

import 'bill_preview.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _searchText = '';
  Product? _searchedProduct;
  ProductVariant? _searchedVariant;

  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // PRODUCT SEARCH
  // =====================================================

  List<Product> _getFilteredProducts(
      List<Product> products,
      ) {
    final search = _searchText.trim().toLowerCase();

    if (search.isEmpty) {
      return products;
    }

    return products.where((product) {
      return product.name
          .toLowerCase()
          .contains(search);
    }).toList();
  }

  // =====================================================
// SKU / BARCODE SEARCH
// =====================================================

  Future<void> _searchSkuOrBarcode(
      String value,
      ) async {
    final query = value.trim();

    final requestId = ++_searchRequestId;

    if (query.isEmpty) {
      if (!mounted) return;

      setState(() {
        _searchedProduct = null;
        _searchedVariant = null;
      });

      return;
    }

    final productProvider =
    context.read<ProductProvider>();

    final variant =
    await productProvider
        .searchVariantBySkuOrBarcode(
      query,
    );

    if (!mounted ||
        requestId != _searchRequestId) {
      return;
    }

    if (variant == null ||
        variant.productId <= 0) {
      setState(() {
        _searchedProduct = null;
        _searchedVariant = null;
      });

      return;
    }

    Product? product;

    for (final item
    in productProvider.products) {
      if (item.id == variant.productId) {
        product = item;
        break;
      }
    }

    if (product == null) {
      setState(() {
        _searchedProduct = null;
        _searchedVariant = null;
      });

      return;
    }

    setState(() {
      _searchedProduct = product;
      _searchedVariant = variant;
    });
  }

  // =====================================================
  // BILL NUMBER
  // =====================================================

  String _generateBillNumber() {
    final now = DateTime.now();

    final date =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    final time =
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return 'LF-$date-$time';
  }

  // =====================================================
  // VARIANT SELECT
  // =====================================================

  void _showVariants(Product product) {
    final provider = context.read<ProductProvider>();

    if (product.id == null) return;

    provider.loadVariants(product.id!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Consumer<ProductProvider>(
          builder: (
              context,
              productProvider,
              child,
              ) {
            final variants = productProvider.variants;

            return SizedBox(
              height:
              MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: variants.isEmpty
                        ? const Center(
                      child: Text(
                        'No variants available',
                      ),
                    )
                        : ListView.builder(
                      padding:
                      const EdgeInsets.all(12),
                      itemCount: variants.length,
                      itemBuilder:
                          (context, index) {
                        return _variantCard(
                          product,
                          variants[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // VARIANT CARD
  // =====================================================

  Widget _variantCard(
      Product product,
      ProductVariant variant,
      ) {
    final cart = context.watch<CartProvider>();

    final isOutOfStock = variant.stock <= 0;

    final existing = variant.id == null
        ? null
        : cart.getItem(variant.id!);

    return Card(
      margin:
      const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: isOutOfStock
              ? Colors.red.shade100
              : Colors.indigo.shade100,
          child: Icon(
            Icons.checkroom,
            color: isOutOfStock
                ? Colors.red
                : Colors.indigo,
          ),
        ),
        title: Text(
          '${variant.color} / ${variant.size}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '₹${variant.sellingPrice.toStringAsFixed(2)}',
            ),
            Text(
              'Stock: ${variant.stock}',
            ),
            Text(
              'SKU: ${variant.sku}',
            ),
            if (existing != null)
              Text(
                'In Cart: ${existing.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: isOutOfStock
            ? const Text(
          'OUT OF STOCK',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        )
            : ElevatedButton(
          onPressed: () {
            context
                .read<CartProvider>()
                .addItem(
              product: product,
              variant: variant,
            );

            Navigator.pop(context);
          },
          child: const Text('ADD'),
        ),
      ),
    );
  }

  // =====================================================
  // DISCOUNT
  // =====================================================

  void _showDiscountDialog() {
    final cart = context.read<CartProvider>();

    final amountController =
    TextEditingController(
      text: cart.discount.toStringAsFixed(2),
    );

    final percentController =
    TextEditingController(
      text: cart.discountPercent.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.discount),
              SizedBox(width: 10),
              Text('Apply Discount'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Discount Amount',
                    prefixText: '₹ ',
                    prefixIcon:
                    Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final amount =
                        double.tryParse(
                          value.trim(),
                        ) ??
                            0;

                    cart.setDiscount(amount);

                    percentController.text =
                        cart.discountPercent
                            .toStringAsFixed(2);
                  },
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: percentController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Discount Percentage',
                    suffixText: '%',
                    prefixIcon:
                    Icon(Icons.percent),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final percent =
                        double.tryParse(
                          value.trim(),
                        ) ??
                            0;

                    cart.setDiscountPercent(
                      percent,
                    );

                    amountController.text =
                        cart.discount
                            .toStringAsFixed(2);
                  },
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(10),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Subtotal + GST',
                          ),
                          const Spacer(),
                          Text(
                            '₹${cart.discountBase.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Discount',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${cart.discount.toStringAsFixed(2)}',
                            style:
                            const TextStyle(
                              color: Colors.red,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${cart.grandTotal.toStringAsFixed(2)}',
                            style:
                            const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('DONE'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // CHECKOUT
  // =====================================================

  void _openCheckout() {
    final cart = context.read<CartProvider>();

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const _CheckoutDialog(),
    );
  }

  // =====================================================
  // CART SECTION
  // =====================================================

  Widget _cartSection(
      BuildContext context,
      CartProvider cart,
      ) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              4,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cart (${cart.totalQuantity})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (cart.items.isNotEmpty)
                  TextButton(
                    onPressed: cart.clearCart,
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
              child: Text(
                'Cart is empty',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              itemCount:
              cart.items.length,
              itemBuilder:
                  (context, index) {
                final item =
                cart.items[index];

                final variant =
                    item.variant;

                return Card(
                  margin:
                  const EdgeInsets.only(
                    bottom: 4,
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      item.product.name,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${variant.color} / '
                          '${variant.size} • '
                          '₹${item.sellingPrice.toStringAsFixed(2)}',
                    ),
                    leading:
                    CircleAvatar(
                      radius: 18,
                      child: Text(
                        '${item.quantity}',
                      ),
                    ),
                    trailing:
                    SizedBox(
                      width: 170,
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .end,
                        children: [
                          IconButton(
                            onPressed: () {
                              cart
                                  .decreaseQuantity(
                                variant.id!,
                              );
                            },
                            icon:
                            const Icon(
                              Icons
                                  .remove_circle_outline,
                            ),
                          ),
                          Text(
                            '${item.quantity}',
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              cart
                                  .increaseQuantity(
                                variant.id!,
                              );
                            },
                            icon:
                            const Icon(
                              Icons
                                  .add_circle_outline,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              cart.removeItem(
                                variant.id!,
                              );
                            },
                            icon:
                            const Icon(
                              Icons
                                  .delete_outline,
                              color:
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SUMMARY
  // =====================================================

  Widget _summary(
      BuildContext context,
      CartProvider cart,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, -2),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow(
            'Subtotal',
            cart.subtotal,
          ),
          const SizedBox(height: 5),
          _summaryRow(
            'GST',
            cart.gst,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.discount,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Discount',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showDiscountDialog,
                icon: const Icon(
                  Icons.edit,
                  size: 17,
                ),
                label: Text(
                  cart.discount > 0
                      ? '₹${cart.discount.toStringAsFixed(2)} '
                      '(${cart.discountPercent.toStringAsFixed(2)}%)'
                      : 'Add Discount',
                ),
              ),
            ],
          ),
          const Divider(),
          _summaryRow(
            'Grand Total',
            cart.grandTotal,
            bold: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child:
            ElevatedButton.icon(
              onPressed:
              cart.items.isEmpty
                  ? null
                  : _openCheckout,
              icon: const Icon(
                Icons.point_of_sale,
              ),
              label: const Text(
                'CHECKOUT',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
      String title,
      double amount, {
        bool bold = false,
      }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: bold ? 18 : 14,
          ),
        ),
        const Spacer(),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: bold ? 20 : 14,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final productProvider =
    context.watch<ProductProvider>();

    final cart =
    context.watch<CartProvider>();

    final products =
    _getFilteredProducts(
      productProvider.products,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.all(16),
            child: TextField(
              controller:
              _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
                _searchSkuOrBarcode(value);
              },
              decoration:
              InputDecoration(
                hintText: 'Search Product',
                prefixIcon:
                const Icon(Icons.search),
                suffixIcon:
                _searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController
                        .clear();

                    setState(() {
                      _searchText = '';
                      _searchedProduct = null;
                      _searchedVariant = null;
                    });
                  },
                  icon:
                  const Icon(
                    Icons.clear,
                  ),
                )
                    : null,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchedVariant != null &&
                _searchedProduct != null
                ? ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.qr_code_2),
                    ),
                    title: Text(
                      _searchedProduct!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${_searchedVariant!.color} / '
                          '${_searchedVariant!.size}\n'
                          'SKU: ${_searchedVariant!.sku}\n'
                          'Barcode: ${_searchedVariant!.barcode}\n'
                          'Stock: ${_searchedVariant!.stock}',
                    ),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      onPressed:
                      _searchedVariant!.stock <= 0
                          ? null
                          : () {
                        context
                            .read<CartProvider>()
                            .addItem(
                          product:
                          _searchedProduct!,
                          variant:
                          _searchedVariant!,
                        );

                        _searchController.clear();

                        setState(() {
                          _searchText = '';
                          _searchedProduct = null;
                          _searchedVariant = null;
                        });
                      },
                      child: const Text('ADD'),
                    ),
                  ),
                ),
              ],
            )
                : products.isEmpty
                ? const Center(
              child: Text(
                'No Products Found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 12,
              ),
              itemCount:
              products.length,
              itemBuilder:
                  (context, index) {
                final product =
                products[index];

                return Card(
                  margin:
                  const EdgeInsets
                      .only(
                    bottom: 8,
                  ),
                  child: ListTile(
                    leading:
                    const CircleAvatar(
                      child: Icon(
                        Icons
                            .inventory_2,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                    subtitle: Text(
                      product.department ??
                          'Product',
                    ),
                    trailing:
                    ElevatedButton(
                      onPressed: () {
                        _showVariants(
                          product,
                        );
                      },
                      child:
                      const Text(
                        'SELECT',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _cartSection(
            context,
            cart,
          ),
          _summary(
            context,
            cart,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// CHECKOUT DIALOG
// =====================================================

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog();

  @override
  State<_CheckoutDialog> createState() =>
      _CheckoutDialogState();
}

class _CheckoutDialogState
    extends State<_CheckoutDialog> {
  int? _selectedCustomerId;

  Customer? _selectedCustomer;

  String _paymentMethod = 'Cash';

  bool _saving = false;

  bool _newCustomer = false;

  String _customerSearch = '';

  final TextEditingController
  _customerSearchController =
  TextEditingController();

  final TextEditingController
  _nameController =
  TextEditingController();

  final TextEditingController
  _phoneController =
  TextEditingController();

  final TextEditingController
  _emailController =
  TextEditingController();

  final TextEditingController
  _addressController =
  TextEditingController();

  @override
  void dispose() {
    _customerSearchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();

    super.dispose();
  }

  // =====================================================
  // BILL NUMBER
  // =====================================================

  String _generateBillNumber() {
    final now = DateTime.now();

    final date =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    final time =
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return 'LF-$date-$time';
  }

  // =====================================================
  // FILTER CUSTOMERS
  // =====================================================

  List<Customer> _getFilteredCustomers(
      List<Customer> customers,
      ) {
    final search =
    _customerSearch.trim().toLowerCase();

    if (search.isEmpty) {
      return customers;
    }

    return customers.where((customer) {
      final name =
      customer.name.toLowerCase();

      final phone =
      customer.phone.toLowerCase();

      return name.contains(search) ||
          phone.contains(search);
    }).toList();
  }

  // =====================================================
  // SELECT CUSTOMER
  // =====================================================

  void _selectCustomer(
      Customer customer,
      ) {
    setState(() {
      _selectedCustomer = customer;
      _selectedCustomerId = customer.id;

      _customerSearchController.text =
          customer.name;

      _customerSearch =
          customer.name;
    });
  }

  // =====================================================
  // CLEAR CUSTOMER
  // =====================================================

  void _clearSelectedCustomer() {
    setState(() {
      _selectedCustomer = null;
      _selectedCustomerId = null;
      _customerSearch = '';

      _customerSearchController.clear();
    });
  }

  // =====================================================
  // CONFIRM SALE
  // =====================================================

  Future<void> _confirmSale() async {
    if (_saving) return;

    final cart =
    context.read<CartProvider>();

    if (cart.items.isEmpty) {
      return;
    }

    // =====================================================
    // LOGGED-IN STAFF
    // =====================================================

    final staffProvider =
    context.read<StaffProvider>();

    final staffId =
        staffProvider.loggedInStaff?.id;

    // =====================================================
    // NEW CUSTOMER VALIDATION
    // =====================================================

    if (_newCustomer) {
      if (_nameController.text
          .trim()
          .isEmpty) {
        _showError(
          'Please enter customer name.',
        );
        return;
      }

      if (_phoneController.text
          .trim()
          .isEmpty) {
        _showError(
          'Please enter customer phone.',
        );
        return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      int? customerId =
          _selectedCustomerId;

      // =================================================
      // CREATE NEW CUSTOMER
      // =================================================

      if (_newCustomer) {
        final customer = Customer(
          name:
          _nameController.text.trim(),
          phone:
          _phoneController.text.trim(),
          email:
          _emailController.text
              .trim()
              .isEmpty
              ? null
              : _emailController.text
              .trim(),
          address:
          _addressController.text
              .trim()
              .isEmpty
              ? null
              : _addressController.text
              .trim(),
          createdAt:
          DateTime.now()
              .toIso8601String(),
        );

        customerId =
        await context
            .read<CustomerProvider>()
            .addCustomer(
          customer,
        );
      }

      // =================================================
      // SALE
      // =================================================

      final staffProvider =
      context.read<StaffProvider>();

      final loggedInStaff =
          staffProvider.loggedInStaff;

      final staffId =
          loggedInStaff?.id;

      final sale = Sale(
        billNumber:
        _generateBillNumber(),

        customerId:
        customerId,

        staffId:
        staffId,

        subtotal:
        cart.subtotal,

        discount:
        cart.discount,

        gst:
        cart.gst,

        grandTotal:
        cart.grandTotal,

        paymentMethod:
        _paymentMethod,

        paymentStatus:
        'Paid',

        createdAt:
        DateTime.now()
            .toIso8601String(),
      );

      // =================================================
      // SALE ITEMS
      // =================================================

      final saleItems =
      cart.items.map((item) {
        return SaleItem(
          saleId: 0,

          variantId:
          item.variant.id!,

          productName:
          item.product.name,

          color:
          item.variant.color,

          size:
          item.variant.size,

          sku:
          item.variant.sku,

          barcode:
          item.variant.barcode,

          quantity:
          item.quantity,

          purchasePrice:
          item.purchasePrice,

          sellingPrice:
          item.sellingPrice,

          gst:
          item.gstAmount,

          discount: 0,

          total:
          item.total,
        );
      }).toList();

      // =================================================
      // SAVE SALE
      // =================================================

      final saleId =
      await SaleRepository()
          .createSale(
        sale,
        saleItems,
      );

      if (!mounted) return;

      // =================================================
      // PREPARE CUSTOMER
      // =================================================

      Customer? billCustomer;

      if (customerId != null) {
        try {
          billCustomer =
              context
                  .read<CustomerProvider>()
                  .customers
                  .firstWhere(
                    (customer) =>
                customer.id ==
                    customerId,
              );
        } catch (_) {
          billCustomer = null;
        }
      }

      // =================================================
      // CLEAR CART
      // =================================================

      cart.clearCart();

      // =================================================
      // CLOSE CHECKOUT
      // =================================================

      Navigator.pop(context);

      if (!mounted) return;

      // =================================================
      // OPEN BILL PREVIEW
      // =================================================

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BillPreview(
            sale: sale,
            items: saleItems,
            customer:
            billCustomer,
          ),
        ),
      );

      debugPrint(
        'Sale ID: $saleId',
      );

      debugPrint(
        'Staff ID: $staffId',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Sale failed: $e',
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =====================================================
  // ERROR
  // =====================================================

  void _showError(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        Colors.red,
      ),
    );
  }

  // =====================================================
  // PAYMENT CHIP
  // =====================================================

  Widget _paymentChip(
      String title,
      IconData icon,
      ) {
    final selected =
        _paymentMethod == title;

    return ChoiceChip(
      selected: selected,
      avatar: Icon(
        icon,
        size: 18,
      ),
      label: Text(title),
      onSelected: (_) {
        setState(() {
          _paymentMethod = title;
        });
      },
    );
  }

  // =====================================================
  // SUMMARY ROW
  // =====================================================

  Widget _checkoutRow(
      String title,
      double amount, {
        bool bold = false,
      }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize:
              bold ? 18 : 14,
            ),
          ),
          const Spacer(),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize:
              bold ? 20 : 14,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CUSTOMER SEARCH UI
  // =====================================================

  Widget _customerSearchWidget(
      List<Customer> customers,
      ) {
    final filtered =
    _getFilteredCustomers(
      customers,
    );

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        TextField(
          controller:
          _customerSearchController,
          onChanged: (value) {
            setState(() {
              _customerSearch = value;

              if (_selectedCustomer !=
                  null) {
                _selectedCustomer = null;
                _selectedCustomerId = null;
              }
            });
          },
          decoration: InputDecoration(
            labelText:
            'Search Customer',
            hintText:
            'Name or phone number',
            prefixIcon:
            const Icon(
              Icons.search,
            ),
            suffixIcon:
            _customerSearch
                .isNotEmpty
                ? IconButton(
              onPressed:
              _clearSelectedCustomer,
              icon:
              const Icon(
                Icons.clear,
              ),
            )
                : null,
            border:
            const OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 8),

        // Selected customer
        if (_selectedCustomer != null)
          Card(
            child: ListTile(
              leading:
              const CircleAvatar(
                child: Icon(
                  Icons.person,
                ),
              ),
              title: Text(
                _selectedCustomer!
                    .name,
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _selectedCustomer!
                    .phone,
              ),
              trailing:
              IconButton(
                onPressed:
                _clearSelectedCustomer,
                icon:
                const Icon(
                  Icons.close,
                ),
              ),
            ),
          ),

        // Search results
        if (_selectedCustomer ==
            null &&
            _customerSearch
                .trim()
                .isNotEmpty)
          Container(
            constraints:
            const BoxConstraints(
              maxHeight: 220,
            ),
            decoration:
            BoxDecoration(
              border:
              Border.all(
                color:
                Colors.grey.shade300,
              ),
              borderRadius:
              BorderRadius.circular(
                8,
              ),
            ),
            child:
            filtered.isEmpty
                ? const Padding(
              padding:
              EdgeInsets.all(
                16,
              ),
              child: Text(
                'No customer found.',
              ),
            )
                : ListView.builder(
              shrinkWrap:
              true,
              itemCount:
              filtered.length,
              itemBuilder:
                  (
                  context,
                  index,
                  ) {
                final customer =
                filtered[
                index];

                return ListTile(
                  leading:
                  const Icon(
                    Icons
                        .person,
                  ),
                  title:
                  Text(
                    customer
                        .name,
                  ),
                  subtitle:
                  Text(
                    customer
                        .phone,
                  ),
                  onTap: () {
                    _selectCustomer(
                      customer,
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // =====================================================
  // BUILD CHECKOUT
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final cart =
    context.watch<CartProvider>();

    final customerProvider =
    context.watch<
        CustomerProvider>();

    final customers =
        customerProvider.customers;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.receipt_long,
          ),
          SizedBox(width: 10),
          Text('Checkout'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child:
        SingleChildScrollView(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // =================================================
              // CUSTOMER HEADER
              // =================================================

              Row(
                children: [
                  const Text(
                    'Customer',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _newCustomer =
                        !_newCustomer;

                        _selectedCustomer =
                        null;

                        _selectedCustomerId =
                        null;

                        _customerSearch =
                        '';

                        _customerSearchController
                            .clear();
                      });
                    },
                    icon: Icon(
                      _newCustomer
                          ? Icons.list
                          : Icons.person_add,
                    ),
                    label: Text(
                      _newCustomer
                          ? 'Existing Customer'
                          : 'New Customer',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // =================================================
              // NEW CUSTOMER
              // =================================================

              if (_newCustomer) ...[
                TextField(
                  controller:
                  _nameController,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'Customer Name *',
                    prefixIcon:
                    Icon(
                      Icons.person,
                    ),
                    border:
                    OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller:
                  _phoneController,
                  keyboardType:
                  TextInputType.phone,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'Phone Number *',
                    prefixIcon:
                    Icon(
                      Icons.phone,
                    ),
                    border:
                    OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller:
                  _emailController,
                  keyboardType:
                  TextInputType
                      .emailAddress,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'Email (Optional)',
                    prefixIcon:
                    Icon(
                      Icons.email,
                    ),
                    border:
                    OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller:
                  _addressController,
                  maxLines: 2,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'Address (Optional)',
                    prefixIcon:
                    Icon(
                      Icons.location_on,
                    ),
                    border:
                    OutlineInputBorder(),
                  ),
                ),
              ]

              // =================================================
              // EXISTING CUSTOMER
              // =================================================
              else ...[
                _customerSearchWidget(
                  customers,
                ),

                const SizedBox(height: 8),

                if (_selectedCustomer ==
                    null)
                  ListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    leading:
                    const Icon(
                      Icons.person_outline,
                    ),
                    title: const Text(
                      'Walk-in Customer',
                    ),
                    subtitle:
                    const Text(
                      'No customer selected',
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCustomer =
                        null;
                        _selectedCustomerId =
                        null;
                        _customerSearch =
                        '';
                        _customerSearchController
                            .clear();
                      });
                    },
                  ),
              ],

              const SizedBox(height: 20),

              // =================================================
              // PAYMENT
              // =================================================

              const Text(
                'Payment Method',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: [
                  _paymentChip(
                    'Cash',
                    Icons.money,
                  ),
                  _paymentChip(
                    'UPI',
                    Icons.qr_code,
                  ),
                  _paymentChip(
                    'Card',
                    Icons.credit_card,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Divider(),

              _checkoutRow(
                'Subtotal',
                cart.subtotal,
              ),

              _checkoutRow(
                'GST',
                cart.gst,
              ),

              _checkoutRow(
                'Discount',
                cart.discount,
              ),

              const Divider(),

              _checkoutRow(
                'Grand Total',
                cart.grandTotal,
                bold: true,
              ),

              const SizedBox(height: 10),

              Text(
                'Payment: $_paymentMethod',
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.w600,
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // TERMS
              // =================================================

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(
                  12,
                ),
                decoration:
                BoxDecoration(
                  border:
                  Border.all(
                    color:
                    Colors.grey.shade300,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    8,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1. Return: Return accepted within 24 hours of purchase.',
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2. Exchange: Exchange accepted within 7 days of purchase.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // =====================================================
      // ACTIONS
      // =====================================================

      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
            Navigator.pop(
              context,
            );
          },
          child:
          const Text('Cancel'),
        ),

        ElevatedButton.icon(
          onPressed:
          _saving
              ? null
              : _confirmSale,
          icon: _saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Icon(
            Icons.check,
          ),
          label: Text(
            _saving
                ? 'Saving...'
                : 'CONFIRM SALE',
          ),
        ),
      ],
    );
  }
}