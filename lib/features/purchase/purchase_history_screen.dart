import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/purchase_provider.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() =>
      _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState
    extends State<PurchaseHistoryScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
    });
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> _refresh() async {
    await context.read<PurchaseProvider>().loadPurchases();
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value);

      return DateFormat(
        'dd-MM-yyyy',
      ).format(date);
    } catch (_) {
      return value;
    }
  }

  // =========================================================
  // DELETE CONFIRMATION
  // =========================================================

  Future<void> _confirmDelete(
      Map<String, dynamic> purchase,
      ) async {
    final purchaseId =
    purchase['id'] as int?;

    if (purchaseId == null) {
      return;
    }

    final invoiceNumber =
        purchase['invoiceNumber']?.toString() ??
            '-';

    final confirm =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Purchase?',
          ),
          content: Text(
            'Purchase $invoiceNumber delete karne par us purchase ka stock reverse ho jayega.',
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
                'CANCEL',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'DELETE',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await context
          .read<PurchaseProvider>()
          .deletePurchase(
        purchaseId,
      );

      if (!mounted) return;

      _showMessage(
        'Purchase deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Delete failed: $e',
        isError: true,
      );
    }
  }

  // =========================================================
  // PURCHASE DETAILS
  // =========================================================

  Future<void> _showPurchaseDetails(
      Map<String, dynamic> purchase,
      ) async {
    final purchaseId =
    purchase['id'] as int?;

    if (purchaseId == null) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _PurchaseDetailsDialog(
          purchaseId: purchaseId,
          purchase: purchase,
        );
      },
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? Colors.red : Colors.green,
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
        title: const Text(
          'Purchase History',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (
            context,
            provider,
            child,
            ) {
          if (provider.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.purchases.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height:
                    MediaQuery.of(context)
                        .size
                        .height *
                        0.3,
                  ),
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Center(
                    child: Text(
                      'No Purchase Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Center(
                    child: Text(
                      'Saved purchases yahan dikhenge.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding:
              const EdgeInsets.all(16),
              itemCount:
              provider.purchases.length,
              itemBuilder:
                  (context, index) {
                final purchase =
                provider.purchases[index];

                final invoice =
                    purchase[
                    'invoiceNumber']
                        ?.toString() ??
                        '-';

                final date =
                _formatDate(
                  purchase['createdAt']
                      ?.toString(),
                );

                final total =
                    (purchase['grandTotal']
                    as num?)
                        ?.toDouble() ??
                        0;

                final paymentStatus =
                    purchase[
                    'paymentStatus']
                        ?.toString() ??
                        'Paid';

                return Card(
                  margin:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    onTap: () {
                      _showPurchaseDetails(
                        purchase,
                      );
                    },
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        14,
                      ),
                      child: Row(
                        children: [
                          // =====================
                          // ICON
                          // =====================

                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                            Colors.purple
                                .withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              color:
                              Colors.purple,
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          // =====================
                          // DETAILS
                          // =====================

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  invoice,
                                  style:
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  'Date: $date',
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.grey,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  'Payment: $paymentStatus',
                                  style:
                                  TextStyle(
                                    fontSize: 12,
                                    color:
                                    paymentStatus
                                        .toLowerCase() ==
                                        'paid'
                                        ? Colors
                                        .green
                                        : Colors
                                        .orange,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // =====================
                          // TOTAL + DELETE
                          // =====================

                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .end,
                            children: [
                              Text(
                                '₹${total.toStringAsFixed(2)}',
                                style:
                                const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              IconButton(
                                onPressed: () {
                                  _confirmDelete(
                                    purchase,
                                  );
                                },
                                icon:
                                const Icon(
                                  Icons
                                      .delete_outline,
                                  color:
                                  Colors.red,
                                ),
                                tooltip:
                                'Delete Purchase',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// =============================================================
// PURCHASE DETAILS DIALOG
// =============================================================

class _PurchaseDetailsDialog
    extends StatefulWidget {
  final int purchaseId;

  final Map<String, dynamic> purchase;

  const _PurchaseDetailsDialog({
    required this.purchaseId,
    required this.purchase,
  });

  @override
  State<_PurchaseDetailsDialog> createState() =>
      _PurchaseDetailsDialogState();
}

class _PurchaseDetailsDialogState
    extends State<_PurchaseDetailsDialog> {
  late Future<List<Map<String, dynamic>>>
  _itemsFuture;

  @override
  void initState() {
    super.initState();

    _itemsFuture = context
        .read<PurchaseProvider>()
        .getPurchaseItems(
      widget.purchaseId,
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    try {
      return DateFormat(
        'dd-MM-yyyy',
      ).format(
        DateTime.parse(value),
      );
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice =
        widget.purchase[
        'invoiceNumber']
            ?.toString() ??
            '-';

    final date = _formatDate(
      widget.purchase['createdAt']
          ?.toString(),
    );

    final subtotal =
        (widget.purchase['subtotal']
        as num?)
            ?.toDouble() ??
            0;

    final gst =
        (widget.purchase['gst']
        as num?)
            ?.toDouble() ??
            0;

    final discount =
        (widget.purchase['discount']
        as num?)
            ?.toDouble() ??
            0;

    final grandTotal =
        (widget.purchase['grandTotal']
        as num?)
            ?.toDouble() ??
            0;

    return AlertDialog(
      title: Text(
        invoice,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Date: $date',
            ),

            const SizedBox(
              height: 12,
            ),

            const Divider(),

            const Text(
              'Purchase Items',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Expanded(
              child: FutureBuilder<
                  List<Map<String, dynamic>>>(
                future: _itemsFuture,
                builder: (
                    context,
                    snapshot,
                    ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                      CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load items.',
                      ),
                    );
                  }

                  final items =
                      snapshot.data ?? [];

                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No items found.',
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount:
                    items.length,
                    separatorBuilder:
                        (_, __) =>
                    const Divider(),
                    itemBuilder:
                        (context, index) {
                      final item =
                      items[index];

                      final name =
                          item['productName']
                              ?.toString() ??
                              '-';

                      final color =
                          item['color']
                              ?.toString() ??
                              '-';

                      final size =
                          item['size']
                              ?.toString() ??
                              '-';

                      final quantity =
                          (item['quantity']
                          as num?)
                              ?.toInt() ??
                              0;

                      final price =
                          (item[
                          'purchasePrice']
                          as num?)
                              ?.toDouble() ??
                              0;

                      final total =
                          (item['total']
                          as num?)
                              ?.toDouble() ??
                              0;

                      return ListTile(
                        contentPadding:
                        EdgeInsets.zero,
                        title: Text(
                          name,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$color / $size\n'
                              'Qty: $quantity × '
                              '₹${price.toStringAsFixed(2)}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '₹${total.toStringAsFixed(2)}',
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(),

            _summaryRow(
              'Subtotal',
              subtotal,
            ),

            const SizedBox(
              height: 4,
            ),

            _summaryRow(
              'GST',
              gst,
            ),

            const SizedBox(
              height: 4,
            ),

            _summaryRow(
              'Discount',
              discount,
            ),

            const SizedBox(
              height: 6,
            ),

            _summaryRow(
              'Grand Total',
              grandTotal,
              bold: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'CLOSE',
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
      String title,
      double amount, {
        bool bold = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}