/// 应用状态。
library;

import 'dart:async' show unawaited;
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
    if (savedLang != null) {
      language = AppLanguage.fromCode(savedLang);
    } else if (profiles.isNotEmpty) {
      // 升级上来的老用户:之前只有简体,别因为系统语言突然变成英文
      language = AppLanguage.zhHans;
    } else {
      language = AppLanguage.fromSystem(PlatformDispatcher.instance.locale);
    }
    if (active != null) _recompute();
    notifyListeners();
    // 故意不 await:这个 ping 可能要等几十秒(见 refreshServerStatus 的说明),
    // 启动页不能陪着挂。先把界面放出去,可达状态回来了再 notify。
    unawaited(refreshServerStatus());
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

  /// 探测云端是否可达,**顺便把它叫醒**(启动时、解读失败后调用)。
  ///
  /// 服务端在 Render 免费档上,闲置 15 分钟就休眠,冷启动 Render 自己说
  /// "can delay requests by 50 seconds or more"。所以这个请求有两重作用:
  /// 判断可达性,以及用它把实例唤醒——等用户看完命盘再去点 AI 解读时,
  /// 服务端已经热了。
  ///
  /// 两张 AI 卡都是拿 [serverReachable] 决定灰不灰的,所以**不能**因为冷启动慢
  /// 就判成"不可达":那样封闭测试的人隔一会儿打开 app,卡永远是灰的,
  /// 而且灰了就发不出请求,也就没有失败能触发重新探测——死在那儿了。
  /// ping 的超时放宽到 90 秒就是为了盖住冷启动,见 ApiClient.ping。
  ///
  /// 纯离线包不受影响:它的地址是 localhost:8787,没人监听,connection refused
  /// 立刻返回,不会在这儿等满 90 秒,卡照样自动灰掉。
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
