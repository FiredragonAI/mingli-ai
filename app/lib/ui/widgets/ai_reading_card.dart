import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

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
/// [load] 拿到 ApiClient 后发请求,走云端解读。
/// [localText] 是本机规则引擎的兜底:用户主动选离线时用它;
/// 云端连不上或请求中途失败时也自动用它——用户永远不会面对一块空白或报错。
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

  /// 本次结果是否因云端失败而临时改用本机生成。
  bool _fellBack = false;

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
    try {
      final text = widget.localText!();
      setState(() {
        _result = Interpretation(text: text, sections: const {}, cached: false, model: 'local');
        _error = null;
        _fellBack = fallback;
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
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (!mounted) return;
      // 网络不通或服务端故障:有本地兜底就直接用,不让用户面对一条报错。
      // 4xx(限流、内容拒绝)是要告诉用户的,不吞。
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
    final source = _sourceOf(context.watch<AppState>());

    String? badge;
    if (_result != null) {
      if (_fellBack) {
        badge = '云端暂不可用 · 本机生成';
      } else if (_result!.model == 'local') {
        badge = '本机生成 · 未联网';
      } else if (_result!.cached) {
        badge = '已缓存';
      }
    }

    final hint = switch (source) {
      _Source.cloud => '点击下方按钮,由 AI 为您解读这份盘面。',
      _Source.localForced => '点击下方按钮,由本机规则引擎生成解读(无需联网)。',
      _Source.localFallback => '当前连不上云端,将由本机规则引擎生成解读;联网后点"重新生成"可获得 AI 版本。',
      _Source.unavailable => '当前无法连接解读服务,请检查网络。',
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
                  Text(badge, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
            const SizedBox(height: 12),
            if (_result != null)
              MarkdownBody(
                data: _result!.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                  h2: theme.textTheme.titleMedium,
                  h3: theme.textTheme.titleSmall,
                ),
              )
            else if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(
                _error is ApiException ? (_error as ApiException).message : '解读失败:$_error',
                style: TextStyle(color: theme.colorScheme.error),
              )
            else
              Text(hint, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 12),
            if (!_loading)
              OutlinedButton.icon(
                onPressed: source == _Source.unavailable ? null : _run,
                icon: Icon(_result == null ? Icons.play_arrow : Icons.refresh),
                label: Text(_result == null ? '开始解读' : '重新生成'),
              ),
          ],
        ),
      ),
    );
  }
}
