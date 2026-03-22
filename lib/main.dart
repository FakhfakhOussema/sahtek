import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'providers/app_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/friends_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

// ⚠️ Remplace ces valeurs par celles de TON projet Supabase
// (Settings → API dans le dashboard Supabase)
const _supabaseUrl     = 'https://izpdhbgzmpptwpglkjxr.supabase.co';
const _supabaseAnonKey = 'sb_publishable_kjLmwKPGmVDV2697Ngq6VQ_KPG24pVg';

tz.Location _resolveLocalTimezone() {
  final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
  try {
    for (final name in tz.timeZoneDatabase.locations.keys) {
      final loc = tz.timeZoneDatabase.locations[name]!;
      final now = tz.TZDateTime.now(loc);
      if (now.timeZoneOffset.inMinutes == offsetMinutes) return loc;
    }
  } catch (_) {}
  return tz.UTC;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
  ]);
  tz.initializeTimeZones();
  tz.setLocalLocation(_resolveLocalTimezone());
  await initializeDateFormatting('fr_FR', null);
  await NotificationService.instance.init();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(ChangeNotifierProvider(create: (_) => AppProvider(), child: const SahtekApp()));
}

class SahtekApp extends StatelessWidget {
  const SahtekApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sahtek', debugShowCheckedModeBanner: false,
    theme: AppTheme.theme, home: const _AuthGate(),
  );
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
      if (data.event == AuthChangeEvent.signedIn) {
        context.read<AppProvider>().syncFromCloud();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return session == null ? const AuthScreen() : const _RootNav();
  }
}

class _RootNav extends StatefulWidget {
  const _RootNav();
  @override
  State<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<_RootNav> {
  int _index = 0;
  static const _screens = [HomeScreen(), DashboardScreen(), FriendsScreen()];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: _screens),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded), label: 'Journée'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded), label: 'Amis'),
      ],
    ),
  );
}