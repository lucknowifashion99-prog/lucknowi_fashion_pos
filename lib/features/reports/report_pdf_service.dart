import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPdfService {
  static Future<void> generateAndPrint({
    required DateTime fromDate,
    required DateTime toDate,
    required double sales,
    required double returns,
    required double netSales,
    required double purchase,
    required double profit,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> staffSales,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd-MM-yyyy');

    String money(double value) {
      return 'Rs. ${value.toStringAsFixed(2)}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            // =====================================================
            // HEADER
            // =====================================================

            pw.Center(
              child: pw.Text(
                'LUCKNOWI FASHION',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 5),

            pw.Center(
              child: pw.Text(
                'Business Report',
                style: const pw.TextStyle(
                  fontSize: 14,
                ),
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Center(
              child: pw.Text(
                '${dateFormat.format(fromDate)}  to  '
                    '${dateFormat.format(toDate)}',
                style: const pw.TextStyle(
                  fontSize: 11,
                ),
              ),
            ),

            pw.SizedBox(height: 25),

            // =====================================================
            // SUMMARY
            // =====================================================

            pw.Text(
              'Summary',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
              },
              children: [
                _summaryRow(
                  'Total Sales',
                  money(sales),
                ),
                _summaryRow(
                  'Returns / Refund',
                  money(returns),
                ),
                _summaryRow(
                  'Net Sales',
                  money(netSales),
                ),
                _summaryRow(
                  'Purchase',
                  money(purchase),
                ),
                _summaryRow(
                  'Net Profit',
                  money(profit),
                ),
              ],
            ),

            pw.SizedBox(height: 25),

            // =====================================================
            // TOP SELLING PRODUCTS
            // =====================================================

            pw.Text(
              'Top Selling Products',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 8),

            if (topProducts.isEmpty)
              pw.Text(
                'No product sales found.',
              )
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                },
                children: [
                  _productHeaderRow(),
                  ...List.generate(
                    topProducts.length,
                        (index) {
                      final item =
                      topProducts[index];

                      return _productRow(
                        index + 1,
                        item['productName']
                            ?.toString() ??
                            '',
                        (item['soldQuantity']
                        as num?)
                            ?.toInt() ??
                            0,
                        (item['returnedQuantity']
                        as num?)
                            ?.toInt() ??
                            0,
                        (item['netQuantity']
                        as num?)
                            ?.toInt() ??
                            0,
                      );
                    },
                  ),
                ],
              ),

            pw.SizedBox(height: 25),

            // =====================================================
            // STAFF SALES
            // =====================================================

            pw.Text(
              'Staff-wise Sales',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 8),

            if (staffSales.isEmpty)
              pw.Text(
                'No staff sales found.',
              )
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.3),
                  3: const pw.FlexColumnWidth(1.3),
                  4: const pw.FlexColumnWidth(1.3),
                },
                children: [
                  _staffHeaderRow(),
                  ...List.generate(
                    staffSales.length,
                        (index) {
                      final item =
                      staffSales[index];

                      final staffName =
                          item['staffName']
                              ?.toString() ??
                              'Admin / Unknown';

                      final totalSales =
                          (item['totalSales']
                          as num?)
                              ?.toDouble() ??
                              0;

                      final returnAmount =
                          (item['returns']
                          as num?)
                              ?.toDouble() ??
                              0;

                      final net =
                          totalSales -
                              returnAmount;

                      return _staffRow(
                        index + 1,
                        staffName,
                        totalSales,
                        returnAmount,
                        net,
                      );
                    },
                  ),
                ],
              ),

            pw.SizedBox(height: 30),

            pw.Divider(),

            pw.Center(
              child: pw.Text(
                'Lucknowi Fashion • Generated Report',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return pdf.save();
      },
    );
  }

  // =============================================================
  // SUMMARY ROW
  // =============================================================

  static pw.TableRow _summaryRow(
      String title,
      String value,
      ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(title),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // =============================================================
  // PRODUCT HEADER
  // =============================================================

  static pw.TableRow _productHeaderRow() {
    return pw.TableRow(
      children: [
        _cell('#', bold: true),
        _cell('Product', bold: true),
        _cell('Sold', bold: true),
        _cell('Returned', bold: true),
        _cell('Net', bold: true),
      ],
    );
  }

  // =============================================================
  // PRODUCT ROW
  // =============================================================

  static pw.TableRow _productRow(
      int index,
      String product,
      int sold,
      int returned,
      int net,
      ) {
    return pw.TableRow(
      children: [
        _cell(index.toString()),
        _cell(product),
        _cell(sold.toString()),
        _cell(returned.toString()),
        _cell(net.toString()),
      ],
    );
  }

  // =============================================================
  // STAFF HEADER
  // =============================================================

  static pw.TableRow _staffHeaderRow() {
    return pw.TableRow(
      children: [
        _cell('#', bold: true),
        _cell('Staff', bold: true),
        _cell('Sales', bold: true),
        _cell('Returns', bold: true),
        _cell('Net Sales', bold: true),
      ],
    );
  }

  // =============================================================
  // STAFF ROW
  // =============================================================

  static pw.TableRow _staffRow(
      int index,
      String staff,
      double sales,
      double returns,
      double net,
      ) {
    String money(double value) {
      return 'Rs. ${value.toStringAsFixed(2)}';
    }

    return pw.TableRow(
      children: [
        _cell(index.toString()),
        _cell(staff),
        _cell(money(sales)),
        _cell(money(returns)),
        _cell(money(net)),
      ],
    );
  }

  // =============================================================
  // TABLE CELL
  // =============================================================

  static pw.Widget _cell(
      String text, {
        bool bold = false,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }
}