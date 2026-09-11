import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bazi/bazi_chart.dart';
import '../data/cities.dart';
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
  bool _unknownTime = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _date = DateTime(i.year, i.month, i.day);
      _time = TimeOfDay(hour: i.hour, minute: i.minute);
      _gender = i.gender;
      _nameCtrl.text = i.name;
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
      locale: const Locale('zh'),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _submit() {
    final input = BirthInput(
      year: _date.year,
      month: _date.month,
      day: _date.day,
      hour: _unknownTime ? 12 : _time.hour,
      minute: _unknownTime ? 0 : _time.minute,
      gender: _gender,
      longitude: _city?.longitude ?? 116.41,
      latitude: _city?.latitude ?? 0,
      placeName: _city?.name ?? '',
      timezoneHours: _city?.timezone ?? 8,
      // 真太阳时按出生地经度自动叠加,不再由用户手动开关——省级坐标已经
      // 比只按北京时间准,又不需要用户理解"真太阳时"这个概念。
      // 时间不确定时(按正午排盘)真太阳时修正意义不大,直接关闭。
      useTrueSolarTime: !_unknownTime,
      // 晚子时统一按"次日"处理,这是多数排盘软件的默认口径。
      ziHourMode: ZiHourMode.nextDay,
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? (widget.firstRun ? '命理师 AI' : '出生信息'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.firstRun) ...[
                Text('请填写出生信息', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('所有推算均在本机完成,信息不会上传。', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '姓名(选填,用于姓名测试)'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<Gender>(
                segments: const [
                  ButtonSegment(value: Gender.male, label: Text('男 · 乾造'), icon: Icon(Icons.male)),
                  ButtonSegment(value: Gender.female, label: Text('女 · 坤造'), icon: Icon(Icons.female)),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant)),
                leading: const Icon(Icons.event),
                title: const Text('出生日期(公历)'),
                subtitle: Text('${_date.year} 年 ${_date.month} 月 ${_date.day} 日'),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant)),
                leading: const Icon(Icons.schedule),
                title: const Text('出生时间'),
                subtitle: Text(_unknownTime ? '不确定(按正午排盘,时柱仅供参考)' : _time.format(context)),
                onTap: _unknownTime ? null : _pickTime,
                trailing: Switch(
                  value: !_unknownTime,
                  onChanged: (v) => setState(() => _unknownTime = !v),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<City>(
                value: _city,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '出生地(省/直辖市)'),
                items: [
                  for (final c in cities) DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (c) => setState(() => _city = c),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _submit, child: Text(widget.onSubmit != null ? '确定' : '开始排盘')),
            ],
          ),
        ),
      ),
    );
  }
}
