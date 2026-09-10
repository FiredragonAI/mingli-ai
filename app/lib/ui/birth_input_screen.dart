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
  final _lonCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _trueSolar = true;
  ZiHourMode _ziMode = ZiHourMode.nextDay;
  bool _unknownTime = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _date = DateTime(i.year, i.month, i.day);
      _time = TimeOfDay(hour: i.hour, minute: i.minute);
      _gender = i.gender;
      _lonCtrl.text = i.longitude.toStringAsFixed(2);
      _nameCtrl.text = i.name;
      _trueSolar = i.useTrueSolarTime;
      _ziMode = i.ziHourMode;
      _city = cities.where((c) => c.name == i.placeName).firstOrNull;
    } else {
      _date = DateTime(1995, 6, 15);
      _time = const TimeOfDay(hour: 12, minute: 0);
      _city = cities.first;
      _lonCtrl.text = _city!.longitude.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _lonCtrl.dispose();
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
    final lon = double.tryParse(_lonCtrl.text);
    if (lon == null || lon < -180 || lon > 180) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('经度需在 −180 到 180 之间')));
      return;
    }
    final input = BirthInput(
      year: _date.year,
      month: _date.month,
      day: _date.day,
      hour: _unknownTime ? 12 : _time.hour,
      minute: _unknownTime ? 0 : _time.minute,
      gender: _gender,
      longitude: lon,
      latitude: _city?.latitude ?? 0,
      placeName: _city?.name ?? '',
      timezoneHours: _city?.timezone ?? 8,
      useTrueSolarTime: _trueSolar && !_unknownTime,
      ziHourMode: _ziMode,
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
                decoration: const InputDecoration(labelText: '出生地'),
                items: [
                  for (final c in cities) DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (c) => setState(() {
                  _city = c;
                  if (c != null) _lonCtrl.text = c.longitude.toStringAsFixed(2);
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lonCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: '经度(东经为正)',
                  helperText: '选城市自动填入;县级以下地区可手动微调',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('按真太阳时排盘'),
                subtitle: const Text('叠加经度差与均时差,专业口径'),
                value: _trueSolar && !_unknownTime,
                onChanged: _unknownTime ? null : (v) => setState(() => _trueSolar = v),
              ),
              ListTile(
                title: const Text('晚子时(23:00 后)'),
                subtitle: Text(_ziMode.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final m = await showModalBottomSheet<ZiHourMode>(
                    context: context,
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final m in ZiHourMode.values)
                          ListTile(title: Text(m.label), onTap: () => Navigator.pop(context, m)),
                      ],
                    ),
                  );
                  if (m != null) setState(() => _ziMode = m);
                },
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
