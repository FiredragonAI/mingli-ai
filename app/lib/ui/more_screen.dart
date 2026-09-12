import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import 'marriage_screen.dart';
import 'naming_screen.dart';
import 'settings_screen.dart';
import 'vision_screen.dart';
import 'zodiac_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('更多')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _tile(context, Icons.star_border, '星座', '太阳星座 · 上升星座 · 配对', const ZodiacScreen()),
              _tile(context, Icons.favorite_outline, '合婚', '两人八字六维匹配 · 星座配对', const MarriageScreen()),
              _tile(context, Icons.text_fields, '姓名测试', '五格剖象 · 三才 · 八字补益', const NamingScreen()),
              _tile(context, Icons.back_hand_outlined, '手相 AI', '照片仅在本机分析', const VisionScreen(mode: VisionMode.palm)),
              _tile(context, Icons.face_outlined, '面相 AI', '三停五眼 · 十二宫', const VisionScreen(mode: VisionMode.face)),
              const Divider(),
              _tile(
                context,
                Icons.settings_outlined,
                '设置',
                '档案管理 · 解读服务 '
                    '${state.useLocalInterpretation ? '离线本地' : state.serverReachable ? '已连接' : '未连接'}',
                const SettingsScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, Widget page) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      );
}
