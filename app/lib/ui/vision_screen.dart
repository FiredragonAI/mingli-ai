import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/interpret/local_interpreter.dart';
import '../core/vision/face_features.dart';
import '../core/vision/palm_features.dart';
import '../services/app_state.dart';
import '../services/vision/landmark_service.dart';
import '../services/vision/palm_line_extractor.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';

enum VisionMode { palm, face }

/// 手相 / 面相:拍照或选图 → 端侧提取特征 → 仅上传几何 JSON。
class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key, required this.mode});
  final VisionMode mode;

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  final _picker = ImagePicker();
  final _landmarks = LandmarkService.forPlatform();
  bool _busy = false;
  String? _error;
  PalmFeatures? _palm;
  FaceFeatures? _face;
  String? _locNote;

  bool get isPalm => widget.mode == VisionMode.palm;

  Future<bool> _ensureConsent() async {
    final state = context.read<AppState>();
    if (state.biometricConsent) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('关于您的照片'),
        content: const Text(
          '手掌或面部照片属于敏感个人信息。\n\n'
          '• 照片只在本机内存中分析,不保存、不上传;\n'
          '• 发送给解读服务的仅是比例、角度等几何数据,无法还原出您的照片;\n'
          '• 您可随时在"设置"中撤回同意。\n\n'
          '是否同意在本机处理您的照片?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('不同意')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('同意')),
        ],
      ),
    );
    if (ok == true) await state.grantBiometricConsent();
    return ok == true;
  }

  static bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// `image` 包能解码的格式。HEIC/AVIF 等目前解不了,选了会给出明确提示。
  static const _decodable = <String>[
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'tif', 'tiff', 'tga', 'ico', 'psd', 'pnm', 'pbm', 'pgm', 'ppm',
  ];

  /// 选图。桌面端用系统文件对话框,不限制扩展名;移动端走相册/相机。
  Future<String?> _pickPath(ImageSource source) async {
    if (source == ImageSource.gallery && _isDesktop) {
      final f = await openFile(acceptedTypeGroups: const [
        XTypeGroup(label: '图片', extensions: _decodable),
        XTypeGroup(label: '所有文件'),
      ]);
      return f?.path;
    }
    final x = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 92);
    return x?.path;
  }

  Future<void> _pick(ImageSource source) async {
    if (!await _ensureConsent()) return;
    final path = await _pickPath(source);
    if (path == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _palm = null;
      _face = null;
    });
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
        throw '无法解码这张图片${ext.isEmpty ? '' : '(.$ext)'}。'
            '支持 JPG / PNG / WebP / BMP / GIF / TIFF 等常见格式;'
            'iPhone 的 HEIC 照片请先在手机相册里"导出为 JPG"再选择。';
      }
      if (isPalm) {
        final lm = await _landmarks.detectHand(path);
        if (lm == null) throw '未检测到手掌。请让手掌张开、掌心朝向镜头;全身照也可以,但手掌别被遮挡。';
        final lines = PalmLineExtractor().extract(decoded, lm);
        _palm = computePalmFeatures(lm, lines);
      } else {
        final k = await _landmarks.detectFace(path);
        if (k == null) throw '未检测到人脸。请确保脸部无遮挡、光线均匀;全身照可以,但侧脸或过小的脸识别不了。';
        _face = computeFaceFeatures(k);
      }
      _locNote = _landmarks.lastLocationNote;
    } catch (e) {
      _error = e.toString();
    } finally {
      // 相机拍的临时文件处理完立刻删除,照片不留在磁盘;用户自己选的文件不动
      try {
        if (source == ImageSource.camera) await File(path).delete();
      } catch (_) {}
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chart = context.watch<AppState>().chart;
    final features = isPalm ? _palm?.toJson() : _face?.toJson();

    return Scaffold(
      appBar: AppBar(title: Text(isPalm ? '手相 AI' : '面相 AI')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(isPalm ? Icons.back_hand_outlined : Icons.face_outlined, size: 56, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        isPalm ? '张开手掌,掌心朝向镜头,光线均匀无阴影。全身照、生活照也可以,程序会自动定位手掌。' : '正对镜头,露出额头与下巴,表情自然,光线均匀。全身照、合照也可以,程序会自动定位人脸。',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // 桌面端 image_picker 不支持相机,只保留选图
                          if (!_isDesktop) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('拍照'),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('选择照片'),
                            ),
                          ),
                        ],
                      ),
                      if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      const SizedBox(height: 8),
                      Text('照片仅在本机分析,不会上传。', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
              ),
              if (_palm != null) ...[
                const SizedBox(height: 8),
                _FeatureCard(
                  title: '${_palm!.hand} · ${_palm!.handShape}',
                  rows: {
                    '掌长/掌宽': _palm!.palmAspect.toStringAsFixed(2),
                    '中指/掌长': _palm!.fingerToPalm.toStringAsFixed(2),
                    '拇指张角': '${_palm!.thumbAngle.toStringAsFixed(0)}°',
                    for (final e in _palm!.fingerRatios.entries) e.key: e.value.toStringAsFixed(2),
                    for (final l in _palm!.lines) l.name: '长 ${l.length.toStringAsFixed(2)} · 弯 ${l.curvature.toStringAsFixed(2)}${l.segments > 1 ? ' · 断 ${l.segments - 1}' : ''}',
                  },
                  notes: [if (_locNote != null) _locNote!, ..._palm!.notes],
                ),
              ],
              if (_face != null) ...[
                const SizedBox(height: 8),
                _FeatureCard(
                  title: '${_face!.faceShape} · 对称度 ${(_face!.symmetry * 100).round()}%',
                  rows: {
                    '三停': _face!.threeCourts.map((c) => (c * 100).round()).join(' : '),
                    '五眼': _face!.fiveEyes.toStringAsFixed(1),
                    for (final e in _face!.palaces.entries) e.key: e.value,
                  },
                  notes: [if (_locNote != null) _locNote!, ..._face!.notes],
                ),
              ],
              if (features != null) ...[
                const SizedBox(height: 8),
                AiReadingCard(
                  key: ValueKey(features.hashCode),
                  title: isPalm ? 'AI 手相解读' : 'AI 面相解读',
                  load: (api) => isPalm ? api.interpretPalm(features, chart?.toJson()) : api.interpretFace(features, chart?.toJson()),
                  localText: () => isPalm ? localInterpretPalm(_palm!) : localInterpretFace(_face!),
                ),
              ],
              const Disclaimer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.rows, required this.notes});
  final String title;
  final Map<String, String> rows;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final e in rows.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))),
                    Text(e.value, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            const Divider(),
            for (final n in notes) Text('· $n', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
