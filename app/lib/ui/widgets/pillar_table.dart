import 'package:flutter/material.dart';

import '../../core/bazi/bazi_chart.dart';
import '../../l10n/glossary.dart';
import '../../l10n/strings.dart';
import '../theme.dart';

/// 四柱表:天干十神 / 干 / 支 / 藏干 / 纳音 / 长生。
class PillarTable extends StatelessWidget {
  const PillarTable({super.key, required this.chart});
  final BaziChart chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final voidPos = chart.voidPositions;

    Widget cell(Widget child, {double height = 36}) => SizedBox(height: height, child: Center(child: child));

    /// 大字 + 英文界面下的小字拼音。
    Widget glyph(String zh, String pinyin, String element) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(zh, style: TextStyle(fontSize: 28, height: 1.1, fontWeight: FontWeight.w700, color: elementColor[element])),
            if (s.en) Text(pinyin, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
          ],
        );

    final glyphHeight = s.en ? 58.0 : 44.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _label(theme, ''),
                for (var i = 0; i < 4; i++)
                  Expanded(child: cell(Text('${s.pillar(i)}${s.pillarSuffix}', style: theme.textTheme.labelMedium))),
              ],
            ),
            Row(
              children: [
                _label(theme, s.tenGods),
                for (final p in chart.pillars)
                  Expanded(child: cell(Text(s.term(p.stemGod?.label ?? '日主'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center))),
              ],
            ),
            Row(
              children: [
                _label(theme, s.stemRow),
                for (final p in chart.pillars)
                  Expanded(child: cell(glyph(p.stemBranch.stemName, stemPinyin[p.stemBranch.stem], p.stemBranch.stemElement.label), height: glyphHeight)),
              ],
            ),
            Row(
              children: [
                _label(theme, s.branchRow),
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: cell(
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          glyph(chart.pillars[i].stemBranch.branchName, branchPinyin[chart.pillars[i].stemBranch.branch], chart.pillars[i].stemBranch.branchElement.label),
                          if (voidPos.contains(i))
                            Positioned(
                              right: 6,
                              top: 0,
                              child: Text(s.voidMark, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                            ),
                        ],
                      ),
                      height: glyphHeight,
                    ),
                  ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(theme, s.hiddenRow),
                for (final p in chart.pillars)
                  Expanded(
                    child: Column(
                      children: [
                        for (final h in p.hiddenStems)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: s.en ? stemPinyin[h.stem] : h.name,
                                  style: TextStyle(color: elementColor[_el(h.stem)], fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: ' ${s.term(h.tenGod.label)}', style: theme.textTheme.bodySmall),
                              ]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _label(theme, s.naYinRow),
                for (final p in chart.pillars) Expanded(child: cell(Text(s.text(p.naYin), style: theme.textTheme.bodySmall))),
              ],
            ),
            Row(
              children: [
                _label(theme, s.lifeStageRow),
                for (final p in chart.pillars)
                  Expanded(
                    child: cell(Text(
                      s.en ? lifeStageEnglish[lifeStages.indexOf(p.lifeStage)] : s.text(p.lifeStage),
                      style: theme.textTheme.bodySmall,
                    )),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _el(int stem) => ['木', '木', '火', '火', '土', '土', '金', '金', '水', '水'][stem];

  Widget _label(ThemeData theme, String s) => SizedBox(
        width: 52,
        child: Text(s, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
      );
}
