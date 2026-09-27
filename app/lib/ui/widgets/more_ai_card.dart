import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_language.dart';
import '../../l10n/strings.dart';
import '../../services/api_client.dart';
import '../../services/app_state.dart';
import 'ai_reading_card.dart';

/// 「更多 AI 解读」:和上面那张 AiReadingCard 用同一份数据,但固定让后端走 Gemini、
/// 按"补充视角"模式生成(一处反直觉的观察、三个场景的建议、一句写给一年后的你)。
///
/// 和 AiReadingCard 的区别只有一点:**没有本机兜底**。服务器不可达时按钮灰掉、给出提示,
/// 不报错;现有的 AI 解读卡完全不受影响。
class MoreAiCard extends StatefulWidget {
  const MoreAiCard({super.key, required this.kind, required this.body});

  /// 后端任务类型,与 /v1/interpret/<kind> 一致。
  final String kind;

  /// 请求体,与对应 interpretX 的字段一致;每次生成时现取,免得拿到过期的盘面。
  final Map<String, dynamic> Function() body;

  @override
  State<MoreAiCard> createState() => _MoreAiCardState();
}

class _MoreAiCardState extends State<MoreAiCard> {
  Interpretation? _result;
  Object? _error;
  bool _loading = false;
  AppLanguage? _resultLang;

  Future<void> _run() async {
    final state = context.read<AppState>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await state.api.more(widget.kind, widget.body());
      if (mounted) {
        setState(() {
          _result = r;
          _resultLang = state.language;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      // 连不上就顺手刷新一下可达状态,按钮会随之灰掉
      if (e is ApiException && e.statusCode == 0) state.refreshServerStatus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final s = S.of(context);
    final available = state.serverReachable;

    // 切换语言后,旧结果的语言对不上了,清掉让用户重新生成
    if (_result != null && _resultLang != null && _resultLang != state.language) {
      _result = null;
      _resultLang = null;
    }

    final badge = _result == null ? null : (_result!.cached ? '${s.moreAiBadge} · ${s.badgeCached}' : s.moreAiBadge);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_motion, color: theme.colorScheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(s.moreAiTitle, style: theme.textTheme.titleMedium)),
                if (badge != null)
                  Flexible(child: Text(badge, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.end)),
              ],
            ),
            const SizedBox(height: 12),
            if (_result != null)
              aiMarkdownBody(theme, _result!.text)
            else if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Text(
                _error is ApiException ? (_error as ApiException).message : s.failed('$_error'),
                style: TextStyle(color: theme.colorScheme.error),
              )
            else
              Text(available ? s.moreAiSubtitle : s.moreAiNeedServer, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 12),
            if (!_loading)
              OutlinedButton.icon(
                onPressed: available ? _run : null,
                icon: Icon(_result == null ? Icons.play_arrow : Icons.refresh),
                label: Text(_result == null ? s.moreAiGenerate : s.regenerate),
              ),
          ],
        ),
      ),
    );
  }
}
