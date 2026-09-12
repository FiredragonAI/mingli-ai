import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../core/naming/name_analysis.dart';
import '../core/naming/numerology.dart';
import '../l10n/strings.dart';
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
      _analyze(silent: true);
    }
  }

  void _analyze({bool silent = false}) {
    final name = _ctrl.text.trim();
    if (name.length < 2 || name.length > 6) {
      if (!silent) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S(context.read<AppState>().language).nameLengthError)));
      return;
    }
    setState(() => _result = analyzeName(name, chart: context.read<AppState>().chart));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final r = _result;
    final chart = context.watch<AppState>().chart;
    return Scaffold(
      appBar: AppBar(title: Text(s.naming)),
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
                      decoration: InputDecoration(labelText: s.name, hintText: s.nameHint),
                      onSubmitted: (_) => _analyze(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _analyze, child: Text(s.analyze)),
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
                        Text(s.text(r.summary), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                        if (r.unknownChars.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(s.unknownCharsHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
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
                          title: Text('${s.term(g.name)} · ${s.text(g.meaning.title)} · ${s.term(g.meaning.luck.label)}'),
                          subtitle: Text('${s.text(g.meaning.text)}\n${s.text(g.domain)}', style: theme.textTheme.bodySmall),
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
                        Text(s.sanCai(s.text(r.sanCaiText), r.sanCaiScore), style: theme.textTheme.titleSmall),
                        Text(s.text(r.sanCaiComment), style: theme.textTheme.bodySmall),
                        if (r.elementNotes.isNotEmpty) ...[
                          const Divider(),
                          Text(s.chartBalance, style: theme.textTheme.titleSmall),
                          for (final n in r.elementNotes) Text('· ${s.text(n)}', style: theme.textTheme.bodySmall),
                        ],
                        if (r.zodiacNotes.isNotEmpty) ...[
                          const Divider(),
                          Text(s.zodiacChars, style: theme.textTheme.titleSmall),
                          for (final n in r.zodiacNotes) Text('· ${s.text(n)}', style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AiReadingCard(
                  title: s.aiName,
                  load: (api) => api.interpretName(r.toJson(), chart?.toJson()),
                  localText: () => s.en ? enInterpretName(r) : localInterpretName(r),
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
