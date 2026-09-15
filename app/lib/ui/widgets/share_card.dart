import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart' hide Element;
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/bazi/bazi_chart.dart';
import '../../core/bazi/five_elements.dart';
import '../../core/interpret/local_interpreter_en.dart';
import '../../core/interpret/plain_language.dart';
import '../../core/zodiac/western_zodiac.dart';
import '../../l10n/glossary.dart';
import '../../l10n/strings.dart';
import '../theme.dart';

/// 可分享的"命盘人设卡":四柱 + 日主人设 + 五行 + 喜用 + 星座,竖版海报比例。
///
/// 只包含用户自己已经在命盘页看到的东西,不含出生日期(海报会被转发,生日是敏感信息)。
class PersonaCard extends StatelessWidget {
  const PersonaCard({super.key, required this.chart, required this.zodiac, required this.s});
  final BaziChart chart;
  final ZodiacProfile zodiac;
  final S s;

  @override
  Widget build(BuildContext context) {
    final p = stemPersonas[chart.dayStem];
    final pe = enStemPersona(chart.dayStem);
    final e = chart.elements;
    final name = chart.input.name.isEmpty ? s.term(chart.input.gender.chartLabel) : chart.input.name;
    final image = s.en ? pe.image : s.text(p.image);
    final traits = s.en ? pe.traits : p.traits.map(s.text).join(' · ');
    final tip = s.en ? pe.tip : s.text(p.tip);

    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7F3EA), Color(0xFFEFE3D0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('命', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.cinnabar)),
              const SizedBox(width: 8),
              Text(s.appTitle, style: const TextStyle(fontSize: 13, color: AppColors.ink, letterSpacing: 1)),
              const Spacer(),
              Text(zodiac.sun.symbol, style: const TextStyle(fontSize: 22, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 18),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(s.en ? summaryEn(chart) : chart.summaryLine,
              style: TextStyle(fontSize: s.en ? 15 : 24, letterSpacing: s.en ? 0 : 3, fontWeight: FontWeight.w700, color: AppColors.cinnabar)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.personaLabel} · $image', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(traits, style: const TextStyle(fontSize: 13, color: Color(0xFF5A6270))),
                const SizedBox(height: 8),
                Text(tip, style: const TextStyle(fontSize: 12, color: Color(0xFF5A6270), height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final el in Element.values) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 46 * (e.percentages[el]! / 100).clamp(0.08, 1.0) + 6,
                        decoration: BoxDecoration(color: elementColor[el.label], borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 4),
                      Text(s.term(el.label), style: TextStyle(fontSize: s.en ? 9 : 12, color: AppColors.ink)),
                      Text('${e.percentages[el]!.round()}%', style: const TextStyle(fontSize: 10, color: Color(0xFF5A6270))),
                    ],
                  ),
                ),
                if (el != Element.water) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('${s.dayMasterShort} ${s.en ? stemPinyin[chart.dayStem] : chart.dayMasterName}${s.term(chart.dayMaster.label)} · ${s.term(e.strength.label)}'),
              _chip('${s.favorableShort} ${e.favorable.map((x) => s.term(x.label)).join(s.en ? ', ' : '')}'),
              _chip('${s.zodiacChip} ${s.animal(chart.yearPillar.stemBranch.branch)}'),
              _chip(s.en ? zodiac.sun.english : s.text(zodiac.sun.name)),
            ],
          ),
          const SizedBox(height: 18),
          Text(s.shareCardFooter, style: const TextStyle(fontSize: 10, color: Color(0xFF8A8F98))),
        ],
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.gold.withValues(alpha: 0.4))),
        child: Text(t, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
      );
}

/// 弹出预览 + 保存/分享。
Future<void> showShareCard(BuildContext context, BaziChart chart, ZodiacProfile zodiac) async {
  final key = GlobalKey();
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

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
              RepaintBoundary(key: key, child: PersonaCard(chart: chart, zodiac: zodiac, s: s)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: Icon(isDesktop ? Icons.save_alt : Icons.ios_share),
                    label: Text(isDesktop ? s.saveImage : s.shareImage),
                    onPressed: () async {
                      final png = await capture();
                      if (isDesktop) {
                        final loc = await getSaveLocation(
                          suggestedName: 'mingli-${chart.summaryLine.replaceAll(' ', '')}.png',
                          acceptedTypeGroups: const [XTypeGroup(label: 'PNG', extensions: ['png'])],
                        );
                        if (loc == null) return;
                        await File(loc.path).writeAsBytes(png);
                        messenger.showSnackBar(SnackBar(content: Text('${s.savedTo}: ${loc.path}')));
                      } else {
                        final dir = Directory.systemTemp;
                        final f = File('${dir.path}${Platform.pathSeparator}mingli-card.png');
                        await f.writeAsBytes(png);
                        await Share.shareXFiles([XFile(f.path, mimeType: 'image/png')]);
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
