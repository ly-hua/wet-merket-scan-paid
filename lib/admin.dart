// lib/admin.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'db.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
// import 'dart:typed_data';
import 'package:flutter/rendering.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, Object?>> stores = [];
  final _repaintKey = GlobalKey();

  Future<void> _load() async {
    final d = await AppDB.db;
    stores = await d.query('stores', orderBy: 'stallid');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _saveStore({Map<String, Object?>? existing}) async {
    final idC = TextEditingController(
      text: existing?['stallid']?.toString() ?? '',
    );
    final nameC = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final ownerC = TextEditingController(
      text: existing?['owner']?.toString() ?? '',
    );
    final grpC = TextEditingController(
      text: existing?['grp']?.toString() ?? '',
    );
    final amtC = TextEditingController(
      text: existing?['defaultAmount']?.toString() ?? '',
    );
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Store' : 'Edit Store'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: idC,
                decoration: const InputDecoration(labelText: 'Stall ID'),
              ),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: ownerC,
                decoration: const InputDecoration(labelText: 'Owner'),
              ),
              TextField(
                controller: grpC,
                decoration: const InputDecoration(labelText: 'Group'),
              ),
              TextField(
                controller: amtC,
                decoration: const InputDecoration(labelText: 'Default Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final d = await AppDB.db;
              final data = {
                'stallid': idC.text,
                'name': nameC.text,
                'owner': ownerC.text,
                'grp': grpC.text,
                'defaultAmount': int.tryParse(amtC.text) ?? 0,
              };
              if (existing == null) {
                await d.insert('stores', data);
              } else {
                await d.update(
                  'stores',
                  data,
                  where: 'stallid=?',
                  whereArgs: [existing['stallid']],
                );
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    await _load();
  }

  Future<void> _delete(String stallid) async {
    final d = await AppDB.db;
    await d.delete('stores', where: 'stallid=?', whereArgs: [stallid]);
    await _load();
  }

  Future<void> _showQR(String stallid) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('QR: $stallid'),
        content: SizedBox(
          width: 240,
          height: 260,
          child: Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: QrImageView(
                  data: stallid,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              // export QR as image and share (user can choose Print in the sheet)
              final boundary =
                  _repaintKey.currentContext!.findRenderObject()
                      as RenderRepaintBoundary;
              final img = await boundary.toImage(pixelRatio: 3);
              final bytes = await img.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final data = bytes!.buffer.asUint8List();

              // On device, use path_provider to save to temp; here just share from memory:
              await Share.shareXFiles([
                XFile.fromData(
                  data,
                  name: 'qr_$stallid.png',
                  mimeType: 'image/png',
                ),
              ]);
            },
            child: const Text('Share/Print'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(_) => Scaffold(
    appBar: AppBar(title: const Text('Admin — Stores')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _saveStore(),
      child: const Icon(Icons.add),
    ),
    body: ListView.builder(
      itemCount: stores.length,
      itemBuilder: (_, i) {
        final s = stores[i];
        return ListTile(
          title: Text('${s['stallid']} • ${s['name']}'),
          subtitle: Text(
            'Owner: ${s['owner']}  | Group: ${s['grp']}  | Default: ${s['defaultAmount']}',
          ),
          trailing: Wrap(
            spacing: 8,
            children: [
              IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: () => _showQR(s['stallid'] as String),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _saveStore(existing: s),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _delete(s['stallid'] as String),
              ),
            ],
          ),
        );
      },
    ),
  );
}
