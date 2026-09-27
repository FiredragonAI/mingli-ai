import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/sbti/sbti.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'theme.dart';
import 'widgets/disclaimer.dart';

/// SBTI 玩梗测试:介绍 → 30 题逐题作答 → 结果页(可分享)。
///
/// 全程本机、确定性,不调任何 AI;它是给人截图转发用的社交货币,
/// 所以结果页刻意做成"一屏装下、一眼看懂"。
class SbtiScreen extends StatefulWidget {
  const SbtiScreen({super.key});

  @override
  State<SbtiScreen> createState() => _SbtiScreenState();
}

enum _Stage { intro, quiz, result }

class _SbtiScreenState extends State<SbtiScreen> {
  _Stage _stage = _Stage.intro;
  final List<int> _answers = [];
  SbtiResult? _result;

  void _start() => setState(() {
        _answers.clear();
        _result = null;
        _stage = _Stage.quiz;
      });

  void _answer(int option) => setState(() {
        _answers.add(option);
        if (_answers.length == sbtiQuestions.length) {
          _result = sbtiEvaluate(_answers);
          _stage = _Stage.result;
        }
      });

  void _back() => setState(() {
        if (_answers.isEmpty) {
          _stage = _Stage.intro;
        } else {
          _answers.removeLast();
        }
      });

  Future<void> _share(S s) async {
    final text = sbtiShareText(_result!, en: s.en);
    if (kIsWeb) {
      // 桌面浏览器多半没有系统分享面板;复制到剪贴板最不会让人卡住
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.sbtiCopied)));
      return;
    }
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.sbtiTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: switch (_stage) {
            _Stage.intro => _Intro(s: s, onStart: _start),
            _Stage.quiz => _Quiz(s: s, index: _answers.length, onAnswer: _answer, onBack: _back),
            _Stage.result => _Result(s: s, result: _result!, onShare: () => _share(s), onRetake: _start),
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 介绍

class _Intro extends StatelessWidget {
  const _Intro({required this.s, required this.onStart});
  final S s;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('SBTI', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.cinnabar, letterSpacing: 4)),
                Text(s.sbtiSubtitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Text(s.sbtiIntro, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(s.sbtiStart),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(s.sbtiFooter, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center),
      ],
    );
  }
}

// ---------------------------------------------------------------- 答题

class _Quiz extends StatelessWidget {
  const _Quiz({required this.s, required this.index, required this.onAnswer, required this.onBack});
  final S s;
  final int index;
  final ValueChanged<int> onAnswer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = sbtiQuestions[index];
    final n = sbtiQuestions.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            TextButton.icon(onPressed: onBack, icon: const Icon(Icons.chevron_left), label: Text(s.sbtiPrev)),
            const Spacer(),
            Text(s.sbtiQuestionNo(index + 1, n), style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: index / n, minHeight: 6),
        ),
        const SizedBox(height: 28),
        // key 跟着题号走,切题时按钮不会沿用上一题的按压态
        KeyedSubtree(
          key: ValueKey(index),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.en ? q.en : s.text(q.zh), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.35)),
              const SizedBox(height: 20),
              for (var i = 0; i < q.options.length; i++) ...[
                FilledButton.tonal(
                  onPressed: () => onAnswer(i),
                  style: FilledButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  child: Text(s.en ? q.options[i].en : s.text(q.options[i].zh), style: theme.textTheme.bodyLarge),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 结果

class _Result extends StatelessWidget {
  const _Result({required this.s, required this.result, required this.onShare, required this.onRetake});
  final S s;
  final SbtiResult result;
  final VoidCallback onShare;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = result.type;
    final chart = context.watch<AppState>().chart;
    final en = s.en;

    String dimHigh(int d) => en ? sbtiDimensions[d].enHigh : s.text(sbtiDimensions[d].zhHigh);
    String dimLow(int d) => en ? sbtiDimensions[d].enLow : s.text(sbtiDimensions[d].zhLow);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(s.sbtiYourType, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 6),
                Text(t.code, style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.cinnabar, letterSpacing: 2)),
                Text(en ? t.enName : s.text(t.zhName), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    Chip(label: Text(s.sbtiRarity(t.rarityPct)), backgroundColor: AppColors.gold.withValues(alpha: 0.2)),
                    Chip(label: Text(s.sbtiMatch(result.matchPct))),
                  ],
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.cinnabar, width: 3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
                    child: Text(
                      en ? t.enTagline : s.text(t.zhTagline),
                      style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(en ? t.enRoast : s.text(t.zhRoast), style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
              ],
            ),
          ),
        ),

        // 个性化:这个人自己的高低维度,不是模板里写死的
        if (result.highDims.isNotEmpty || result.lowDims.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.highDims.isNotEmpty) ...[
                    Text(s.sbtiHighs, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [for (final d in result.highDims) Chip(label: Text(dimHigh(d)), backgroundColor: AppColors.cinnabar.withValues(alpha: 0.12))]),
                  ],
                  if (result.highDims.isNotEmpty && result.lowDims.isNotEmpty) const SizedBox(height: 12),
                  if (result.lowDims.isNotEmpty) ...[
                    Text(s.sbtiLows, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [for (final d in result.lowDims) Chip(label: Text(dimLow(d)), backgroundColor: AppColors.jade.withValues(alpha: 0.12))]),
                  ],
                ],
              ),
            ),
          ),

        if (chart != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome, color: AppColors.gold),
              title: Text(s.sbtiEasterEgg, style: theme.textTheme.titleSmall),
              subtitle: Text(sbtiDayMasterLine(chart.dayMaster, en: en)),
            ),
          ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: Text(s.sbtiTip, style: theme.textTheme.titleSmall),
            subtitle: Text(en ? t.enTip : s.text(t.zhTip)),
          ),
        ),

        const SizedBox(height: 8),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            OutlinedButton.icon(onPressed: onRetake, icon: const Icon(Icons.refresh), label: Text(s.sbtiRetake)),
            FilledButton.icon(onPressed: onShare, icon: Icon(kIsWeb ? Icons.copy : Icons.ios_share), label: Text(s.sbtiShare)),
          ],
        ),
        const SizedBox(height: 8),
        Text(s.sbtiFooter, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center),
        const Disclaimer(),
      ],
    );
  }
}
