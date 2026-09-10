import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/app_state.dart';

/// 通用 AI 解读卡片:点一下请求后端,展示 Markdown。
///
/// [load] 拿到 ApiClient 后发请求。请求体由调用方决定,这里只管展示。
class AiReadingCard extends StatefulWidget {
  const AiReadingCard({
    super.key,
    required this.title,
    required this.load,
    this.autoLoad = false,
  });

  final String title;
  final Future<Interpretation> Function(ApiClient api) load;
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

  Future<void> _run() async {
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
    final reachable = context.watch<AppState>().serverReachable;
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
                if (_result?.cached == true)
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
                reachable ? '点击下方按钮,由 AI 为您解读这份盘面。' : '未连接到解读服务,请在"设置"中填写服务器地址。',
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
