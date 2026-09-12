import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'almanac_screen.dart';
import 'birth_input_screen.dart';
import 'chart_screen.dart';
import 'fortune_screen.dart';
import 'more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    if (state.active == null) {
      return const BirthInputScreen(firstRun: true);
    }

    const pages = [ChartScreen(), FortuneScreen(), AlmanacScreen(), MoreScreen()];
    final wide = MediaQuery.sizeOf(context).width >= 800;

    if (wide) {
      // Windows 桌面:左侧导航栏
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('命', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              ),
              destinations: [
                NavigationRailDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view), label: Text(s.navChart)),
                NavigationRailDestination(icon: const Icon(Icons.wb_sunny_outlined), selectedIcon: const Icon(Icons.wb_sunny), label: Text(s.navFortune)),
                NavigationRailDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: Text(s.navAlmanac)),
                NavigationRailDestination(icon: const Icon(Icons.more_horiz), selectedIcon: const Icon(Icons.more_horiz), label: Text(s.navMore)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view), label: s.navChart),
          NavigationDestination(icon: const Icon(Icons.wb_sunny_outlined), selectedIcon: const Icon(Icons.wb_sunny), label: s.navFortune),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: s.navAlmanac),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: s.navMore),
        ],
      ),
    );
  }
}
