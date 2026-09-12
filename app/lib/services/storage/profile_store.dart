/// 本地档案存储:命主与合婚对象的出生信息、设置。
///
/// 存的只是用户自己填的生日和地点,用 shared_preferences 足够;
/// 手相面相**不存**任何照片与特征。
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/bazi/bazi_chart.dart';
import '../../core/calendar/lunar_calendar.dart';

class ProfileStore {
  static const _kProfiles = 'profiles.v1';
  static const _kActive = 'profiles.active';
  static const _kServer = 'settings.serverUrl';
  static const _kDeviceId = 'settings.deviceId';
  static const _kConsent = 'settings.consent.v1';
  static const _kLocalInterpretation = 'settings.localInterpretation';

  Future<List<BirthInput>> loadProfiles() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProfiles);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveProfiles(List<BirthInput> profiles) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProfiles, jsonEncode(profiles.map((p) => p.toJson()).toList()));
  }

  Future<int> loadActiveIndex() async =>
      (await SharedPreferences.getInstance()).getInt(_kActive) ?? 0;

  Future<void> saveActiveIndex(int i) async =>
      (await SharedPreferences.getInstance()).setInt(_kActive, i);

  Future<String> loadServerUrl(String fallback) async =>
      (await SharedPreferences.getInstance()).getString(_kServer) ?? fallback;

  Future<void> saveServerUrl(String url) async =>
      (await SharedPreferences.getInstance()).setString(_kServer, url);

  /// 匿名设备 ID,用于后端限流;不是账号。
  Future<String> deviceId() async {
    final sp = await SharedPreferences.getInstance();
    var id = sp.getString(_kDeviceId);
    if (id == null) {
      final now = DateTime.now().microsecondsSinceEpoch;
      id = 'd${now.toRadixString(36)}${(now * 7919 % 1000000).toRadixString(36)}';
      await sp.setString(_kDeviceId, id);
    }
    return id;
  }

  /// 用户是否已同意"面部/手部影像仅在本机处理"的单独告知。
  Future<bool> hasBiometricConsent() async =>
      (await SharedPreferences.getInstance()).getBool(_kConsent) ?? false;

  Future<void> setBiometricConsent(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kConsent, v);

  /// 是否使用离线本地解读(规则引擎生成文字,不联网、不经过任何 AI API)。
  Future<bool> loadUseLocalInterpretation() async =>
      (await SharedPreferences.getInstance()).getBool(_kLocalInterpretation) ?? false;

  Future<void> setUseLocalInterpretation(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kLocalInterpretation, v);

  static BirthInput _fromJson(Map<String, dynamic> j) => BirthInput(
        year: j['year'] as int,
        month: j['month'] as int,
        day: j['day'] as int,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        gender: Gender.values.byName(j['gender'] as String),
        longitude: (j['longitude'] as num).toDouble(),
        latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
        placeName: j['placeName'] as String? ?? '',
        timezoneHours: (j['timezoneHours'] as num?)?.toDouble() ?? chinaTimezoneHours,
        useTrueSolarTime: j['useTrueSolarTime'] as bool? ?? true,
        ziHourMode: ZiHourMode.values.byName(j['ziHourMode'] as String? ?? 'nextDay'),
        name: j['name'] as String? ?? '',
      );
}
