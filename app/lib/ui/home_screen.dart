import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    if (state.active == null) {
      return const BirthInputScreen(firstRun: true);
    }

    final pages = const [ChartScreen(), FortuneScreen(), AlmanacScreen(), MoreScreen()];
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
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: Text('命盘')),
                NavigationRailDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny), label: Text('运势')),
                NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('黄历')),
                NavigationRailDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: Text('更多')),
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: '命盘'),
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny), label: '运势'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: '黄历'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: '更多'),
        ],
      ),
    );
  }
}
