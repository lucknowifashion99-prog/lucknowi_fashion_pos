import 'dart:io';

import 'package:excel_plus/excel_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportExcelService {
  static Future<String> exportReport({
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
    final excel = Excel.createExcel();
    final sheet = excel['Report'];

    final from =
        '${fromDate.day.toString().padLeft(2, '0')}-'
        '${fromDate.month.toString().padLeft(2, '0')}-'
        '${fromDate.year}';

    final to =
        '${toDate.day.toString().padLeft(2, '0')}-'
        '${toDate.month.toString().padLeft(2, '0')}-'
        '${toDate.year}';

    // =========================================================
    // TITLE
    // =========================================================

    sheet.cell(
      CellIndex.indexByString('A1'),
    ).value = TextCellValue(
      'LUCKNOWI FASHION',
    );

    sheet.cell(
      CellIndex.indexByString('A2'),
    ).value = TextCellValue(
      'Business Report',
    );

    sheet.cell(
      CellIndex.indexByString('A3'),
    ).value = TextCellValue(
      '$from to $to',
    );

    // =========================================================
    // SUMMARY
    // =========================================================

    sheet.cell(
      CellIndex.indexByString('A5'),
    ).value = TextCellValue('SUMMARY');

    sheet.cell(
      CellIndex.indexByString('A6'),
    ).value = TextCellValue('Total Sales');

    sheet.cell(
      CellIndex.indexByString('B6'),
    ).value = DoubleCellValue(sales);

    sheet.cell(
      CellIndex.indexByString('A7'),
    ).value = TextCellValue('Returns / Refund');

    sheet.cell(
      CellIndex.indexByString('B7'),
    ).value = DoubleCellValue(returns);

    sheet.cell(
      CellIndex.indexByString('A8'),
    ).value = TextCellValue('Net Sales');

    sheet.cell(
      CellIndex.indexByString('B8'),
    ).value = DoubleCellValue(netSales);

    sheet.cell(
      CellIndex.indexByString('A9'),
    ).value = TextCellValue('Purchase');

    sheet.cell(
      CellIndex.indexByString('B9'),
    ).value = DoubleCellValue(purchase);

    sheet.cell(
      CellIndex.indexByString('A10'),
    ).value = TextCellValue('Net Profit');

    sheet.cell(
      CellIndex.indexByString('B10'),
    ).value = DoubleCellValue(profit);

    // =========================================================
    // TOP SELLING PRODUCTS
    // =========================================================

    sheet.cell(
      CellIndex.indexByString('A12'),
    ).value = TextCellValue(
      'TOP SELLING PRODUCTS',
    );

    sheet.cell(
      CellIndex.indexByString('A13'),
    ).value = TextCellValue('#');

    sheet.cell(
      CellIndex.indexByString('B13'),
    ).value = TextCellValue('Product');

    sheet.cell(
      CellIndex.indexByString('C13'),
    ).value = TextCellValue('Sold');

    sheet.cell(
      CellIndex.indexByString('D13'),
    ).value = TextCellValue('Returned');

    sheet.cell(
      CellIndex.indexByString('E13'),
    ).value = TextCellValue('Net');

    for (int i = 0; i < topProducts.length; i++) {
      final row = 14 + i;
      final item = topProducts[i];

      final sold =
          (item['soldQuantity'] as num?)
              ?.toInt() ??
              0;

      final returned =
          (item['returnedQuantity'] as num?)
              ?.toInt() ??
              0;

      final net =
          (item['netQuantity'] as num?)
              ?.toInt() ??
              sold - returned;

      sheet.cell(
        CellIndex.indexByString('A$row'),
      ).value = IntCellValue(i + 1);

      sheet.cell(
        CellIndex.indexByString('B$row'),
      ).value = TextCellValue(
        item['productName']?.toString() ?? '',
      );

      sheet.cell(
        CellIndex.indexByString('C$row'),
      ).value = IntCellValue(sold);

      sheet.cell(
        CellIndex.indexByString('D$row'),
      ).value = IntCellValue(returned);

      sheet.cell(
        CellIndex.indexByString('E$row'),
      ).value = IntCellValue(net);
    }

    // =========================================================
    // STAFF-WISE SALES
    // =========================================================

    final staffStartRow =
        15 + topProducts.length;

    sheet.cell(
      CellIndex.indexByString(
        'A$staffStartRow',
      ),
    ).value = TextCellValue(
      'STAFF-WISE SALES',
    );

    final staffHeaderRow =
        staffStartRow + 1;

    sheet.cell(
      CellIndex.indexByString(
        'A$staffHeaderRow',
      ),
    ).value = TextCellValue('#');

    sheet.cell(
      CellIndex.indexByString(
        'B$staffHeaderRow',
      ),
    ).value = TextCellValue('Staff');

    sheet.cell(
      CellIndex.indexByString(
        'C$staffHeaderRow',
      ),
    ).value = TextCellValue('Sales');

    sheet.cell(
      CellIndex.indexByString(
        'D$staffHeaderRow',
      ),
    ).value = TextCellValue('Returns');

    sheet.cell(
      CellIndex.indexByString(
        'E$staffHeaderRow',
      ),
    ).value = TextCellValue('Net Sales');

    for (int i = 0; i < staffSales.length; i++) {
      final row =
          staffHeaderRow + 1 + i;

      final item = staffSales[i];

      final staffName =
          item['staffName']?.toString() ??
              'Admin / Unknown';

      final totalSales =
          (item['totalSales'] as num?)
              ?.toDouble() ??
              0.0;

      final returnAmount =
          (item['returns'] as num?)
              ?.toDouble() ??
              0.0;

      final net =
          totalSales - returnAmount;

      sheet.cell(
        CellIndex.indexByString('A$row'),
      ).value = IntCellValue(i + 1);

      sheet.cell(
        CellIndex.indexByString('B$row'),
      ).value = TextCellValue(staffName);

      sheet.cell(
        CellIndex.indexByString('C$row'),
      ).value = DoubleCellValue(totalSales);

      sheet.cell(
        CellIndex.indexByString('D$row'),
      ).value = DoubleCellValue(returnAmount);

      sheet.cell(
        CellIndex.indexByString('E$row'),
      ).value = DoubleCellValue(net);
    }

    // =========================================================
    // REMOVE DEFAULT SHEET
    // =========================================================

    if (excel.sheets.keys.contains('Sheet1') &&
        excel.sheets.keys.length > 1) {
      excel.delete('Sheet1');
    }

    // =========================================================
    // GENERATE EXCEL BYTES
    // =========================================================

    final bytes = excel.encode();

    if (bytes == null || bytes.isEmpty) {
      throw Exception(
        'Excel file generate nahi hui.',
      );
    }

    // =========================================================
    // SAVE FILE
    // =========================================================

    final directory =
    await getApplicationDocumentsDirectory();

    final fileName =
        'Lucknowi_Fashion_Report_'
        '${fromDate.year}_'
        '${fromDate.month.toString().padLeft(2, '0')}_'
        '${fromDate.day.toString().padLeft(2, '0')}.xlsx';

    final filePath =
        '${directory.path}/$fileName';

    final file = File(filePath);

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    // =========================================================
    // VERIFY FILE
    // =========================================================

    final exists = await file.exists();

    if (!exists) {
      throw Exception(
        'Excel file save nahi hui.',
      );
    }

    final fileSize = await file.length();

    if (fileSize == 0) {
      throw Exception(

        'Excel file empty hai.',
      );
    }

    // =========================================================
    // SHARE ACTUAL XLSX FILE
    // =========================================================

    final xFile = XFile(
      filePath,
      name: fileName,
      mimeType:
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: 'Lucknowi Fashion Business Report',
        text: 'Lucknowi Fashion Business Report',
      ),
    );

    return filePath;
  }
}