import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_language.dart';
import '../../l10n/s2t.dart';
import '../../l10n/strings.dart';
import '../../services/api_client.dart';
import '../../services/app_state.dart';

/// 解读文字从哪来。
enum _Source {
  /// 云端 AI。
  cloud,

  /// 用户在设置里主动选了离线本地。
  localForced,

  /// 云端连不上,自动退回本机生成。
  localFallback,

  /// 云端连不上且本模块没有本地兜底。
  unavailable,
}

/// 通用 AI 解读卡片:点一下请求后端,展示 Markdown。
///
/// [load] 拿到 ApiClient 后发请求,走云端解读(语言由 ApiClient 带给后端)。
/// [localText] 是本机规则引擎的兜底:用户主动选离线时用它;云端连不上或请求
/// 中途失败时也自动用它。调用方按当前语言给中文或英文版本;繁体由这里统一转换。
class AiReadingCard extends StatefulWidget {
  const AiReadingCard({
    super.key,
    required this.title,
    required this.load,
    this.localText,
    this.autoLoad = false,
  });

  final String title;
  final Future<Interpretation> Function(ApiClient api) load;
  final String Function()? localText;
  final bool autoLoad;

  @override
  State<AiReadingCard> createState() => _AiReadingCardState();
}

class _AiReadingCardState extends State<AiReadingCard> {
  Interpretation? _result;
  Object? _error;
  bool _loading = false;
  bool _fellBack = false;
  AppLanguage? _resultLang;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  _Source _sourceOf(AppState s) {
    final hasLocal = widget.localText != null;
    if (s.useLocalInterpretation && hasLocal) return _Source.localForced;
    if (s.serverReachable) return _Source.cloud;
    if (hasLocal) return _Source.localFallback;
    return _Source.unavailable;
  }

  void _setLocal({required bool fallback}) {
    final lang = context.read<AppState>().language;
    try {
      var text = widget.localText!();
      if (lang == AppLanguage.zhHant) text = S2T.convert(text);
      setState(() {
        _result = Interpretation(text: text, sections: const {}, cached: false, model: 'local');
        _error = null;
        _fellBack = fallback;
        _resultLang = lang;
      });
    } catch (e) {
      setState(() => _error = e);
    }
  }

  Future<void> _run() async {
    final state = context.read<AppState>();
    switch (_sourceOf(state)) {
      case _Source.localForced:
        _setLocal(fallback: false);
        return;
      case _Source.localFallback:
        _setLocal(fallback: true);
        return;
      case _Source.unavailable:
        return;
      case _Source.cloud:
        break;
    }

    setState(() {
      _loading = true;
      _error = null;
      _fellBack = false;
    });
    try {
      final r = await widget.load(state.api);
      if (mounted) {
        setState(() {
          _result = r;
          _resultLang = state.language;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // 网络不通或服务端故障:有本地兜底就直接用。4xx(限流、内容拒绝)要告诉用户,不吞。
      final transient = e is ApiException && (e.statusCode == 0 || e.statusCode >= 500);
      if (transient && widget.localText != null) {
        _setLocal(fallback: true);
        state.refreshServerStatus();
      } else {
        setState(() => _error = e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final s = S.of(context);
    final source = _sourceOf(state);

    // 切换语言后,旧结果的语言对不上了,清掉让用户重新生成
    if (_result != null && _resultLang != null && _resultLang != state.language) {
      _result = null;
      _resultLang = null;
    }

    String? badge;
    if (_result != null) {
      if (_fellBack) {
        badge = s.badgeFallback;
      } else if (_result!.model == 'local') {
        badge = s.badgeLocal;
      } else if (_result!.cached) {
        badge = s.badgeCached;
      }
    }

    final hint = switch (source) {
      _Source.cloud => s.hintCloud,
      _Source.localForced => s.hintLocal,
      _Source.localFallback => s.hintFallback,
      _Source.unavailable => s.hintUnavailable,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.title, style: theme.textTheme.titleMedium)),
                if (badge != null)
                  Flexible(child: Text(badge, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.end)),
              ],
            ),
            const SizedBox(height: 12),
            if (_result != null)
              MarkdownBody(
                data: _result!.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                  h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
                  h1Padding: const EdgeInsets.only(bottom: 4),
                  h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  h2Padding: const EdgeInsets.only(top: 10, bottom: 2),
                  h3: theme.textTheme.titleSmall,
                  blockquoteDecoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
                  ),
                  blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  blockquote: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.normal, height: 1.6),
                ),
              )
            else if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Text(
                _error is ApiException ? (_error as ApiException).message : s.failed('$_error'),
                style: TextStyle(color: theme.colorScheme.error),
              )
            else
              Text(hint, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 12),
            if (!_loading)
              OutlinedButton.icon(
                onPressed: source == _Source.unavailable ? null : _run,
                icon: Icon(_result == null ? Icons.play_arrow : Icons.refresh),
                label: Text(_result == null ? s.generate : s.regenerate),
              ),
          ],
        ),
      ),
    );
  }
}
