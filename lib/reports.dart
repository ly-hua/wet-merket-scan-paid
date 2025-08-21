// lib/reports.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReportsPage extends StatefulWidget { const ReportsPage({super.key}); @override State<ReportsPage> createState()=>_ReportsPageState(); }
class _ReportsPageState extends State<ReportsPage> {
  DateTime day = DateTime.now();
  String storeFilter = '';
  String collectorFilter = '';
  List<Map<String, Object?>> rows = [];

  Future<void> _load() async {
    final d = await AppDB.db;
    final sdate = DateFormat('yyyy-MM-dd').format(day);
    final stores = await d.query('stores');
    final pays = await d.query('payments', where:'sdate=?', whereArgs:[sdate]);
    final payByStore = { for (final p in pays) p['store_id']: p };
    rows = stores.map((s){
      final p = payByStore[s['stallid']];
      return {
        'sdate': sdate,
        'store_id': s['stallid'],
        'store_name': s['name'],
        'owner': s['owner'],
        'group': s['grp'],
        'status': p==null ? 'Unpaid':'Paid',
        'amount': p?['amount'] ?? 0,
        'timestamp': p?['ts'] ?? '',
        'note': p?['note'] ?? '',
        'collector': p?['collector'] ?? '',
      };
    }).where((r){
      final okName = storeFilter.isEmpty || r['store_name'].toString().toLowerCase().contains(storeFilter.toLowerCase());
      final okCol = collectorFilter.isEmpty || r['collector'].toString()==collectorFilter;
      return okName && okCol;
    }).toList();
    setState((){});
  }

  @override void initState(){ super.initState(); _load(); }

  Future<void> _exportCSV({DateTime? from, DateTime? to}) async {
    final d = await AppDB.db;
    final f = DateFormat('yyyy-MM-dd');
    final start = f.format(from ?? day);
    final end = f.format(to ?? day);
    final data = <List<dynamic>>[
      ['sdate','store_id','store_name','owner','group','status','amount','timestamp','note','collector'],
    ];

    // build per day within range
    DateTime cur = from ?? day;
    while (!cur.isAfter(to ?? day)) {
      final sd = f.format(cur);
      final stores = await d.query('stores', orderBy: 'stallid');
      final pays = await d.query('payments', where:'sdate=?', whereArgs:[sd]);
      final byId = { for (final p in pays) p['store_id']: p };
      for (final s in stores) {
        final p = byId[s['stallid']];
        data.add([sd,s['stallid'],s['name'],s['owner'],s['grp'], p==null?'Unpaid':'Paid', p?['amount']??0, p?['ts']??'', p?['note']??'', p?['collector']??'']);
      }
      cur = cur.add(const Duration(days: 1));
    }

    final csv = const ListToCsvConverter().convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/report_${start}_to_${end}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Daily report $start to $end');
  }

  @override
  Widget build(_) => Scaffold(
    appBar: AppBar(title: const Text('Reports')),
    body: Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          TextButton(onPressed: () async {
            final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: day);
            if (picked!=null) { setState(()=>day=picked); _load(); }
          }, child: Text(DateFormat.yMMMEd().format(day))),
          const SizedBox(width: 8),
          SizedBox(
            width: 280,
            child: TextField(
              decoration: const InputDecoration(labelText:'Filter by store name'),
              onChanged: (v){ storeFilter=v; _load(); },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            hint: const Text('Collector'),
            value: collectorFilter.isEmpty ? null : collectorFilter,
            items: [const DropdownMenuItem(value:'Collector A', child: Text('Collector A'))],
            onChanged: (v){ collectorFilter = v ?? ''; _load(); },
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: ()=>_exportCSV(), child: const Text('Export Day CSV')),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () async {
            final start = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: day);
            if (start==null) return;
            final end = await showDatePicker(context: context, firstDate: start, lastDate: DateTime(2100), initialDate: start);
            if (end==null) return;
            await _exportCSV(from: start, to: end);
          }, child: const Text('Export Range CSV')),
        ]),
      ),
      const Divider(height: 1),
      Expanded(child: ListView(
        children: rows.map((r) => ListTile(
          leading: Icon(r['status']=='Paid'? Icons.check_circle: Icons.cancel, color: r['status']=='Paid'? Colors.green: Colors.red),
          title: Text('${r['store_id']} • ${r['store_name']}'),
          subtitle: Text('Owner: ${r['owner']} | Group: ${r['group']} | Amount: ${r['amount']} | Note: ${r['note']}'),
          trailing: Text(r['status'].toString()),
        )).toList(),
      ))
    ]),
  );
}
