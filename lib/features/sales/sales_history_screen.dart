import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';

import '../../repositories/customer_repository.dart';
import '../../repositories/sale_repository.dart';

import 'bill_preview.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({
    super.key,
  });

  @override
  State<SalesHistoryScreen> createState() =>
      _SalesHistoryScreenState();
}

class _SalesHistoryScreenState
    extends State<SalesHistoryScreen> {
  final SaleRepository _repository =
  SaleRepository();

  final CustomerRepository _customerRepository =
  CustomerRepository();

  List<Sale> _sales = [];

  List<Sale> _filteredSales = [];

  bool _loading = true;

  String _searchText = '';

  final TextEditingController _searchController =
  TextEditingController();

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadSales();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD SALES
  // =========================================================

  Future<void> _loadSales() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final sales =
      await _repository.getAllSales();

      if (!mounted) return;

      setState(() {
        _sales = sales;
        _filteredSales = sales;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load sales: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void _searchSales(String value) {
    final search =
    value.trim().toLowerCase();

    setState(() {
      _searchText = value;

      if (search.isEmpty) {
        _filteredSales = _sales;
        return;
      }

      _filteredSales = _sales.where(
            (sale) {
          return sale.billNumber
              .toLowerCase()
              .contains(search) ||
              sale.paymentMethod
                  .toLowerCase()
                  .contains(search);
        },
      ).toList();
    });
  }

  // =========================================================
  // DATE FORMAT
  // =========================================================

  String _formatDate(String value) {
    final date =
    DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    final year =
    date.year.toString();

    final hour =
    date.hour.toString().padLeft(2, '0');

    final minute =
    date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }

  // =========================================================
  // OPEN BILL
  // =========================================================

  Future<void> _openBill(
      Sale sale,
      ) async {
    if (sale.id == null) {
      return;
    }

    try {
      // -------------------------------------------------------
      // GET SALE ITEMS
      // -------------------------------------------------------

      final List<SaleItem> items =
      await _repository.getSaleItems(
        sale.id!,
      );

      // -------------------------------------------------------
      // GET CUSTOMER
      // -------------------------------------------------------

      Customer? customer;

      if (sale.customerId != null) {
        customer =
        await _customerRepository.getById(
          sale.customerId!,
        );
      }

      if (!mounted) return;

      // -------------------------------------------------------
      // OPEN BILL PREVIEW
      // -------------------------------------------------------

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillPreview(
            sale: sale,
            items: items,
            customer: customer,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open bill: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // =========================================================
  // PAYMENT ICON
  // =========================================================

  IconData _paymentIcon(
      String paymentMethod,
      ) {
    switch (
    paymentMethod.toLowerCase()) {
      case 'upi':
        return Icons.qr_code;

      case 'card':
        return Icons.credit_card;

      case 'cash':
      default:
        return Icons.payments;
    }
  }

  // =========================================================
  // SALE CARD
  // =========================================================

  Widget _saleCard(Sale sale) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(12),
        onTap: () {
          _openBill(sale);
        },
        child: Padding(
          padding:
          const EdgeInsets.all(16),
          child: Column(
            children: [
              // =================================================
              // TOP ROW
              // =================================================

              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                    Colors.indigo.shade100,
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.indigo,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.billNumber,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _formatDate(
                            sale.createdAt,
                          ),
                          style: TextStyle(
                            color:
                            Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${sale.grandTotal.toStringAsFixed(2)}',
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.green.shade50,
                          borderRadius:
                          BorderRadius
                              .circular(20),
                        ),
                        child: Text(
                          sale.paymentStatus,
                          style:
                          TextStyle(
                            color:
                            Colors.green.shade700,
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Divider(height: 1),

              const SizedBox(height: 10),

              // =================================================
              // BOTTOM ROW
              // =================================================

              Row(
                children: [
                  Icon(
                    _paymentIcon(
                      sale.paymentMethod,
                    ),
                    size: 18,
                    color: Colors.indigo,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    sale.paymentMethod,
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    'Subtotal ₹${sale.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color:
                      Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 15),

          const Text(
            'No Sales Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _searchText.isEmpty
                ? 'Your completed sales will appear here.'
                : 'No bill matches your search.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Sales History'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading ? null : _loadSales,
            icon:
            const Icon(Icons.refresh),
          ),
        ],
      ),

      // =======================================================
      // BODY
      // =======================================================

      body: Column(
        children: [
          // =====================================================
          // SEARCH
          // =====================================================

          Padding(
            padding:
            const EdgeInsets.all(16),
            child: TextField(
              controller:
              _searchController,
              onChanged:
              _searchSales,
              decoration:
              InputDecoration(
                hintText:
                'Search Bill Number',
                prefixIcon:
                const Icon(
                  Icons.search,
                ),
                suffixIcon:
                _searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController
                        .clear();

                    _searchSales('');
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

          // =====================================================
          // COUNT + TOTAL
          // =====================================================

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              children: [
                Text(
                  'Sales: ${_filteredSales.length}',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const Spacer(),

                if (_filteredSales.isNotEmpty)
                  Text(
                    'Total: ₹${_filteredSales.fold<double>(
                      0,
                          (sum, sale) =>
                      sum +
                          sale.grandTotal,
                    ).toStringAsFixed(2)}',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =====================================================
          // SALES LIST
          // =====================================================

          Expanded(
            child: _loading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : _filteredSales.isEmpty
                ? _emptyState()
                : RefreshIndicator(
              onRefresh:
              _loadSales,
              child:
              ListView.builder(
                padding:
                const EdgeInsets
                    .fromLTRB(
                  16,
                  4,
                  16,
                  20,
                ),
                itemCount:
                _filteredSales
                    .length,
                itemBuilder:
                    (context, index) {
                  final sale =
                  _filteredSales[
                  index];

                  return _saleCard(
                    sale,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}