// lib/pages/exhibition_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scan_page.dart';
import '../models/exhibition.dart';

class ExhibitionDetailPage extends StatefulWidget {
  final Exhibition exhibition;

  const ExhibitionDetailPage({Key? key, required this.exhibition}) : super(key: key);

  @override
  _ExhibitionDetailPageState createState() => _ExhibitionDetailPageState();
}

class _ExhibitionDetailPageState extends State<ExhibitionDetailPage> {
  late Exhibition exhibition;

  @override
  void initState() {
    super.initState();
    exhibition = widget.exhibition;
  }

  void _copyTitles() {
    final titles = '${exhibition.pictures.join(',')},';
    Clipboard.setData(ClipboardData(text: titles));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tituly byly zkopírovány")),
    );
  }

  Future<void> _startScanning() async {
    // Pass the existing picture codes into the ScanPage
    final scannedItems = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ScanPage(initialItems: exhibition.pictures),
      ),
    );
    if (scannedItems != null && scannedItems.isNotEmpty) {
      setState(() {
        exhibition.pictures = scannedItems;
        exhibition.lastScan = DateTime.now();
      });
    }
  }

  Future<bool> _confirmDeletion(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Potvrzení smazání"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Ne"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ano"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _removePicture(int index) async {
    bool confirmed = await _confirmDeletion("Opravdu chcete odstranit tuto fotografii?");
    if (confirmed) {
      setState(() {
        exhibition.pictures.removeAt(index);
      });
    }
  }

  Future<void> _confirmDeleteExhibition() async {
    bool confirmed = await _confirmDeletion(
        "Opravdu chcete smazat celou výstavu '${exhibition.title}'?");
    if (confirmed) {
      Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Exhibition?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, exhibition);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(exhibition.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Smazat celou výstavu",
              onPressed: _confirmDeleteExhibition,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: exhibition.pictures.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Žádné fotografie",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Stiskněte 'Skenovat' pro přidání fotek.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: exhibition.pictures.length,
                itemBuilder: (context, index) {
                  final title = exhibition.pictures[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.image),
                      title: Text(title),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removePicture(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _copyTitles,
                    child: const Text("Kopírovat tituly"),
                  ),
                  ElevatedButton(
                    onPressed: _startScanning,
                    child: const Text("Skenovat"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
