import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final List<String> scannedItems = [];
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.all],
    torchEnabled: true
  );

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    if (kIsWeb) {
      MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(
        "https://unpkg.com/@zxing/library@0.21.3",
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && !scannedItems.contains(code)) {
        setState(() {
          scannedItems.add(code);
        });
      }
    }
  }

  // The user must end and save the scanning explicitly.
  void _endAndSave() {
    Navigator.pop(context, scannedItems);
  }

  // Disable system back navigation to force the user to save scans.
  Future<bool> _onWillPop() async {
    // Optionally show a dialog warning that scans will be lost.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Režim skenování"),
          automaticallyImplyLeading: false,
          actions: [
            // Torch toggle button.
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                return IconButton(
                  icon: Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                  ),
                  onPressed: () => controller.toggleTorch(),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Scanning view area.
            Expanded(
              flex: 2,
              child: MobileScanner(
                controller: controller,
                onDetect: _onDetect,
              ),
            ),
            // List of scanned items.
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Naskenované položky:"),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: scannedItems.length,
                      itemBuilder: (context, index) {
                        final item = scannedItems[index];
                        return ListTile(
                          title: Text(item),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                scannedItems.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Always-visible, large "End and Save" button at bottom.
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _endAndSave,
            icon: const Icon(Icons.check),
            label: const Text("Ukončit a uložit"),
          ),
        ),
      ),
    );
  }
}
