// lib/collector.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'db.dart';

class CollectorPage extends StatefulWidget {
  const CollectorPage({super.key});
  @override
  State<CollectorPage> createState() => _CollectorPageState();
}

class _CollectorPageState extends State<CollectorPage> {
  DateTime day = DateTime.now();
  String? last;
  final amtC = TextEditingController();
  final noteC = TextEditingController();
  bool isFlashOn = false;
  MobileScannerController cameraController = MobileScannerController();

  Future<void> _markPaid(String stallid) async {
    final d = await AppDB.db;
    final store = (await d.query(
      'stores',
      where: 'stallid=?',
      whereArgs: [stallid],
    )).firstOrNull;
    if (store == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unknown stall')));
      return;
    }
    amtC.text = (store['defaultAmount'] ?? 0).toString();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mark Paid: $stallid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(store['name'].toString()),
            TextField(
              controller: amtC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: noteC,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final sdate = DateFormat('yyyy-MM-dd').format(day);
              final amount = int.tryParse(amtC.text) ?? 0;
              final nowIso = DateTime.now().toIso8601String();
              final existing = await d.query(
                'payments',
                where: 'sdate=? AND store_id=?',
                whereArgs: [sdate, stallid],
              );
              if (existing.isEmpty) {
                await d.insert('payments', {
                  'sdate': sdate,
                  'store_id': stallid,
                  'status': 'Paid',
                  'amount': amount,
                  'ts': nowIso,
                  'note': noteC.text,
                  'collector': 'Collector A',
                });
              } else {
                await d.update(
                  'payments',
                  {
                    'status': 'Paid',
                    'amount': amount,
                    'ts': nowIso,
                    'note': noteC.text,
                    'collector': 'Collector A',
                  },
                  where: 'id=?',
                  whereArgs: [existing.first['id']],
                );
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        final capture = await cameraController.analyzeImage(image.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final code = capture.barcodes.first.rawValue;
          if (code != null && code != last) {
            last = code;
            _markPaid(code);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No QR code found in the image')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error scanning image')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(_) => Scaffold(
    appBar: AppBar(
      title: const Text('Collector — Scan'),
      actions: [
        IconButton(
          icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
          onPressed: () {
            setState(() {
              isFlashOn = !isFlashOn;
              cameraController.toggleTorch();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.image),
          onPressed: pickImage,
        ),
      ],
    ),
    body: Column(
      children: [
        ListTile(
          title: const Text('Select Date'),
          subtitle: Text('${DateFormat.yMMMEd().format(day)}'),
          trailing: ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: day,
              );
              if (picked != null) setState(() => day = picked);
            },
            child: const Text('Pick'),
          ),
        ),
        Expanded(
          child: MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final code = capture.barcodes.first.rawValue;
              if (code != null && code != last) {
                last = code;
                _markPaid(code);
              }
            },
          ),
        ),
      ],
    ),
  );
}
