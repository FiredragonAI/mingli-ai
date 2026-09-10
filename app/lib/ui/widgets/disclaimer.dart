import 'package:flutter/material.dart';

/// 每个结果页底部固定的免责声明。合规要求,不要删。
class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Text(
        '内容基于传统文化整理,仅供娱乐参考,不构成任何医疗、法律、投资建议。'
        '解读文字由 AI 生成。',
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
