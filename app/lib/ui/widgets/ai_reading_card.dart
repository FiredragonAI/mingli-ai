import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/app_state.dart';

/// 通用 AI 解读卡片:点一下请求后端,展示 Markdown。
///
/// [load] 拿到 ApiClient 后发请求,走云端解读。
/// [localText] 在"设置 → 离线本地解读"打开时代替 [load]——同步生成 Markdown,
/// 不发任何网络请求。两者都可以传;调用方决定这块内容值不值得做离线兜底。
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

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  bool get _useLocal =>
      context.read<AppState>().useLocalInterpretation && widget.localText != null;

  Future<void> _run() async {
    if (_useLocal) {
      // 本地生成是纯函数、瞬时完成,不需要走 loading 态,但仍统一走一次
      // setState 以复用下面的展示逻辑与错误兜底。
      try {
        final text = widget.localText!();
        setState(() {
          _result = Interpretation(text: text, sections: const {}, cached: false, model: '本地生成');
          _error = null;
        });
      } catch (e) {
        setState(() => _error = e);
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AppState>().api;
      final r = await widget.load(api);
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useLocal = context.watch<AppState>().useLocalInterpretation && widget.localText != null;
    final reachable = useLocal || context.watch<AppState>().serverReachable;
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
                if (_result?.model == '本地生成')
                  Text('本地生成 · 未联网', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline))
                else if (_result?.cached == true)
                  Text('已缓存', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
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
              Text(
                useLocal
                    ? '点击下方按钮,由本机规则引擎为您生成解读(无需联网)。'
                    : reachable
                        ? '点击下方按钮,由 AI 为您解读这份盘面。'
                        : '未连接到解读服务,请在"设置"中填写服务器地址,或开启离线本地解读。',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            const SizedBox(height: 12),
            if (!_loading)
              OutlinedButton.icon(
                onPressed: reachable ? _run : null,
                icon: Icon(_result == null ? Icons.play_arrow : Icons.refresh),
                label: Text(_result == null ? '开始解读' : '重新生成'),
              ),
          ],
        ),
      ),
    );
  }
}
