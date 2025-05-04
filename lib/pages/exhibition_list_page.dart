// lib/pages/exhibition_list_page.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exhibition.dart';
import '../helpers/storage_helper.dart';
import 'exhibition_detail_page.dart';
import 'install_page.dart';

class ExhibitionListPage extends StatefulWidget {
  const ExhibitionListPage({Key? key}) : super(key: key);

  @override
  _ExhibitionListPageState createState() => _ExhibitionListPageState();
}

class _ExhibitionListPageState extends State<ExhibitionListPage> {
  List<Exhibition> exhibitions = [];

  @override
  void initState() {
    super.initState();
    _loadExhibitions();
  }

  Future<void> _loadExhibitions() async {
    String? data = await StorageHelper.get('exhibitions');
    if (data != null) {
      List<dynamic> list = json.decode(data);
      exhibitions = list.map((e) => Exhibition.fromMap(e)).toList();
    }
    setState(() {});
  }

  Future<void> _saveExhibitions() async {
    List<Map<String, dynamic>> list = exhibitions.map((e) => e.toMap()).toList();
    await StorageHelper.set('exhibitions', json.encode(list));
  }

  Future<void> _addExhibition() async {
    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Přidat novou výstavu"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Název výstavy",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Zrušit"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newExhibition = Exhibition(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: controller.text,
                  pictures: [],
                  lastScan: null,
                );
                setState(() {
                  exhibitions.add(newExhibition);
                });
                _saveExhibitions();
                Navigator.pop(context);
              }
            },
            child: const Text("Uložit"),
          ),
        ],
      ),
    );
  }

  Future<void> _seedSampleExhibitions() async {
    final now = DateTime.now();
    final random = Random();
    final sample = List.generate(5, (i) {
      final count = random.nextInt(5) + 3;
      final pictures = List.generate(count, (j) => "2024/${100 + j + i * 10}");
      return Exhibition(
        id: (now.millisecondsSinceEpoch + i).toString(),
        title: "Výstava ${i + 1}",
        pictures: pictures,
        lastScan: now.subtract(Duration(days: i * 2)),
      );
    });

    setState(() {
      exhibitions = sample;
    });
    await _saveExhibitions();
  }

  String _formatDate(DateTime? date, BuildContext context) {
    if (date == null) return "-";
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).add_Hm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Výstavy"),
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.install_mobile),
              tooltip: "Instalovat aplikaci",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InstallPage()),
                );
              },
            ),
          // IconButton(
          //   icon: const Icon(Icons.bolt),
          //   tooltip: "Generovat ukázková data",
          //   onPressed: _seedSampleExhibitions,
          // ),
        ],
      ),
      body: exhibitions.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.grid_view_sharp, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Žádná výstava",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              "Klikněte na '+' pro vytvoření nové výstavy.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: exhibitions.length,
        itemBuilder: (context, index) {
          final exhibition = exhibitions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.grid_view_sharp),
              title: Text(exhibition.title),
              subtitle: Text(
                "Fotografií: ${exhibition.pictures.length} – Poslední sken: ${_formatDate(exhibition.lastScan, context)}",
              ),
              onTap: () async {
                final updatedExhibition = await Navigator.push<Exhibition?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ExhibitionDetailPage(exhibition: exhibition),
                  ),
                );
                if (updatedExhibition == null) {
                  setState(() {
                    exhibitions.removeAt(index);
                  });
                  await _saveExhibitions();
                } else {
                  setState(() {
                    exhibitions[index] = updatedExhibition;
                  });
                  await _saveExhibitions();
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExhibition,
        tooltip: "Přidat novou výstavu",
        child: const Icon(Icons.add),
      ),
    );
  }
}
