import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterService {
  PrinterService._();

  static final PrinterService instance = PrinterService._();

  BluetoothInfo? _selectedPrinter;

  // =========================================================
  // SELECTED PRINTER
  // =========================================================

  BluetoothInfo? get selectedPrinter => _selectedPrinter;

  bool get hasSelectedPrinter => _selectedPrinter != null;

  void selectPrinter(BluetoothInfo printer) {
    _selectedPrinter = printer;
  }

  // =========================================================
  // GET PAIRED PRINTERS
  // =========================================================

  Future<List<BluetoothInfo>> getPrinters() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (_) {
      return [];
    }
  }

  // =========================================================
  // BLUETOOTH STATUS
  // =========================================================

  Future<bool> isBluetoothEnabled() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (_) {
      // Windows par bluetoothEnabled supported nahi hai.
      return true;
    }
  }

  // =========================================================
  // CONNECTION STATUS
  // =========================================================

  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // CONNECT
  // =========================================================

  Future<bool> connect() async {
    final printer = _selectedPrinter;

    if (printer == null) {
      return false;
    }

    try {
      final alreadyConnected =
      await PrintBluetoothThermal.connectionStatus;

      if (alreadyConnected) {
        return true;
      }

      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: printer.macAdress,
      );

      return result;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // DISCONNECT
  // =========================================================

  Future<bool> disconnect() async {
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // SEND RAW BYTES
  // =========================================================

  Future<bool> _writeBytes(List<int> bytes) async {
    try {
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // TEXT
  // =========================================================

  Future<bool> _writeText(String text) async {
    return _writeBytes(text.codeUnits);
  }

  // =========================================================
  // NEW LINE
  // =========================================================

  Future<bool> _newLine() async {
    return _writeBytes([0x0A]);
  }

  // =========================================================
  // CENTER
  // ESC a 1
  // =========================================================

  Future<bool> _center() async {
    return _writeBytes([
      0x1B,
      0x61,
      0x01,
    ]);
  }

  // =========================================================
  // LEFT
  // ESC a 0
  // =========================================================

  Future<bool> _left() async {
    return _writeBytes([
      0x1B,
      0x61,
      0x00,
    ]);
  }

  // =========================================================
  // BOLD ON
  // =========================================================

  Future<bool> _boldOn() async {
    return _writeBytes([
      0x1B,
      0x45,
      0x01,
    ]);
  }

  // =========================================================
  // BOLD OFF
  // =========================================================

  Future<bool> _boldOff() async {
    return _writeBytes([
      0x1B,
      0x45,
      0x00,
    ]);
  }

  // =========================================================
  // DOUBLE SIZE ON
  // =========================================================

  Future<bool> _doubleSizeOn() async {
    return _writeBytes([
      0x1D,
      0x21,
      0x11,
    ]);
  }

  // =========================================================
  // NORMAL SIZE
  // =========================================================

  Future<bool> _normalSize() async {
    return _writeBytes([
      0x1D,
      0x21,
      0x00,
    ]);
  }

  // =========================================================
  // PAPER CUT
  // =========================================================

  Future<bool> _cutPaper() async {
    return _writeBytes([
      0x1D,
      0x56,
      0x00,
    ]);
  }

  // =========================================================
  // TEST PRINT
  // =========================================================

  Future<bool> printTest() async {
    try {
      // -----------------------------------------
      // CONNECTION
      // -----------------------------------------

      if (!await isConnected()) {
        final connected = await connect();

        if (!connected) {
          return false;
        }
      }

      // -----------------------------------------
      // RESET
      // -----------------------------------------

      await _writeBytes([
        0x1B,
        0x40,
      ]);

      // -----------------------------------------
      // HEADER
      // -----------------------------------------

      await _center();

      await _boldOn();
      await _doubleSizeOn();

      await _writeText(
        'LUCKNOWI FASHION',
      );

      await _newLine();

      await _normalSize();
      await _boldOff();

      await _writeText(
        'Fashion & Lifestyle',
      );

      await _newLine();
      await _newLine();

      await _writeText(
        '--------------------------------',
      );

      await _newLine();

      // -----------------------------------------
      // TEST
      // -----------------------------------------

      await _boldOn();

      await _writeText(
        'THERMAL PRINTER TEST',
      );

      await _newLine();

      await _boldOff();

      await _writeText(
        'Shreyans CD410',
      );

      await _newLine();

      await _writeText(
        '58mm Receipt',
      );

      await _newLine();

      await _writeText(
        'Bluetooth Connected',
      );

      await _newLine();

      await _writeText(
        '--------------------------------',
      );

      await _newLine();
      await _newLine();

      // -----------------------------------------
      // SUCCESS
      // -----------------------------------------

      await _boldOn();

      await _writeText(
        'TEST PRINT SUCCESSFUL',
      );

      await _newLine();

      await _boldOff();

      await _writeText(
        'Thank You!',
      );

      await _newLine();

      await _writeText(
        'Visit Again',
      );

      await _newLine();
      await _newLine();
      await _newLine();

      // -----------------------------------------
      // CUT
      // -----------------------------------------

      await _cutPaper();

      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // PRINT BILL - 58MM
  // =========================================================

  Future<bool> printBill({
    required String billNumber,
    required String date,
    required String customerName,
    required String paymentMethod,
    required List<PrinterBillItem> items,
    required double subtotal,
    required double gst,
    required double discount,
    required double grandTotal,
  }) async {
    try {
      // -----------------------------------------
      // CONNECTION
      // -----------------------------------------

      if (!await isConnected()) {
        final connected = await connect();

        if (!connected) {
          return false;
        }
      }

      // -----------------------------------------
      // RESET
      // -----------------------------------------

      await _writeBytes([
        0x1B,
        0x40,
      ]);

      // -----------------------------------------
      // HEADER
      // -----------------------------------------

      await _center();

      await _boldOn();
      await _doubleSizeOn();

      await _writeText(
        'LUCKNOWI FASHION',
      );

      await _newLine();

      await _normalSize();
      await _boldOff();

      await _writeText(
        'Fashion & Lifestyle',
      );

      await _newLine();

      await _writeText(
        '--------------------------------',
      );

      await _newLine();

      // -----------------------------------------
      // BILL DETAILS
      // -----------------------------------------

      await _left();

      await _writeText(
        'Bill No : $billNumber',
      );

      await _newLine();

      await _writeText(
        'Date    : $date',
      );

      await _newLine();

      await _writeText(
        'Customer: ${_limitText(customerName, 22)}',
      );

      await _newLine();

      await _writeText(
        '--------------------------------',
      );

      await _newLine();

      // -----------------------------------------
      // ITEM HEADER
      // -----------------------------------------

      await _boldOn();

      await _writeText(
        'ITEM                 QTY    TOTAL',
      );

      await _newLine();

      await _boldOff();

      await _writeText(
        '--------------------------------',
      );

      await _newLine();

      // -----------------------------------------
      // ITEMS
      // -----------------------------------------

      for (final item in items) {
        final name =
        _limitText(item.name, 18);

        final qty =
        item.quantity.toString();

        final total =
        item.total.toStringAsFixed(2);

        await _writeText(
          name,
        );

        await _newLine();

        await _writeText(
          '  Qty: $qty                 Rs.$total',
        );

        await _newLine();
      }

      // -----------------------------------------
      // SUMMARY
      // -----------------------------------------

      await _writeText(
        '--------------------------------',
      );

      await _newLine();

      await _writeText(
        'Subtotal : Rs.${subtotal.toStringAsFixed(2)}',
      );

      await _newLine();

      await _writeText(
        'GST      : Rs.${gst.toStringAsFixed(2)}',
      );

      await _newLine();

      await _writeText(
        'Discount : Rs.${discount.toStringAsFixed(2)}',
      );

      await _newLine();

      await _writeText(
        '--------------------------------',
      );

      await _newLine();

      // -----------------------------------------
      // GRAND TOTAL
      // -----------------------------------------

      await _boldOn();
      await _doubleSizeOn();

      await _writeText(
        'TOTAL Rs.${grandTotal.toStringAsFixed(2)}',
      );

      await _newLine();

      await _normalSize();
      await _boldOff();

      await _writeText(
        'Payment: $paymentMethod',
      );

      await _newLine();

      // -----------------------------------------
      // PAID
      // -----------------------------------------

      await _center();

      await _boldOn();

      await _writeText(
        'PAID',
      );

      await _newLine();

      await _boldOff();

      await _writeText(
        '--------------------------------',
      );

      await _newLine();

      // -----------------------------------------
      // FOOTER
      // -----------------------------------------

      await _boldOn();

      await _writeText(
        'Thank You!',
      );

      await _newLine();

      await _boldOff();

      await _writeText(
        'Visit Again',
      );

      await _newLine();
      await _newLine();
      await _newLine();

      // -----------------------------------------
      // CUT
      // -----------------------------------------

      await _cutPaper();

      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
// PRINT BARCODE LABEL
// =========================================================

  Future<bool> printBarcodeLabel({
    required String productName,
    required String color,
    required String size,
    required String sku,
    required String barcode,
    required double sellingPrice,
    int quantity = 1,
  }) async {
    try {
      if (barcode.trim().isEmpty) {
        return false;
      }

      if (quantity <= 0) {
        return false;
      }

      // -----------------------------------------
      // CONNECTION
      // -----------------------------------------

      if (!await isConnected()) {
        final connected = await connect();

        if (!connected) {
          return false;
        }
      }

      // -----------------------------------------
      // PRINT LABELS
      // -----------------------------------------

      for (int i = 0; i < quantity; i++) {
        // RESET
        await _writeBytes([
          0x1B,
          0x40,
        ]);

        // CENTER
        await _center();

        // SHOP NAME
        await _boldOn();
        await _writeText(
          'LUCKNOWI FASHION',
        );
        await _newLine();
        await _boldOff();

        // PRODUCT
        await _writeText(
          _limitText(productName, 24),
        );
        await _newLine();

        // VARIANT
        await _writeText(
          '${_limitText(color, 10)} / ${_limitText(size, 8)}',
        );
        await _newLine();

        // PRICE
        await _boldOn();
        await _writeText(
          'Rs.${sellingPrice.toStringAsFixed(2)}',
        );
        await _newLine();
        await _boldOff();

        // SKU
        await _writeText(
          'SKU: ${_limitText(sku, 20)}',
        );
        await _newLine();

        await _writeText(
          'Barcode: $barcode',
        );
        await _newLine();

        await _newLine();

        // ---------------------------------------
        // BARCODE
        // CODE128
        // ---------------------------------------

        final barcodeData =
            barcode.codeUnits;

        final length =
            barcodeData.length + 3;

        final lowByte =
        length & 0xFF;

        final highByte =
        (length >> 8) & 0xFF;

        // HRI position: below barcode
        await _writeBytes([
          0x1D,
          0x48,
          0x02,
        ]);

        // Barcode height
        await _writeBytes([
          0x1D,
          0x68,
          0x50,
        ]);

        // Barcode width
        await _writeBytes([
          0x1D,
          0x77,
          0x02,
        ]);

        // CODE128
        await _writeBytes([
          0x1D,
          0x6B,
          0x49,
          lowByte,
          highByte,
          0x7B,
          0x42,
          ...barcodeData,
        ]);

        await _newLine();
        await _newLine();
        await _newLine();

        // CUT
        await _cutPaper();
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // LIMIT TEXT
  // =========================================================

  String _limitText(
      String text,
      int maxLength,
      ) {
    final value = text.trim();

    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength - 3)}...';
  }
}

// =============================================================
// PRINTER BILL ITEM
// =============================================================

class PrinterBillItem {
  final String name;
  final int quantity;
  final double total;

  const PrinterBillItem({
    required this.name,
    required this.quantity,
    required this.total,
  });
}