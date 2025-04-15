import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exhibition.dart';
import 'scan_page.dart';

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
    final titles = exhibition.pictures.join('\n');
    Clipboard.setData(ClipboardData(text: titles));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tituly byly zkopírovány")),
    );
  }

  Future<void> _startScanning() async {
    final scannedItems = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanPage(),
      ),
    );
    if (scannedItems != null && scannedItems.isNotEmpty) {
      setState(() {
        exhibition.pictures.addAll(scannedItems);
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
    bool confirmed = await _confirmDeletion("Opravdu chcete smazat celou výstavu '${exhibition.title}'?");
    if (confirmed) {
      Navigator.pop(context, null); // Return null to signal deletion of the exhibition
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // When back button is pressed, return the updated exhibition.
      // If the exhibition was deleted, null is returned.
      onWillPop: () async {
        Navigator.pop(context, exhibition);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Výstava: ${exhibition.title}"),
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
              child: ListView.builder(
                itemCount: exhibition.pictures.length,
                itemBuilder: (context, index) {
                  final title = exhibition.pictures[index];
                  return ListTile(
                    title: Text(title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removePicture(index),
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
