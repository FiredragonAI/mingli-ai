import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/cities.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
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
    final s = S.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(s.language, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              // 语言名永远用该语言自己的写法,不跟着界面翻译
              SegmentedButton<AppLanguage>(
                segments: [for (final l in AppLanguage.values) ButtonSegment(value: l, label: Text(l.nativeName))],
                selected: {state.language},
                onSelectionChanged: (v) => state.setLanguage(v.first),
              ),
              const SizedBox(height: 24),
              Text(s.profiles, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              RadioGroup<int>(
                groupValue: state.activeIndex,
                onChanged: (v) => state.setActive(v!),
                child: Column(
                  children: [
                    for (var i = 0; i < state.profiles.length; i++)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Radio<int>(value: i),
                          title: Text(state.profiles[i].name.isEmpty
                              ? '${s.term(state.profiles[i].gender.chartLabel)} ${state.profiles[i].year}-${state.profiles[i].month}-${state.profiles[i].day}'
                              : state.profiles[i].name),
                          subtitle: Text(
                              '${s.en ? cityEnglish(state.profiles[i].placeName) : s.text(state.profiles[i].placeName)} · ${state.profiles[i].hour.toString().padLeft(2, '0')}:${state.profiles[i].minute.toString().padLeft(2, '0')}'),
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
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BirthInputScreen())),
                icon: const Icon(Icons.add),
                label: Text(s.addProfile),
              ),
              const SizedBox(height: 24),
              Text(s.readingService, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(s.forceLocalTitle),
                subtitle: Text(s.forceLocalSub),
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
                      labelText: s.serverUrl,
                      helperText: state.useLocalInterpretation
                          ? s.serverDisabledHint
                          : state.serverReachable
                              ? s.statusConnected
                              : s.statusDisconnected,
                      suffixIcon: IconButton(icon: const Icon(Icons.check), onPressed: () => state.setServerUrl(_url.text)),
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
                    label: Text(s.resetUrl),
                  ),
                ),
              const SizedBox(height: 24),
              Text(s.privacy, style: theme.textTheme.titleMedium),
              SwitchListTile(
                title: Text(s.consentTitle),
                subtitle: Text(s.consentSub),
                value: state.biometricConsent,
                onChanged: (v) async {
                  if (v) {
                    await state.grantBiometricConsent();
                  } else {
                    await state.revokeBiometricConsent();
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(s.about, style: theme.textTheme.titleMedium),
              ListTile(title: Text('${s.appTitle} 0.1.0'), subtitle: Text(s.aboutSub)),
            ],
          ),
        ),
      ),
    );
  }
}
