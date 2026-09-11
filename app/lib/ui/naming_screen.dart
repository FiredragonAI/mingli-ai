import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/interpret/local_interpreter.dart';
import '../core/naming/name_analysis.dart';
import '../core/naming/numerology.dart';
import '../services/app_state.dart';
import 'theme.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';

class NamingScreen extends StatefulWidget {
  const NamingScreen({super.key});

  @override
  State<NamingScreen> createState() => _NamingScreenState();
}

class _NamingScreenState extends State<NamingScreen> {
  final _ctrl = TextEditingController();
  NameAnalysis? _result;

  @override
  void initState() {
    super.initState();
    final name = context.read<AppState>().active?.name ?? '';
    if (name.length >= 2) {
      _ctrl.text = name;
      _analyze();
    }
  }

  void _analyze() {
    final name = _ctrl.text.trim();
    if (name.length < 2 || name.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入 2–6 个汉字的姓名')));
      return;
    }
    setState(() => _result = analyzeName(name, chart: context.read<AppState>().chart));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _result;
    final chart = context.watch<AppState>().chart;
    return Scaffold(
      appBar: AppBar(title: const Text('姓名测试')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(labelText: '姓名', hintText: '如:李思晨'),
                      onSubmitted: (_) => _analyze(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _analyze, child: const Text('测算')),
                ],
              ),
              if (r != null) ...[
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(r.fullName, style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 6)),
                        Text(r.strokes.join(' · '), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        const SizedBox(height: 8),
                        Text('${r.overallScore}', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                        Text(r.summary, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                        if (r.unknownChars.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('提示:完整康熙笔画字典未加载,生僻字按 0 画计', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final g in [r.tian, r.ren, r.di, r.wai, r.zong])
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: elementColor[g.element.label],
                            foregroundColor: Colors.white,
                            child: Text('${g.number}'),
                          ),
                          title: Text('${g.name} · ${g.meaning.title} · ${g.meaning.luck.label}'),
                          subtitle: Text('${g.meaning.text}\n${g.domain}', style: theme.textTheme.bodySmall),
                          trailing: Icon(
                            switch (g.meaning.luck) {
                              Luck.auspicious => Icons.check_circle_outline,
                              Luck.half => Icons.remove_circle_outline,
                              Luck.inauspicious => Icons.cancel_outlined,
                            },
                            color: switch (g.meaning.luck) {
                              Luck.auspicious => AppColors.jade,
                              Luck.half => AppColors.gold,
                              Luck.inauspicious => theme.colorScheme.error,
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('三才 ${r.sanCaiText} · ${r.sanCaiScore} 分', style: theme.textTheme.titleSmall),
                        Text(r.sanCaiComment, style: theme.textTheme.bodySmall),
                        if (r.elementNotes.isNotEmpty) ...[
                          const Divider(),
                          Text('八字补益', style: theme.textTheme.titleSmall),
                          for (final n in r.elementNotes) Text('· $n', style: theme.textTheme.bodySmall),
                        ],
                        if (r.zodiacNotes.isNotEmpty) ...[
                          const Divider(),
                          Text('生肖用字', style: theme.textTheme.titleSmall),
                          for (final n in r.zodiacNotes) Text('· $n', style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AiReadingCard(
                  title: 'AI 姓名解读',
                  load: (api) => api.interpretName(r.toJson(), chart?.toJson()),
                  localText: () => localInterpretName(r),
                ),
              ],
              const Disclaimer(),
            ],
          ),
        ),
      ),
    );
  }
}
