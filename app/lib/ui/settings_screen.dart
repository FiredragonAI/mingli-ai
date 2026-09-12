import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import 'birth_input_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _url;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: context.read<AppState>().serverUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('档案', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < state.profiles.length; i++)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Radio<int>(value: i, groupValue: state.activeIndex, onChanged: (v) => state.setActive(v!)),
                    title: Text(state.profiles[i].name.isEmpty ? '${state.profiles[i].gender.chartLabel} ${state.profiles[i].year}-${state.profiles[i].month}-${state.profiles[i].day}' : state.profiles[i].name),
                    subtitle: Text('${state.profiles[i].placeName} · ${state.profiles[i].hour.toString().padLeft(2, '0')}:${state.profiles[i].minute.toString().padLeft(2, '0')}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BirthInputScreen(initial: state.profiles[i], editIndex: i))),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: state.profiles.length <= 1 ? null : () => state.removeProfile(i),
                        ),
                      ],
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BirthInputScreen())),
                icon: const Icon(Icons.add),
                label: const Text('新增档案'),
              ),
              const SizedBox(height: 24),
              Text('解读服务', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('始终使用离线本地解读'),
                subtitle: const Text('开:一律由本机规则引擎生成,不联网。'
                    '关:能连上云端就用 AI,连不上时自动改用本机生成,不会空白。'),
                value: state.useLocalInterpretation,
                onChanged: (v) => state.setUseLocalInterpretation(v),
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: state.useLocalInterpretation ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: state.useLocalInterpretation,
                  child: TextField(
                    controller: _url,
                    decoration: InputDecoration(
                      labelText: '云端服务器地址',
                      helperText: state.useLocalInterpretation
                          ? '已切换到离线本地解读,此项暂不生效'
                          : state.serverReachable
                              ? '已连接'
                              : '未连接',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () => state.setServerUrl(_url.text),
                      ),
                    ),
                    onSubmitted: state.setServerUrl,
                  ),
                ),
              ),
              if (!state.isDefaultServerUrl && !state.useLocalInterpretation)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await state.resetServerUrl();
                      _url.text = state.serverUrl;
                    },
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('恢复默认地址'),
                  ),
                ),
              const SizedBox(height: 24),
              Text('隐私', style: theme.textTheme.titleMedium),
              SwitchListTile(
                title: const Text('允许在本机处理手掌/面部照片'),
                subtitle: const Text('关闭后手相、面相功能将再次征求同意'),
                value: state.biometricConsent,
                onChanged: (v) async {
                  if (v) {
                    await state.grantBiometricConsent();
                  } else {
                    // 撤回同意
                    await state.revokeBiometricConsent();
                  }
                },
              ),
              const SizedBox(height: 24),
              Text('关于', style: theme.textTheme.titleMedium),
              const ListTile(
                title: Text('命理师 AI 0.1.0'),
                subtitle: Text('排盘在本机完成;解读文字由 AI 生成,仅供娱乐参考。'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
