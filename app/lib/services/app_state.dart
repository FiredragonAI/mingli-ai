/// 应用状态。
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';

import '../core/bazi/bazi_chart.dart';
import '../core/fortune/daily_fortune.dart';
import '../core/marriage/marriage.dart';
import '../l10n/app_language.dart';
import 'api_client.dart';
import 'storage/profile_store.dart';

class AppState extends ChangeNotifier {
  AppState(this._store);

  final ProfileStore _store;

  List<BirthInput> profiles = [];
  int activeIndex = 0;
  BaziChart? chart;
  BaziChart? partnerChart;
  MarriageResult? marriage;
  DailyFortune? today;

  static const _envUrl = String.fromEnvironment('MINGLI_API_URL');
  static const _envToken = String.fromEnvironment('MINGLI_APP_TOKEN');

  /// 云端解读服务地址。发布版在编译时用
  /// `--dart-define=MINGLI_API_URL=https://…` 注入,用户装上就能用;
  /// 没注入就指向本机开发服务器。
  static String get defaultServerUrl => _envUrl.isEmpty ? 'http://localhost:8787' : _envUrl;

  /// 与服务端 APP_TOKEN 对应的共享口令,同样在编译时注入。
  static String get appToken => _envToken;

  String serverUrl = defaultServerUrl;
  String deviceId = '';
  bool biometricConsent = false;
  bool serverReachable = false;

  /// 开启后所有"AI 解读"卡片改用本机规则引擎生成文字,不联网、不经过任何 API。
  /// 关闭时:云端可达就用 AI,不可达由 AiReadingCard 自动退回本机生成。
  bool useLocalInterpretation = false;

  /// 界面语言;同时决定本机解读的语言与发给云端的输出语言。
  AppLanguage language = AppLanguage.zhHans;

  ApiClient? _api;
  ApiClient get api => _api ??= ApiClient(
        baseUrl: serverUrl,
        deviceId: deviceId,
        appToken: appToken,
        language: language.code,
      );

  bool get isDefaultServerUrl => serverUrl == defaultServerUrl;

  BirthInput? get active => profiles.isEmpty ? null : profiles[activeIndex.clamp(0, profiles.length - 1)];

  Future<void> init() async {
    profiles = await _store.loadProfiles();
    activeIndex = await _store.loadActiveIndex();
    serverUrl = await _store.loadServerUrl(defaultServerUrl);
    deviceId = await _store.deviceId();
    biometricConsent = await _store.hasBiometricConsent();
    useLocalInterpretation = await _store.loadUseLocalInterpretation();
    final savedLang = await _store.loadLanguage();
    language = savedLang == null
        ? AppLanguage.fromSystem(PlatformDispatcher.instance.locale)
        : AppLanguage.fromCode(savedLang);
    if (active != null) _recompute();
    notifyListeners();
    serverReachable = await api.ping();
    notifyListeners();
  }

  void _recompute() {
    final a = active;
    if (a == null) {
      chart = null;
      today = null;
      return;
    }
    chart = computeBaziChart(a);
    today = todayFortune(chart!);
    if (partnerChart != null) marriage = analyzeMarriage(chart!, partnerChart!);
  }

  Future<void> addProfile(BirthInput input, {bool makeActive = true}) async {
    profiles = [...profiles, input];
    if (makeActive) activeIndex = profiles.length - 1;
    await _store.saveProfiles(profiles);
    await _store.saveActiveIndex(activeIndex);
    _recompute();
    notifyListeners();
  }

  Future<void> updateProfile(int index, BirthInput input) async {
    profiles = [...profiles]..[index] = input;
    await _store.saveProfiles(profiles);
    _recompute();
    notifyListeners();
  }

  Future<void> removeProfile(int index) async {
    profiles = [...profiles]..removeAt(index);
    if (activeIndex >= profiles.length) activeIndex = profiles.isEmpty ? 0 : profiles.length - 1;
    await _store.saveProfiles(profiles);
    await _store.saveActiveIndex(activeIndex);
    _recompute();
    notifyListeners();
  }

  Future<void> setActive(int index) async {
    activeIndex = index;
    await _store.saveActiveIndex(index);
    _recompute();
    notifyListeners();
  }

  void setPartner(BirthInput? input) {
    partnerChart = input == null ? null : computeBaziChart(input);
    marriage = (chart != null && partnerChart != null) ? analyzeMarriage(chart!, partnerChart!) : null;
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    serverUrl = url.trim();
    await _store.saveServerUrl(serverUrl);
    _api?.dispose();
    _api = null;
    serverReachable = await api.ping();
    notifyListeners();
  }

  Future<void> resetServerUrl() => setServerUrl(defaultServerUrl);

  /// 重新探测云端是否可达(解读失败后、或从后台回来时调用)。
  Future<void> refreshServerStatus() async {
    final ok = await api.ping();
    if (ok != serverReachable) {
      serverReachable = ok;
      notifyListeners();
    }
  }

  Future<void> grantBiometricConsent() async {
    biometricConsent = true;
    await _store.setBiometricConsent(true);
    notifyListeners();
  }

  Future<void> revokeBiometricConsent() async {
    biometricConsent = false;
    await _store.setBiometricConsent(false);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage l) async {
    if (l == language) return;
    language = l;
    await _store.saveLanguage(l.code);
    _api?.dispose();
    _api = null; // 让新的 ApiClient 带上新的语言
    notifyListeners();
  }

  Future<void> setUseLocalInterpretation(bool v) async {
    useLocalInterpretation = v;
    await _store.setUseLocalInterpretation(v);
    notifyListeners();
  }

  /// 刷新"今日"(跨天后调用)。
  void refreshToday() {
    if (chart != null) {
      today = todayFortune(chart!);
      notifyListeners();
    }
  }
}
