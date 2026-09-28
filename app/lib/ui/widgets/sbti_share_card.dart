import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/sbti/sbti.dart';
import '../../l10n/strings.dart';
import '../../services/app_state.dart';
import '../../platform/native.dart';
import '../theme.dart';

/// SBTI 结果海报:竖版,一屏装下"我是 XX",给人截图/转发用。
///
/// 只放类型码、名字、金句、稀有度/匹配度和落款——没有任何个人信息,转发出去也不泄露什么。
class SbtiPoster extends StatelessWidget {
  const SbtiPoster({super.key, required this.result, required this.s});
  final SbtiResult result;
  final S s;

  @override
  Widget build(BuildContext context) {
    final t = result.type;
    final en = s.en;
    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFBF7F0), Color(0xFFF1E7DA)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.jade.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 两个标题都给 Flexible + 省略号:英文标题长,窄海报上不能靠 Spacer 硬撑
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(s.appTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cinnabar, letterSpacing: 1))),
              const SizedBox(width: 12),
              Flexible(child: Text(s.sbtiTitle, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, color: AppColors.ink))),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.sbtiYourType, style: const TextStyle(fontSize: 12, color: Color(0xFF8A8078))),
          const SizedBox(height: 2),
          SvgPicture.asset(
            'assets/sbti/${t.avatar}.svg',
            width: 150,
            height: 150,
            errorBuilder: (_, __, ___) => SizedBox(width: 150, height: 150, child: Center(child: Text(t.emoji, style: const TextStyle(fontSize: 90, height: 1)))),
          ),
          Text(t.code, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: AppColors.jade, letterSpacing: 2, height: 1.05)),
          Text(en ? t.enName : s.text(t.zhName), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          Text(
            en ? t.enTagline : s.text(t.zhTagline),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.45, color: Color(0xFF4A4340)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _pill(s.sbtiRarity(t.rarityPct), AppColors.gold),
              _pill('${s.sbtiMatch(result.matchPct)} · ${s.sbtiExact(result.exactMatches, sbtiDimensions.length)}', AppColors.jade),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.ink.withValues(alpha: 0.12)),
          const SizedBox(height: 10),
          Text(s.sbtiPosterFooter, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8078))),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
      );
}

/// 只分享文字(旧行为,留作次要选项)。
Future<void> shareSbtiText(BuildContext context, SbtiResult result, S s) async {
  final text = sbtiShareText(result, en: s.en);
  if (kIsWeb) {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.sbtiCopied)));
    return;
  }
  await Share.share(text);
}

/// 弹出海报预览 + 保存/分享图片。与命盘页的 showShareCard 同一套抓图与落盘逻辑。
Future<void> showSbtiShareCard(BuildContext context, SbtiResult result) async {
  final key = GlobalKey();
  // 这是回调不是 build:不能 watch,读一次当前语言即可
  final s = S(context.read<AppState>().language);
  final messenger = ScaffoldMessenger.of(context);
  // 桌面端另存为、Web 端浏览器下载,都是"存到本机";手机端才走系统分享面板
  final saveLocally = isDesktop || kIsWeb;
  final filename = 'sbti-${result.type.code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}.png';

  Future<Uint8List> capture() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 海报比对话框宽时按比例缩小显示;RepaintBoundary 在 FittedBox 里面,
              // toImage 抓的仍是海报自身的布局尺寸(pixelRatio 3),导出分辨率不受影响。
              FittedBox(
                fit: BoxFit.scaleDown,
                child: RepaintBoundary(key: key, child: SbtiPoster(result: result, s: s)),
              ),
              const SizedBox(height: 12),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await shareSbtiText(context, result, s);
                    },
                    child: Text(s.sbtiShareTextOnly),
                  ),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
                  FilledButton.icon(
                    icon: Icon(saveLocally ? Icons.save_alt : Icons.ios_share),
                    label: Text(saveLocally ? s.saveImage : s.shareImage),
                    onPressed: () async {
                      final png = await capture();
                      if (kIsWeb) {
                        await downloadBytes(png, filename, 'image/png');
                      } else if (isDesktop) {
                        final loc = await getSaveLocation(
                          suggestedName: filename,
                          acceptedTypeGroups: const [XTypeGroup(label: 'PNG', extensions: ['png'])],
                        );
                        if (loc == null) return;
                        await writeFileBytes(loc.path, png);
                        messenger.showSnackBar(SnackBar(content: Text('${s.savedTo}: ${loc.path}')));
                      } else {
                        final path = tempFilePath(filename);
                        await writeFileBytes(path, png);
                        await Share.shareXFiles([XFile(path, mimeType: 'image/png')], text: sbtiShareText(result, en: s.en));
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
