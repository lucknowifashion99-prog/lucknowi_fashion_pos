import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/customer.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../returns/sales_return_screen.dart';

class BillPreview extends StatelessWidget {
  final Sale sale;
  final List<SaleItem> items;
  final Customer? customer;

  const BillPreview({
    super.key,
    required this.sale,
    required this.items,
    this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Preview'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // SHOP HEADER
                    // =================================================

                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'LUCKNOWI FASHION',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Fashion & Lifestyle',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                        ],
                      ),
                    ),

                    // =================================================
                    // BILL DETAILS
                    // =================================================

                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BILL NUMBER',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                sale.billNumber,
                                style: const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'DATE',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDate(
                                sale.createdAt,
                              ),
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // CUSTOMER
                    // =================================================

                    const Text(
                      'CUSTOMER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                          Colors.grey.shade300,
                        ),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer?.name ??
                                'Walk-in Customer',
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_hasText(
                            customer?.phone,
                          )) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${customer!.phone}',
                            ),
                          ],
                          if (_hasText(
                            customer?.email,
                          )) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Email: ${customer!.email}',
                            ),
                          ],
                          if (_hasText(
                            customer?.address,
                          )) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Address: ${customer!.address}',
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // ITEMS
                    // =================================================

                    const Text(
                      'ITEMS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                          Colors.grey.shade300,
                        ),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              Colors.grey.shade100,
                              borderRadius:
                              const BorderRadius
                                  .vertical(
                                top:
                                Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'ITEM',
                                    style:
                                    TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'QTY',
                                    textAlign:
                                    TextAlign
                                        .center,
                                    style:
                                    TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'PRICE',
                                    textAlign:
                                    TextAlign
                                        .right,
                                    style:
                                    TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'TOTAL',
                                    textAlign:
                                    TextAlign
                                        .right,
                                    style:
                                    TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.asMap().entries.map(
                                (entry) {
                              return _itemRow(
                                entry.value,
                                entry.key,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // PAYMENT
                    // =================================================

                    Row(
                      children: [
                        const Text(
                          'Payment Method:',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration:
                          BoxDecoration(
                            borderRadius:
                            BorderRadius
                                .circular(20),
                            color:
                            Colors.grey.shade200,
                          ),
                          child: Text(
                            sale.paymentMethod,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'PAID',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Divider(),

                    // =================================================
                    // SUMMARY
                    // =================================================

                    _summaryRow(
                      'Subtotal',
                      sale.subtotal,
                    ),

                    const SizedBox(height: 6),

                    _summaryRow(
                      'GST',
                      sale.gst,
                    ),

                    const SizedBox(height: 6),

                    _summaryRow(
                      'Discount',
                      sale.discount,
                    ),

                    const Divider(),

                    _summaryRow(
                      'GRAND TOTAL',
                      sale.grandTotal,
                      bold: true,
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // TERMS
                    // =================================================

                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                          Colors.grey.shade300,
                        ),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TERMS & CONDITIONS',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Return: Return accepted within 24 hours of purchase.',
                            style:
                            TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '2. Exchange: Exchange accepted within 7 days of purchase.',
                            style:
                            TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =================================================
                    // FOOTER
                    // =================================================

                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'Thank You!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Visit Again',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =================================================
                    // RETURN + PRINT + DONE
                    // =================================================

                    Row(
                      children: [
                        // RETURN
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child:
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SalesReturnScreen(
                                          sale: sale,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.assignment_return,
                              ),
                              label: const Text(
                                'RETURN SALE',
                                style: TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              style:
                              OutlinedButton.styleFrom(
                                foregroundColor:
                                Colors.red,
                                side:
                                const BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // PRINT
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child:
                            ElevatedButton.icon(
                              onPressed: () {
                                _printBill(
                                  context,
                                );
                              },
                              icon: const Icon(
                                Icons.print,
                              ),
                              label: const Text(
                                'PRINT',
                                style: TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // DONE
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child:
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                );
                              },
                              icon: const Icon(
                                Icons.done,
                              ),
                              label: const Text(
                                'DONE',
                                style: TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PRINT BILL
  // =========================================================

  Future<void> _printBill(
      BuildContext context,
      ) async {
    try {
      final pdf = await _buildPdf();

      await Printing.layoutPdf(
        onLayout:
            (PdfPageFormat format) async {
          return pdf;
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Print failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // BUILD PDF
  // =========================================================

  Future<Uint8List> _buildPdf() async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat:
        PdfPageFormat.a4,
        margin:
        const pw.EdgeInsets.all(32),
        build:
            (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'LUCKNOWI FASHION',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight:
                      pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Fashion & Lifestyle',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color:
                      PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment
                  .spaceBetween,
              crossAxisAlignment:
              pw.CrossAxisAlignment
                  .start,
              children: [
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment
                      .start,
                  children: [
                    pw.Text(
                      'BILL NUMBER',
                      style:
                      pw.TextStyle(
                        fontSize: 9,
                        color:
                        PdfColors
                            .grey700,
                        fontWeight:
                        pw.FontWeight
                            .bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      sale.billNumber,
                      style:
                      pw.TextStyle(
                        fontSize: 11,
                        fontWeight:
                        pw.FontWeight
                            .bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment
                      .end,
                  children: [
                    pw.Text(
                      'DATE',
                      style:
                      pw.TextStyle(
                        fontSize: 9,
                        color:
                        PdfColors
                            .grey700,
                        fontWeight:
                        pw.FontWeight
                            .bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      _formatDate(
                        sale.createdAt,
                      ),
                      style:
                      const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            pw.Text(
              'CUSTOMER',
              style: pw.TextStyle(
                fontSize: 10,
                color:
                PdfColors.grey700,
                fontWeight:
                pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 5),

            pw.Container(
              width: double.infinity,
              padding:
              const pw.EdgeInsets.all(10),
              decoration:
              pw.BoxDecoration(
                border: pw.Border.all(
                  color:
                  PdfColors.grey300,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment:
                pw.CrossAxisAlignment
                    .start,
                children: [
                  pw.Text(
                    customer?.name ??
                        'Walk-in Customer',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight:
                      pw.FontWeight.bold,
                    ),
                  ),
                  if (_hasText(
                    customer?.phone,
                  ))
                    pw.Padding(
                      padding:
                      const pw.EdgeInsets
                          .only(top: 3),
                      child: pw.Text(
                        'Phone: ${customer!.phone}',
                        style:
                        const pw.TextStyle(
                          fontSize: 9,
                        ),
                      ),
                    ),
                  if (_hasText(
                    customer?.email,
                  ))
                    pw.Padding(
                      padding:
                      const pw.EdgeInsets
                          .only(top: 3),
                      child: pw.Text(
                        'Email: ${customer!.email}',
                        style:
                        const pw.TextStyle(
                          fontSize: 9,
                        ),
                      ),
                    ),
                  if (_hasText(
                    customer?.address,
                  ))
                    pw.Padding(
                      padding:
                      const pw.EdgeInsets
                          .only(top: 3),
                      child: pw.Text(
                        'Address: ${customer!.address}',
                        style:
                        const pw.TextStyle(
                          fontSize: 9,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            pw.Table(
              border:
              pw.TableBorder.all(
                color:
                PdfColors.grey300,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(
                    4),
                1: const pw.FlexColumnWidth(
                    1),
                2: const pw.FlexColumnWidth(
                    2),
                3: const pw.FlexColumnWidth(
                    2),
              },
              children: [
                pw.TableRow(
                  decoration:
                  const pw.BoxDecoration(
                    color:
                    PdfColors.grey200,
                  ),
                  children: [
                    _pdfCell(
                      'ITEM',
                      bold: true,
                    ),
                    _pdfCell(
                      'QTY',
                      bold: true,
                      align:
                      pw.TextAlign.center,
                    ),
                    _pdfCell(
                      'PRICE',
                      bold: true,
                      align:
                      pw.TextAlign.right,
                    ),
                    _pdfCell(
                      'TOTAL',
                      bold: true,
                      align:
                      pw.TextAlign.right,
                    ),
                  ],
                ),
                ...items.map(
                      (item) {
                    return pw.TableRow(
                      children: [
                        _pdfItemCell(
                          item,
                        ),
                        _pdfCell(
                          '${item.quantity}',
                          align:
                          pw.TextAlign
                              .center,
                        ),
                        _pdfCell(
                          'Rs. ${item.sellingPrice.toStringAsFixed(2)}',
                          align:
                          pw.TextAlign
                              .right,
                        ),
                        _pdfCell(
                          'Rs. ${item.total.toStringAsFixed(2)}',
                          bold: true,
                          align:
                          pw.TextAlign
                              .right,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment
                  .spaceBetween,
              children: [
                pw.Text(
                  'Payment Method: ${sale.paymentMethod}',
                  style:
                  pw.TextStyle(
                    fontSize: 10,
                    fontWeight:
                    pw.FontWeight
                        .bold,
                  ),
                ),
                pw.Text(
                  'PAID',
                  style:
                  pw.TextStyle(
                    fontSize: 10,
                    fontWeight:
                    pw.FontWeight
                        .bold,
                    color:
                    PdfColors.green,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Divider(),

            _pdfSummaryRow(
              'Subtotal',
              sale.subtotal,
            ),
            _pdfSummaryRow(
              'GST',
              sale.gst,
            ),
            _pdfSummaryRow(
              'Discount',
              sale.discount,
            ),

            pw.Divider(),

            _pdfSummaryRow(
              'GRAND TOTAL',
              sale.grandTotal,
              bold: true,
            ),

            pw.SizedBox(height: 18),

            pw.Container(
              width: double.infinity,
              padding:
              const pw.EdgeInsets.all(10),
              decoration:
              pw.BoxDecoration(
                border: pw.Border.all(
                  color:
                  PdfColors.grey300,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment:
                pw.CrossAxisAlignment
                    .start,
                children: [
                  pw.Text(
                    'TERMS & CONDITIONS',
                    style:
                    pw.TextStyle(
                      fontSize: 9,
                      fontWeight:
                      pw.FontWeight
                          .bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '1. Return: Return accepted within 24 hours of purchase.',
                    style:
                    const pw.TextStyle(
                      fontSize: 8,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '2. Exchange: Exchange accepted within 7 days of purchase.',
                    style:
                    const pw.TextStyle(
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 22),

            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank You!',
                    style:
                    pw.TextStyle(
                      fontSize: 14,
                      fontWeight:
                      pw.FontWeight
                          .bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Visit Again',
                    style:
                    pw.TextStyle(
                      fontSize: 9,
                      color:
                      PdfColors
                          .grey700,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return document.save();
  }

  // =========================================================
  // PDF CELL
  // =========================================================

  pw.Widget _pdfCell(
      String text, {
        bool bold = false,
        pw.TextAlign align =
            pw.TextAlign.left,
      }) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold
              ? pw.FontWeight.bold
              : null,
        ),
      ),
    );
  }

  // =========================================================
  // PDF ITEM CELL
  // =========================================================

  pw.Widget _pdfItemCell(
      SaleItem item,
      ) {
    final name =
    _buildItemName(item);

    final details = <String>[
      name,
      if (_hasText(item.sku))
        'SKU: ${item.sku}',
      if (_hasText(item.barcode))
        'Barcode: ${item.barcode}',
    ];

    return pw.Padding(
      padding:
      const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment
            .start,
        children: [
          pw.Text(
            details.first,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),
          for (final detail
          in details.skip(1))
            pw.Text(
              detail,
              style: pw.TextStyle(
                fontSize: 7,
                color:
                PdfColors.grey700,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // PDF SUMMARY
  // =========================================================

  pw.Widget _pdfSummaryRow(
      String title,
      double amount, {
        bool bold = false,
      }) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment
            .spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize:
              bold ? 12 : 9,
              fontWeight: bold
                  ? pw.FontWeight.bold
                  : null,
            ),
          ),
          pw.Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize:
              bold ? 13 : 9,
              fontWeight: bold
                  ? pw.FontWeight.bold
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // UI ITEM ROW
  // =========================================================

  Widget _itemRow(
      SaleItem item,
      int index,
      ) {
    final itemName =
    _buildItemName(item);

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
            Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  itemName,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (_hasText(item.sku))
                  Text(
                    'SKU: ${item.sku}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors
                          .grey.shade600,
                    ),
                  ),
                if (_hasText(
                  item.barcode,
                ))
                  Text(
                    'Barcode: ${item.barcode}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors
                          .grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.quantity}',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${item.sellingPrice.toStringAsFixed(2)}',
              textAlign:
              TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${item.total.toStringAsFixed(2)}',
              textAlign:
              TextAlign.right,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ],
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
  // SUMMARY ROW
  // =========================================================

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
            fontSize:
            bold ? 18 : 14,
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize:
            bold ? 20 : 14,
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TEXT CHECK
  // =========================================================

  bool _hasText(String? value) {
    return value != null &&
        value.trim().isNotEmpty;
  }

  // =========================================================
  // DATE FORMAT
  // =========================================================

  String _formatDate(
      String value,
      ) {
    try {
      final date =
      DateTime.parse(value);

      final day = date.day
          .toString()
          .padLeft(2, '0');

      final month = date.month
          .toString()
          .padLeft(2, '0');

      final year =
      date.year.toString();

      final hour = date.hour
          .toString()
          .padLeft(2, '0');

      final minute = date.minute
          .toString()
          .padLeft(2, '0');

      return '$day/$month/$year  '
          '$hour:$minute';
    } catch (_) {
      return value;
    }
  }
}