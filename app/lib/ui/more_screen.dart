import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
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
    final s = S.of(context);
    final status = state.useLocalInterpretation ? s.statusLocal : state.serverReachable ? s.statusConnected : s.statusDisconnected;
    return Scaffold(
      appBar: AppBar(title: Text(s.more)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _tile(context, Icons.star_border, s.zodiac, s.zodiacSub, const ZodiacScreen()),
              _tile(context, Icons.favorite_outline, s.marriage, s.marriageSub, const MarriageScreen()),
              _tile(context, Icons.text_fields, s.naming, s.namingSub, const NamingScreen()),
              _tile(context, Icons.back_hand_outlined, s.palmAi, s.palmSub, const VisionScreen(mode: VisionMode.palm)),
              _tile(context, Icons.face_outlined, s.faceAi, s.faceSub, const VisionScreen(mode: VisionMode.face)),
              const Divider(),
              _tile(context, Icons.settings_outlined, s.settings, s.settingsSub(status), const SettingsScreen()),
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
