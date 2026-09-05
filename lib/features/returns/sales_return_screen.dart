import 'package:flutter/material.dart';

import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../repositories/sale_repository.dart';

class SalesReturnScreen extends StatefulWidget {
  final Sale sale;

  const SalesReturnScreen({
    super.key,
    required this.sale,
  });

  @override
  State<SalesReturnScreen> createState() =>
      _SalesReturnScreenState();
}

class _SalesReturnScreenState
    extends State<SalesReturnScreen> {
  final SaleRepository _repository =
  SaleRepository();

  List<SaleItem> _items = [];

  final Map<int, int> _returnableQuantities = {};
  final Map<int, int> _returnQuantities = {};

  bool _loading = true;
  bool _processing = false;

  String _refundMethod = 'Cash';

  final TextEditingController _reasonController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD ITEMS
  // =========================================================

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
    });

    try {
      if (widget.sale.id == null) {
        throw Exception('Invalid sale ID.');
      }

      final items = await _repository.getSaleItems(
        widget.sale.id!,
      );

      final Map<int, int> returnable = {};
      final Map<int, int> selected = {};

      for (int i = 0; i < items.length; i++) {
        final item = items[i];

        if (item.id == null) {
          continue;
        }

        final key = _itemKey(item, i);

        final alreadyReturned =
        await _repository.getReturnedQuantity(
          item.id!,
        );

        final remaining =
            item.quantity - alreadyReturned;

        returnable[key] =
        remaining < 0 ? 0 : remaining;

        selected[key] = 0;
      }

      if (!mounted) return;

      setState(() {
        _items = items;

        _returnableQuantities
          ..clear()
          ..addAll(returnable);

        _returnQuantities
          ..clear()
          ..addAll(selected);

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load bill items: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // ITEM KEY
  // =========================================================

  int _itemKey(
      SaleItem item,
      int index,
      ) {
    return item.id ?? index;
  }

  // =========================================================
  // RETURNABLE QUANTITY
  // =========================================================

  int _getReturnableQuantity(
      SaleItem item,
      int index,
      ) {
    return _returnableQuantities[
    _itemKey(item, index)] ??
        0;
  }

  // =========================================================
  // SELECTED RETURN QUANTITY
  // =========================================================

  int _getReturnQuantity(
      SaleItem item,
      int index,
      ) {
    return _returnQuantities[
    _itemKey(item, index)] ??
        0;
  }

  void _setReturnQuantity(
      SaleItem item,
      int index,
      int quantity,
      ) {
    final maxQuantity =
    _getReturnableQuantity(
      item,
      index,
    );

    final int safeQuantity =
    quantity.clamp(0, maxQuantity).toInt();

    setState(() {
      _returnQuantities[
      _itemKey(item, index)] =
          safeQuantity;
    });
  }

  // =========================================================
  // CALCULATE ITEM REFUND
  // =========================================================
  //
  // Formula:
  //
  // Line Gross = Selling + GST
  //
  // Discount Share =
  // Bill Discount ×
  // (Line Gross / Total Sale Gross)
  //
  // Net Line =
  // Line Gross - Discount Share
  //
  // Per Unit Refund =
  // Net Line / Sold Quantity
  //
  // Return Refund =
  // Per Unit Refund × Return Quantity
  //
  // =========================================================

  double _calculateItemRefund(
      SaleItem item,
      int quantity,
      ) {
    if (quantity <= 0 ||
        item.quantity <= 0) {
      return 0.0;
    }

    final double totalSaleGross =
        widget.sale.subtotal +
            widget.sale.gst;

    if (totalSaleGross <= 0) {
      return 0.0;
    }

    // Original line total.
    // This already contains selling price + GST.
    final double lineGross =
        item.total;

    // Proportional share of bill discount.
    double discountShare = 0.0;

    if (widget.sale.discount > 0 &&
        lineGross > 0) {
      discountShare =
          widget.sale.discount *
              (lineGross / totalSaleGross);
    }

    // Net amount of complete line.
    double lineNet =
        lineGross - discountShare;

    if (lineNet < 0) {
      lineNet = 0.0;
    }

    // One unit's actual paid amount.
    final double perUnitRefund =
        lineNet / item.quantity;

    // Refund for selected quantity.
    final double refund =
        perUnitRefund * quantity;

    return _roundMoney(refund);
  }

  // =========================================================
  // RETURN TOTAL
  // =========================================================

  double _returnTotal() {
    double total = 0.0;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      final int quantity =
      _getReturnQuantity(
        item,
        i,
      );

      total += _calculateItemRefund(
        item,
        quantity,
      );
    }

    return _roundMoney(total);
  }

  // =========================================================
  // RETURN ITEM COUNT
  // =========================================================

  int _returnItemCount() {
    int count = 0;

    for (int i = 0; i < _items.length; i++) {
      count += _getReturnQuantity(
        _items[i],
        i,
      );
    }

    return count;
  }

  // =========================================================
  // HAS RETURN ITEMS
  // =========================================================

  bool get _hasReturnItems {
    return _returnItemCount() > 0;
  }

  // =========================================================
  // SELECT ALL
  // =========================================================

  void _selectAll() {
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];

        _returnQuantities[
        _itemKey(item, i)] =
            _getReturnableQuantity(
              item,
              i,
            );
      }
    });
  }

  // =========================================================
  // CLEAR ALL
  // =========================================================

  void _clearAll() {
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];

        _returnQuantities[
        _itemKey(item, i)] = 0;
      }
    });
  }

  // =========================================================
  // CONFIRM RETURN
  // =========================================================

  Future<void> _confirmReturn() async {
    if (!_hasReturnItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one item to return.',
          ),
        ),
      );

      return;
    }

    final double total = _returnTotal();
    final int itemCount = _returnItemCount();

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Return',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Bill: ${widget.sale.billNumber}',
              ),
              const SizedBox(height: 8),
              Text(
                'Items: $itemCount',
              ),
              const SizedBox(height: 8),
              Text(
                'Refund Amount: ₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Selected stock will be added back to inventory.',
              ),
            ],
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
              },
              icon: const Icon(
                Icons.check,
              ),
              label: const Text(
                'Confirm Return',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _processReturn();
  }

  // =========================================================
  // PROCESS RETURN
  // =========================================================

  Future<void> _processReturn() async {
    setState(() {
      _processing = true;
    });

    try {
      if (widget.sale.id == null) {
        throw Exception('Invalid sale ID.');
      }

      final Map<int, int> returnQuantities = {};

      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];

        if (item.id == null) {
          continue;
        }

        final quantity =
        _getReturnQuantity(
          item,
          i,
        );

        if (quantity > 0) {
          returnQuantities[item.id!] =
              quantity;
        }
      }

      if (returnQuantities.isEmpty) {
        throw Exception(
          'Please select at least one item to return.',
        );
      }

      // =======================================================
      // CREATE ACTUAL RETURN
      // =======================================================

      final returnId =
      await _repository.createSalesReturn(
        sale: widget.sale,
        items: _items,
        returnQuantities: returnQuantities,

        // Use selected refund method.
        refundMethod: _refundMethod,

        // Use entered reason.
        reason:
        _reasonController.text.trim().isEmpty
            ? 'Customer Return'
            : _reasonController.text.trim(),

        staffId: widget.sale.staffId,
      );

      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      // =======================================================
      // SUCCESS
      // =======================================================

      final double refundAmount =
      _returnTotal();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Text('Return Successful'),
              ],
            ),
            content: Text(
              'Return has been successfully processed.\n\n'
                  'Return ID: $returnId\n'
                  'Refund Amount: ₹${refundAmount.toStringAsFixed(2)}\n\n'
                  'Stock has been added back to inventory.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Return failed: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

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
  // ITEM CARD
  // =========================================================

  Widget _itemCard(
      SaleItem item,
      int index,
      ) {
    final int returnable =
    _getReturnableQuantity(
      item,
      index,
    );

    final int returnQuantity =
    _getReturnQuantity(
      item,
      index,
    );

    // IMPORTANT:
    // Refund now includes GST and proportional bill discount.
    final double itemTotal =
    _calculateItemRefund(
      item,
      returnQuantity,
    );

    final bool fullyReturned =
        returnable <= 0;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                  fullyReturned
                      ? Colors.grey.shade200
                      : Colors.orange.shade100,
                  child: Icon(
                    fullyReturned
                        ? Icons.done_all
                        : Icons.checkroom,
                    color: fullyReturned
                        ? Colors.grey
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildItemName(item),
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (_hasText(item.sku))
                        Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 3,
                          ),
                          child: Text(
                            'SKU: ${item.sku}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                              Colors.grey.shade600,
                            ),
                          ),
                        ),
                      if (_hasText(item.barcode))
                        Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 2,
                          ),
                          child: Text(
                            'Barcode: ${item.barcode}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                              Colors.grey.shade600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        'Sold Qty: ${item.quantity}  •  ₹${item.sellingPrice.toStringAsFixed(2)} each',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey.shade700,
                        ),
                      ),
                      if (fullyReturned)
                        Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 5,
                          ),
                          child: Text(
                            'Fully Returned',
                            style: TextStyle(
                              color:
                              Colors.green.shade700,
                              fontWeight:
                              FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 5,
                          ),
                          child: Text(
                            'Returnable: $returnable',
                            style: TextStyle(
                              color:
                              Colors.orange.shade800,
                              fontWeight:
                              FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'RETURN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Decrease',
                          onPressed:
                          returnQuantity <= 0 ||
                              fullyReturned
                              ? null
                              : () {
                            _setReturnQuantity(
                              item,
                              index,
                              returnQuantity -
                                  1,
                            );
                          },
                          icon: const Icon(
                            Icons
                                .remove_circle_outline,
                          ),
                        ),
                        Container(
                          width: 42,
                          alignment:
                          Alignment.center,
                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 7,
                          ),
                          decoration:
                          BoxDecoration(
                            border: Border.all(
                              color: Colors
                                  .grey.shade300,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: Text(
                            '$returnQuantity',
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Increase',
                          onPressed:
                          returnQuantity >=
                              returnable ||
                              fullyReturned
                              ? null
                              : () {
                            _setReturnQuantity(
                              item,
                              index,
                              returnQuantity +
                                  1,
                            );
                          },
                          icon: const Icon(
                            Icons
                                .add_circle_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (returnQuantity > 0) ...[
              const SizedBox(height: 10),
              const Divider(),
              Row(
                children: [
                  const Text(
                    'Return Amount',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${itemTotal.toStringAsFixed(2)}',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ITEM NAME
  // =========================================================

  String _buildItemName(
      SaleItem item,
      ) {
    final parts = <String>[
      item.productName,
    ];

    if (_hasText(item.color)) {
      parts.add(item.color!);
    }

    if (_hasText(item.size)) {
      parts.add(item.size!);
    }

    return parts.join(' • ');
  }

  // =========================================================
  // TEXT CHECK
  // =========================================================

  bool _hasText(String? value) {
    return value != null &&
        value.trim().isNotEmpty;
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _summaryCard() {
    final int itemCount =
    _returnItemCount();

    final double total =
    _returnTotal();

    return Card(
      elevation: 4,
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_return,
                  color: Colors.orange,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Return Summary',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Return Quantity',
                ),
                const Spacer(),
                Text(
                  '$itemCount',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Refund Amount',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style:
                  const TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _refundMethod,
              decoration:
              const InputDecoration(
                labelText: 'Refund Method',
                border:
                OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.payments),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Cash',
                  child: Text('Cash'),
                ),
                DropdownMenuItem(
                  value: 'UPI',
                  child: Text('UPI'),
                ),
                DropdownMenuItem(
                  value: 'Card',
                  child: Text('Card'),
                ),
                DropdownMenuItem(
                  value: 'Original Payment',
                  child:
                  Text('Original Payment'),
                ),
              ],
              onChanged: _processing
                  ? null
                  : (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _refundMethod =
                      value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
              _reasonController,
              enabled: !_processing,
              maxLines: 2,
              decoration:
              const InputDecoration(
                labelText:
                'Return Reason (Optional)',
                hintText:
                'Enter return reason',
                border:
                OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child:
              ElevatedButton.icon(
                onPressed:
                _processing ||
                    !_hasReturnItems
                    ? null
                    : _confirmReturn,
                icon: _processing
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons
                      .assignment_return,
                ),
                label: Text(
                  _processing
                      ? 'PROCESSING...'
                      : 'CONFIRM RETURN',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ROUND MONEY
  // =========================================================

  double _roundMoney(num value) {
    return ((value.toDouble() * 100).round() /
        100)
        .toDouble();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Return',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Select All',
            onPressed:
            _loading ||
                _items.isEmpty ||
                _processing
                ? null
                : _selectAll,
            icon: const Icon(
              Icons.select_all,
            ),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed:
            _loading ||
                _items.isEmpty ||
                _processing
                ? null
                : _clearAll,
            icon: const Icon(
              Icons.clear_all,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadItems,
        child: ListView(
          padding:
          const EdgeInsets.all(16),
          children: [
            // =========================================
            // BILL HEADER
            // =========================================

            Card(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                      Colors
                          .indigo
                          .shade100,
                      child:
                      const Icon(
                        Icons
                            .receipt_long,
                        color:
                        Colors.indigo,
                        size: 30,
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            widget.sale
                                .billNumber,
                            style:
                            const TextStyle(
                              fontSize:
                              18,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            _formatDate(
                              widget
                                  .sale
                                  .createdAt,
                            ),
                            style:
                            TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .end,
                      children: [
                        const Text(
                          'BILL TOTAL',
                          style:
                          TextStyle(
                            fontSize:
                            10,
                            color: Colors
                                .grey,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          '₹${widget.sale.grandTotal.toStringAsFixed(2)}',
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize:
                            17,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // =========================================
            // INFORMATION
            // =========================================

            Container(
              padding:
              const EdgeInsets.all(
                12,
              ),
              decoration:
              BoxDecoration(
                color: Colors
                    .orange
                    .shade50,
                borderRadius:
                BorderRadius
                    .circular(
                  10,
                ),
                border: Border.all(
                  color: Colors
                      .orange
                      .shade200,
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Icon(
                    Icons
                        .info_outline,
                    color:
                    Colors.orange,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      'Select the quantity you want to return. Already returned quantities cannot be returned again.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // =========================================
            // ITEMS TITLE
            // =========================================

            Row(
              children: [
                const Text(
                  'Sold Items',
                  style:
                  TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight
                        .bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_items.length} items',
                  style:
                  TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            // =========================================
            // ITEMS
            // =========================================

            if (_items.isEmpty)
              const Padding(
                padding:
                EdgeInsets.all(
                  40,
                ),
                child: Center(
                  child: Text(
                    'No items found for this bill.',
                  ),
                ),
              )
            else
              ..._items
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                    _itemCard(
                      entry.value,
                      entry.key,
                    ),
              ),

            const SizedBox(
              height: 10,
            ),

            // =========================================
            // SUMMARY
            // =========================================

            _summaryCard(),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}