/// 后端 API 客户端。
///
/// 客户端**从不**持有大模型密钥。所有解读请求都带着结构化盘面 JSON 打到自建后端,
/// 后端再调用 Claude。请求体里只有推算结果和几何特征,没有照片、没有原始关键点。
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../platform/native.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 解读结果。
class Interpretation {
  const Interpretation({
    required this.text,
    required this.sections,
    required this.cached,
    required this.model,
  });

  /// 全文(Markdown)。
  final String text;

  /// 分段:{标题: 内容}。
  final Map<String, String> sections;
  final bool cached;
  final String model;

  factory Interpretation.fromJson(Map<String, dynamic> j) => Interpretation(
        text: j['text'] as String? ?? '',
        sections: {
          for (final e in ((j['sections'] as Map<String, dynamic>?) ?? {}).entries)
            e.key: e.value as String,
        },
        cached: j['cached'] as bool? ?? false,
        model: j['model'] as String? ?? '',
      );
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.deviceId,
    this.appToken = '',
    this.language = 'zh-Hans',
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String deviceId;

  /// 与服务端 APP_TOKEN 一致的共享口令;空则不发。
  final String appToken;

  /// 希望模型用哪种语言写解读:zh-Hans / zh-Hant / en。
  final String language;
  final http.Client _client;
  final Duration timeout;

  static const appVersion = '0.1.0';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        'X-Device-Id': deviceId,
        'X-App-Version': appVersion,
        'X-Platform': osName,
        if (appToken.isNotEmpty) 'X-App-Token': appToken,
      };

  Future<Interpretation> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final http.Response res;
    try {
      res = await _client
          .post(uri, headers: _headers, body: jsonEncode({...body, 'language': language}))
          .timeout(timeout);
    } on http.ClientException catch (e) {
      // 传输层失败(断网、DNS、连接被拒)。package:http 在各平台都统一抛这个:
      // 原生端包着 SocketException,Web 端包着 fetch 失败——所以不再直接捕 dart:io 的类型。
      throw ApiException(0, '网络不可用:${e.message}');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Interpretation.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    String msg;
    try {
      msg = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['error']?.toString() ?? res.reasonPhrase ?? '';
    } catch (_) {
      msg = res.reasonPhrase ?? '请求失败';
    }
    throw ApiException(res.statusCode, msg);
  }

  /// 八字详批。[chart] 为 `BaziChart.toJson()`。
  Future<Interpretation> interpretBazi(Map<String, dynamic> chart, {String focus = 'overview'}) =>
      _post('/v1/interpret/bazi', {'chart': chart, 'focus': focus});

  /// 每日运势文案。
  Future<Interpretation> interpretDaily(Map<String, dynamic> chart, Map<String, dynamic> fortune) =>
      _post('/v1/interpret/daily', {'chart': chart, 'fortune': fortune});

  /// 合婚。
  Future<Interpretation> interpretMarriage(Map<String, dynamic> marriage) =>
      _post('/v1/interpret/marriage', {'marriage': marriage});

  /// 姓名。
  Future<Interpretation> interpretName(Map<String, dynamic> name, Map<String, dynamic>? chart) =>
      _post('/v1/interpret/name', {'name': name, 'chart': chart});

  /// 黄历择日说明。
  Future<Interpretation> interpretAlmanac(Map<String, dynamic> almanac, Map<String, dynamic>? chart) =>
      _post('/v1/interpret/almanac', {'almanac': almanac, 'chart': chart});

  /// 手相。[features] 为 `PalmFeatures.toJson()`,不含图像。
  Future<Interpretation> interpretPalm(Map<String, dynamic> features, Map<String, dynamic>? chart) =>
      _post('/v1/interpret/palm', {'features': features, 'chart': chart});

  /// 面相。[features] 为 `FaceFeatures.toJson()`,不含图像。
  Future<Interpretation> interpretFace(Map<String, dynamic> features, Map<String, dynamic>? chart) =>
      _post('/v1/interpret/face', {'features': features, 'chart': chart});

  /// 单人婚缘。[love] 为 `LoveForecast.toJson()`。
  Future<Interpretation> interpretLove(Map<String, dynamic> chart, Map<String, dynamic> love) =>
      _post('/v1/interpret/love', {'chart': chart, 'love': love});

  /// 流年。[annual] 为 `AnnualFortune.toJson()`。
  Future<Interpretation> interpretAnnual(Map<String, dynamic> chart, Map<String, dynamic> annual) =>
      _post('/v1/interpret/annual', {'chart': chart, 'annual': annual});

  /// 星座。[zodiac] 为 `ZodiacProfile.toJson()`,[match] 为 `ZodiacMatch.toJson()`。
  Future<Interpretation> interpretZodiac(
    Map<String, dynamic> zodiac,
    Map<String, dynamic>? match,
    Map<String, dynamic>? chart,
  ) =>
      _post('/v1/interpret/zodiac', {'zodiac': zodiac, 'match': match, 'chart': chart});

  /// 健康检查。
  Future<bool> ping() async {
    try {
      final res = await _client.get(Uri.parse('$baseUrl/healthz')).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}
