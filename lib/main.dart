// lib/main.dart
import 'package:flutter/material.dart';
import 'db.dart';
import 'admin.dart';
import 'collector.dart';
import 'reports.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDB.db; // ensure init + seed
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Scan & Mark Paid', home: const Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int i = 0;
  final pages = const [AdminPage(), CollectorPage(), ReportsPage()];
  @override
  Widget build(_) => Scaffold(
    body: pages[i],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: i,
      onTap: (v) => setState(() => i = v),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Admin'),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Collector',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Reports'),
      ],
    ),
  );
}
