import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bazi/bazi_chart.dart';
import '../data/cities.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';

/// 出生信息录入。也用于合婚对象录入([onSubmit] 非空时不写入档案)。
class BirthInputScreen extends StatefulWidget {
  const BirthInputScreen({
    super.key,
    this.firstRun = false,
    this.initial,
    this.editIndex,
    this.onSubmit,
    this.title,
  });

  final bool firstRun;
  final BirthInput? initial;
  final int? editIndex;
  final void Function(BirthInput input)? onSubmit;
  final String? title;

  @override
  State<BirthInputScreen> createState() => _BirthInputScreenState();
}

class _BirthInputScreenState extends State<BirthInputScreen> {
  late DateTime _date;
  late TimeOfDay _time;
  Gender _gender = Gender.male;
  City? _city;
  final _nameCtrl = TextEditingController();
  BirthTimeMode _timeMode = BirthTimeMode.exact;
  int _shichen = 6; // 午时

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _date = DateTime(i.year, i.month, i.day);
      _time = TimeOfDay(hour: i.hour, minute: i.minute);
      _gender = i.gender;
      _nameCtrl.text = i.name;
      _timeMode = i.timeMode;
      _shichen = i.hourBranch;
      _city = cities.where((c) => c.name == i.placeName).firstOrNull ?? cities.first;
    } else {
      _date = DateTime(1995, 6, 15);
      _time = const TimeOfDay(hour: 12, minute: 0);
      _city = cities.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _submit() {
    // 时辰模式取该时辰中点(子 0:00、丑 2:00 … 亥 22:00);不确定按正午
    final (hour, minute) = switch (_timeMode) {
      BirthTimeMode.exact => (_time.hour, _time.minute),
      BirthTimeMode.shichen => ((_shichen * 2) % 24, 0),
      BirthTimeMode.unknown => (12, 0),
    };
    final input = BirthInput(
      year: _date.year,
      month: _date.month,
      day: _date.day,
      hour: hour,
      minute: minute,
      gender: _gender,
      longitude: _city?.longitude ?? 116.41,
      latitude: _city?.latitude ?? 0,
      placeName: _city?.name ?? '',
      timezoneHours: _city?.timezone ?? 8,
      // 真太阳时按出生地经度自动叠加。只有精确时间才值得做几分钟级的修正;
      // 时辰/不确定模式下修正可能把时辰推过边界,反而添乱。
      useTrueSolarTime: _timeMode == BirthTimeMode.exact,
      ziHourMode: ZiHourMode.nextDay,
      timeMode: _timeMode,
      name: _nameCtrl.text.trim(),
    );

    if (widget.onSubmit != null) {
      widget.onSubmit!(input);
      Navigator.of(context).pop();
      return;
    }
    final state = context.read<AppState>();
    if (widget.editIndex != null) {
      state.updateProfile(widget.editIndex!, input);
    } else {
      state.addProfile(input);
    }
    if (!widget.firstRun) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final tileShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant));

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? (widget.firstRun ? s.appTitle : s.birthDetails))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 排盘页(自己的档案)顶部常驻语言切换;合婚里填对方信息的页面不放
              if (widget.onSubmit == null) ...[
                SegmentedButton<AppLanguage>(
                  segments: [for (final l in AppLanguage.values) ButtonSegment(value: l, label: Text(l.nativeName))],
                  selected: {context.watch<AppState>().language},
                  onSelectionChanged: (v) => context.read<AppState>().setLanguage(v.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 20),
              ],
              if (widget.firstRun) ...[
                Text(s.firstRunTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(s.privacyNote, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: s.nameOptional),
              ),
              const SizedBox(height: 12),
              SegmentedButton<Gender>(
                segments: [
                  ButtonSegment(value: Gender.male, label: Text(s.male), icon: const Icon(Icons.male)),
                  ButtonSegment(value: Gender.female, label: Text(s.female), icon: const Icon(Icons.female)),
                ],
                selected: {_gender},
                onSelectionChanged: (v) => setState(() => _gender = v.first),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: tileShape,
                leading: const Icon(Icons.event),
                title: Text(s.birthDate),
                subtitle: Text(s.ymd(_date.year, _date.month, _date.day)),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              Text(s.birthTime, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<BirthTimeMode>(
                segments: [
                  ButtonSegment(value: BirthTimeMode.exact, label: Text(s.timeExact), icon: const Icon(Icons.schedule)),
                  ButtonSegment(value: BirthTimeMode.shichen, label: Text(s.timeShichen), icon: const Icon(Icons.hourglass_bottom)),
                  ButtonSegment(value: BirthTimeMode.unknown, label: Text(s.timeUnknown), icon: const Icon(Icons.help_outline)),
                ],
                selected: {_timeMode},
                onSelectionChanged: (v) => setState(() => _timeMode = v.first),
              ),
              const SizedBox(height: 8),
              switch (_timeMode) {
                BirthTimeMode.exact => ListTile(
                    shape: tileShape,
                    leading: const Icon(Icons.schedule),
                    title: Text(s.timeExact),
                    subtitle: Text(_time.format(context)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickTime,
                  ),
                BirthTimeMode.shichen => DropdownButtonFormField<int>(
                    initialValue: _shichen,
                    decoration: InputDecoration(labelText: s.timeShichen, helperText: s.timeShichenHint),
                    items: [for (var b = 0; b < 12; b++) DropdownMenuItem(value: b, child: Text(s.shichen(b)))],
                    onChanged: (v) => setState(() => _shichen = v ?? _shichen),
                  ),
                BirthTimeMode.unknown => ListTile(
                    shape: tileShape,
                    leading: const Icon(Icons.help_outline),
                    title: Text(s.timeUnknown),
                    subtitle: Text(s.timeUnknownHint),
                  ),
              },
              const SizedBox(height: 12),
              DropdownButtonFormField<City>(
                initialValue: _city,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.birthPlace),
                items: [
                  for (final c in cities) DropdownMenuItem(value: c, child: Text(s.en ? c.en : s.text(c.name))),
                ],
                onChanged: (c) => setState(() => _city = c),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _submit, child: Text(widget.onSubmit != null ? s.ok : s.startChart)),
            ],
          ),
        ),
      ),
    );
  }
}
