/// 应用状态。
library;

import 'package:flutter/foundation.dart';

import '../core/bazi/bazi_chart.dart';
import '../core/fortune/daily_fortune.dart';
import '../core/marriage/marriage.dart';
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

  String serverUrl = 'http://localhost:8787';
  String deviceId = '';
  bool biometricConsent = false;
  bool serverReachable = false;

  /// 开启后所有"AI 解读"卡片改用本机规则引擎生成文字,不联网、不经过任何 API。
  bool useLocalInterpretation = false;

  ApiClient? _api;
  ApiClient get api => _api ??= ApiClient(baseUrl: serverUrl, deviceId: deviceId);

  BirthInput? get active => profiles.isEmpty ? null : profiles[activeIndex.clamp(0, profiles.length - 1)];

  Future<void> init() async {
    profiles = await _store.loadProfiles();
    activeIndex = await _store.loadActiveIndex();
    serverUrl = await _store.loadServerUrl();
    deviceId = await _store.deviceId();
    biometricConsent = await _store.hasBiometricConsent();
    useLocalInterpretation = await _store.loadUseLocalInterpretation();
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
