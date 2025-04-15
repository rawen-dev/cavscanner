import 'dart:convert';
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
        ],
      ),
      body: ListView.builder(
        itemCount: exhibitions.length,
        itemBuilder: (context, index) {
          final exhibition = exhibitions[index];
          return ListTile(
            title: Text(exhibition.title),
            subtitle: Text(
              "Fotografií: ${exhibition.pictures.length} – Poslední sken: ${_formatDate(exhibition.lastScan, context)}",
            ),
            onTap: () async {
              final updatedExhibition = await Navigator.push<Exhibition>(
                context,
                MaterialPageRoute(
                  builder: (context) => ExhibitionDetailPage(exhibition: exhibition),
                ),
              );
              if (updatedExhibition != null) {
                setState(() {
                  exhibitions[index] = updatedExhibition;
                });
                _saveExhibitions();
              }
            },
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
