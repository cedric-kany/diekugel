import 'package:die_kugel/pages/ble_scan.dart';
import 'package:die_kugel/pages/documentation.dart';
import 'package:die_kugel/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
      ),
      routes: {
        '/': (context) => const MainScreen(),
        '/ble-device-scan': (context) => const BLEDeviceScanPage(),
      },
      title: "Die Kugel",
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? _selectedIndex;
  final List<Widget> _buildBody = [
    const HomeScreen(),
    const DocumentationScreen()
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 125, 171, 187),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 32,
        leading: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/ble-device-scan'),
          icon: const Icon(
            Icons.bluetooth,
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44.0),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.grey[900],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[700],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 28,
          currentIndex: _selectedIndex!,
          onTap: (index) => setState(() {
            _selectedIndex = index;
          }),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.animation),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              label: "",
            ),
          ],
        ),
      ),
      body: DefaultTextStyle(
        style: GoogleFonts.robotoMono(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        child: _buildBody[_selectedIndex!],
      ),
    );
  }
}
