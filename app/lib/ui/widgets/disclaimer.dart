import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

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
      child: Text(S.of(context).disclaimer, style: style, textAlign: TextAlign.center),
    );
  }
}
