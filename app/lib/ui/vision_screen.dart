import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../core/vision/face_features.dart';
import '../core/vision/palm_features.dart';
import '../l10n/strings.dart';
import '../platform/native.dart';
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
  static bool get _isDesktop => isDesktop;

  /// `image` 包能解码的格式。HEIC/AVIF 等目前解不了,选了会给出明确提示。
  static const _decodable = <String>[
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'tif', 'tiff', 'tga', 'ico', 'psd', 'pnm', 'pbm', 'pgm', 'ppm',
  ];

  S get _s => S(context.read<AppState>().language);

  Future<bool> _ensureConsent() async {
    final state = context.read<AppState>();
    if (state.biometricConsent) return true;
    final s = _s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.consentDialogTitle),
        content: Text(s.consentDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.disagree)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.agree)),
        ],
      ),
    );
    if (ok == true) await state.grantBiometricConsent();
    return ok == true;
  }

  Future<String?> _pickPath(ImageSource source) async {
    if (source == ImageSource.gallery && _isDesktop) {
      final s = _s;
      final f = await openFile(acceptedTypeGroups: [
        XTypeGroup(label: s.imagesGroup, extensions: _decodable),
        XTypeGroup(label: s.allFilesGroup),
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
    final s = _s;
    setState(() {
      _busy = true;
      _error = null;
      _palm = null;
      _face = null;
    });
    try {
      final bytes = await readFileBytes(path);
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
        throw s.decodeError(ext.isEmpty ? '' : ' (.$ext)');
      }
      if (isPalm) {
        final lm = await _landmarks.detectHand(path);
        if (lm == null) throw s.noHand;
        final lines = PalmLineExtractor().extract(decoded, lm);
        _palm = computePalmFeatures(lm, lines);
      } else {
        final k = await _landmarks.detectFace(path);
        if (k == null) throw s.noFace;
        _face = computeFaceFeatures(k);
      }
      _locNote = _landmarks.lastLocationNote;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (source == ImageSource.camera) await deleteFileQuietly(path);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final chart = context.watch<AppState>().chart;
    final features = isPalm ? _palm?.toJson() : _face?.toJson();

    return Scaffold(
      appBar: AppBar(title: Text(isPalm ? s.palmAi : s.faceAi)),
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
                      Text(isPalm ? s.palmInstruction : s.faceInstruction, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (!_isDesktop) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: Text(s.takePhoto),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(s.choosePhoto),
                            ),
                          ),
                        ],
                      ),
                      if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
                      if (_error != null)
                        Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                      const SizedBox(height: 8),
                      Text(s.photoLocalOnly, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
              ),
              if (_palm != null) ...[
                const SizedBox(height: 8),
                _FeatureCard(
                  title: '${s.term(_palm!.hand)} · ${s.term(_palm!.handShape)}',
                  rows: {
                    s.palmAspect: _palm!.palmAspect.toStringAsFixed(2),
                    s.fingerToPalm: _palm!.fingerToPalm.toStringAsFixed(2),
                    s.thumbAngle: '${_palm!.thumbAngle.toStringAsFixed(0)}°',
                    for (final e in _palm!.fingerRatios.entries) s.term(e.key): e.value.toStringAsFixed(2),
                    for (final l in _palm!.lines) s.term(l.name): s.lineStats(l.length.toStringAsFixed(2), l.curvature.toStringAsFixed(2), l.segments - 1),
                  },
                  notes: [if (_locNote != null) s.text(_locNote!), ..._palm!.notes.map(s.text)],
                ),
              ],
              if (_face != null) ...[
                const SizedBox(height: 8),
                _FeatureCard(
                  title: '${s.term(_face!.faceShape)} · ${s.symmetry((_face!.symmetry * 100).round())}',
                  rows: {
                    s.threeCourts: _face!.threeCourts.map((c) => (c * 100).round()).join(' : '),
                    s.fiveEyes: _face!.fiveEyes.toStringAsFixed(1),
                    for (final e in _face!.palaces.entries) s.text(e.key): s.text(e.value),
                  },
                  notes: [if (_locNote != null) s.text(_locNote!), ..._face!.notes.map(s.text)],
                ),
              ],
              if (features != null) ...[
                const SizedBox(height: 8),
                AiReadingCard(
                  key: ValueKey(features.hashCode),
                  title: isPalm ? s.aiPalm : s.aiFace,
                  load: (api) => isPalm ? api.interpretPalm(features, chart?.toJson()) : api.interpretFace(features, chart?.toJson()),
                  localText: () => isPalm
                      ? (s.en ? enInterpretPalm(_palm!) : localInterpretPalm(_palm!))
                      : (s.en ? enInterpretFace(_face!) : localInterpretFace(_face!)),
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
