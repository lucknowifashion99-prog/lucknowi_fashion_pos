import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../services/printer_service.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final PrinterService _printerService = PrinterService.instance;

  List<BluetoothInfo> _printers = [];

  BluetoothInfo? _selectedPrinter;

  bool _loading = false;
  bool _connected = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  // =========================================================
  // LOAD PAIRED BLUETOOTH PRINTERS
  // =========================================================

  Future<void> _loadPrinters() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final printers = await _printerService.getPrinters();

      if (!mounted) return;

      setState(() {
        _printers = printers;

        if (_selectedPrinter != null) {
          final exists = printers.any(
                (printer) =>
            printer.macAdress == _selectedPrinter!.macAdress,
          );

          if (!exists) {
            _selectedPrinter = null;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Printer list load nahi ho saki.',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // =========================================================
  // SELECT PRINTER
  // =========================================================

  void _selectPrinter(BluetoothInfo printer) {
    setState(() {
      _selectedPrinter = printer;
    });

    _printerService.selectPrinter(printer);
  }

  // =========================================================
  // CONNECT
  // =========================================================

  Future<void> _connectPrinter() async {
    if (_selectedPrinter == null) {
      _showMessage(
        'Pehle Bluetooth printer select karo.',
        isError: true,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final connected = await _printerService.connect();

      if (!mounted) return;

      setState(() {
        _connected = connected;
      });

      if (connected) {
        _showMessage(
          'Printer connected successfully.',
        );
      } else {
        _showMessage(
          'Printer connect nahi ho saka.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Connection failed: $e',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // =========================================================
  // DISCONNECT
  // =========================================================

  Future<void> _disconnectPrinter() async {
    setState(() {
      _loading = true;
    });

    try {
      await _printerService.disconnect();

      if (!mounted) return;

      setState(() {
        _connected = false;
      });

      _showMessage(
        'Printer disconnected.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Disconnect failed.',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // =========================================================
  // TEST PRINT
  // =========================================================

  Future<void> _testPrint() async {
    if (_selectedPrinter == null) {
      _showMessage(
        'Pehle printer select karo.',
        isError: true,
      );
      return;
    }

    setState(() {
      _testing = true;
    });

    try {
      final result = await _printerService.printTest();

      if (!mounted) return;

      if (result) {
        setState(() {
          _connected = true;
        });

        _showMessage(
          'Test print command sent successfully.',
        );
      } else {
        _showMessage(
          'Test print failed.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Test print failed: $e',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _testing = false;
      });
    }
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
  // DEVICE NAME
  // =========================================================

  String _deviceName(BluetoothInfo device) {
    final name = device.name.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'Unknown Printer';
  }

  // =========================================================
  // DEVICE ADDRESS
  // =========================================================

  String _deviceAddress(BluetoothInfo device) {
    final address = device.macAdress.trim();

    if (address.isNotEmpty) {
      return address;
    }

    return 'Address unavailable';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bluetooth Printer',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
            _loading ? null : _loadPrinters,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPrinters,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // =================================================
            // STATUS CARD
            // =================================================

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _connected
                            ? Colors.green.withOpacity(.12)
                            : Colors.grey.withOpacity(.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _connected
                            ? Icons.print
                            : Icons.print_disabled,
                        size: 28,
                        color: _connected
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Printer Status',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _connected
                                ? 'Connected'
                                : 'Not Connected',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                              color: _connected
                                  ? Colors.green
                                  : Colors.red,
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
            // PAPER SIZE
            // =================================================

            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(
                  Icons.receipt_long,
                ),
                title: const Text(
                  'Paper Size',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Shreyans CD410 thermal receipt',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(.1),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '58 mm',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // TITLE
            // =================================================

            const Text(
              'Paired Bluetooth Printers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Windows Bluetooth settings me printer ko pehle pair karein.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            // =================================================
            // LOADING
            // =================================================

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // =================================================
            // NO PRINTER
            // =================================================

            if (!_loading && _printers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 50,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No paired printer found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Shreyans CD410 ko Windows Bluetooth settings se pair karke Refresh dabayein.',
                        textAlign:
                        TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // =================================================
            // PRINTER LIST
            // =================================================

            ..._printers.map(
                  (printer) {
                final selected =
                    _selectedPrinter?.macAdress ==
                        printer.macAdress;

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    onTap: _loading
                        ? null
                        : () {
                      _selectPrinter(
                        printer,
                      );
                    },
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.print,
                      ),
                    ),
                    title: Text(
                      _deviceName(printer),
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _deviceAddress(printer),
                    ),
                    trailing: selected
                        ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    )
                        : const Icon(
                      Icons.radio_button_unchecked,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // =================================================
            // CONNECT BUTTON
            // =================================================

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                _loading ||
                    _selectedPrinter == null
                    ? null
                    : _connected
                    ? _disconnectPrinter
                    : _connectPrinter,
                icon: Icon(
                  _connected
                      ? Icons.bluetooth_disabled
                      : Icons.bluetooth_connected,
                ),
                label: Text(
                  _connected
                      ? 'DISCONNECT PRINTER'
                      : 'CONNECT PRINTER',
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =================================================
            // TEST PRINT
            // =================================================

            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed:
                _testing ||
                    _selectedPrinter == null
                    ? null
                    : _testPrint,
                icon: _testing
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.print,
                ),
                label: Text(
                  _testing
                      ? 'PRINTING...'
                      : 'TEST PRINT - 58mm',
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // INFO
            // =================================================

            Card(
              color: Colors.blue.withOpacity(.06),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Shreyans CD410 ke liye 58mm compact ESC/POS receipt format use kiya ja raha hai.',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =================================================
            // SELECTED PRINTER
            // =================================================

            if (_selectedPrinter != null)
              Card(
                child: Padding(
                  padding:
                  const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Printer',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _deviceName(
                          _selectedPrinter!,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _deviceAddress(
                          _selectedPrinter!,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}