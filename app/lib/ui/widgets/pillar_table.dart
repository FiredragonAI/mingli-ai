import 'package:flutter/material.dart';

import '../../core/bazi/bazi_chart.dart';
import '../theme.dart';

/// 四柱表:天干十神 / 干 / 支 / 藏干 / 纳音 / 长生。
class PillarTable extends StatelessWidget {
  const PillarTable({super.key, required this.chart});
  final BaziChart chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voidPos = chart.voidPositions;

    Widget cell(Widget child, {double height = 36}) => SizedBox(
          height: height,
          child: Center(child: child),
        );

    Widget stemText(String s, String element, {double size = 28}) => Text(
          s,
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: elementColor[element]),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _label(theme, ''),
                for (final p in chart.pillars)
                  Expanded(child: cell(Text('${p.positionName}柱', style: theme.textTheme.labelMedium))),
              ],
            ),
            Row(
              children: [
                _label(theme, '十神'),
                for (final p in chart.pillars)
                  Expanded(child: cell(Text(p.stemGod?.label ?? '日主', style: theme.textTheme.bodySmall))),
              ],
            ),
            Row(
              children: [
                _label(theme, '天干'),
                for (final p in chart.pillars)
                  Expanded(child: cell(stemText(p.stemBranch.stemName, p.stemBranch.stemElement.label), height: 44)),
              ],
            ),
            Row(
              children: [
                _label(theme, '地支'),
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: cell(
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          stemText(chart.pillars[i].stemBranch.branchName, chart.pillars[i].stemBranch.branchElement.label),
                          if (voidPos.contains(i))
                            Positioned(
                              right: 6,
                              top: 0,
                              child: Text('空', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                            ),
                        ],
                      ),
                      height: 44,
                    ),
                  ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(theme, '藏干'),
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
                                  text: h.name,
                                  style: TextStyle(color: elementColor[_el(h.stem)], fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: ' ${h.tenGod.label}', style: theme.textTheme.bodySmall),
                              ]),
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
                _label(theme, '纳音'),
                for (final p in chart.pillars) Expanded(child: cell(Text(p.naYin, style: theme.textTheme.bodySmall))),
              ],
            ),
            Row(
              children: [
                _label(theme, '长生'),
                for (final p in chart.pillars) Expanded(child: cell(Text(p.lifeStage, style: theme.textTheme.bodySmall))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _el(int stem) => ['木', '木', '火', '火', '土', '土', '金', '金', '水', '水'][stem];

  Widget _label(ThemeData theme, String s) => SizedBox(
        width: 40,
        child: Text(s, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
      );
}
