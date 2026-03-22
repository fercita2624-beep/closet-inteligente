import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/armario_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/outfit_screen.dart';

void main() { runApp(const ClosetApp()); }

class ClosetApp extends StatelessWidget {
  const ClosetApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Closet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: ColorScheme.dark(primary: const Color(0xFF9C27B0), secondary: const Color(0xFF7E57C2), surface: const Color(0xFF1A1A2E)),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final List<Widget> _screens = const [HomeScreen(), ArmarioScreen(), OutfitScreen(), ScanScreen(), HistorialScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFF9C27B0).withValues(alpha: 0.3),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny, color: Color(0xFFCE93D8)), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.checkroom_outlined), selectedIcon: Icon(Icons.checkroom, color: Color(0xFFCE93D8)), label: 'Armario'),
          NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style, color: Color(0xFFCE93D8)), label: 'Outfit'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt, color: Color(0xFFCE93D8)), label: 'Escanear'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history, color: Color(0xFFCE93D8)), label: 'Historial'),
        ],
      ),
    );
  }
}
