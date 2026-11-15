// ping 必须扛得住服务端冷启动。
//
// 服务端在 Render 免费档,闲置 15 分钟休眠,冷启动官方口径"可能延迟 50 秒以上"。
// 这里原来是 5 秒超时,后果不是"慢一点",而是功能直接没了:
// ping 超时 → serverReachable=false → 两张 AI 卡灰掉 → 灰掉就发不出请求
// → 没有失败能触发重新探测 → 用户再也拿不到云端解读。
// 封闭测试这种零散使用几乎每次打开都是冷的,所以这条路必须走通。
//
// 这个测试守的就是"别再把超时调回几秒"。用 fake_async 拨快时钟,
// 所以跑起来是瞬时的,不会真等几十秒。

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mingli_ai/services/api_client.dart';

ApiClient clientThatRespondsAfter(Duration delay, {int status = 200}) => ApiClient(
      baseUrl: 'https://example.invalid',
      deviceId: 'test-device',
      client: MockClient((_) async {
        await Future<void>.delayed(delay);
        return http.Response('{"ok":true}', status);
      }),
    );

void main() {
  test('服务端冷启动等了 40 秒,ping 仍然算可达', () {
    fakeAsync((async) {
      bool? result;
      clientThatRespondsAfter(const Duration(seconds: 40)).ping().then((v) => result = v);
      async.elapse(const Duration(seconds: 45));
      expect(result, isTrue, reason: '40 秒是 Render 冷启动的正常范围,不能判成不可达');
    });
  });

  test('等到 80 秒也还算可达(冷启动可能很久)', () {
    fakeAsync((async) {
      bool? result;
      clientThatRespondsAfter(const Duration(seconds: 80)).ping().then((v) => result = v);
      async.elapse(const Duration(seconds: 85));
      expect(result, isTrue);
    });
  });

  test('超过 90 秒才算不可达', () {
    fakeAsync((async) {
      bool? result;
      clientThatRespondsAfter(const Duration(seconds: 120)).ping().then((v) => result = v);
      async.elapse(const Duration(seconds: 150));
      expect(result, isFalse, reason: '总得有个上限,不能无限等');
    });
  });

  test('真的连不上(离线包指向 localhost)时立刻返回 false,卡片照常灰掉', () {
    fakeAsync((async) {
      bool? result;
      ApiClient(
        baseUrl: 'http://localhost:8787',
        deviceId: 'test-device',
        client: MockClient((_) async => throw const _ConnectionRefused()),
      ).ping().then((v) => result = v);
      // 关键:不拨时钟也要有结果——连接被拒是立刻返回的,不会空等 90 秒
      async.flushMicrotasks();
      expect(result, isFalse);
    });
  });

  test('服务端回非 200 时算不可达', () {
    fakeAsync((async) {
      bool? result;
      clientThatRespondsAfter(Duration.zero, status: 503).ping().then((v) => result = v);
      // Future.delayed(zero) 也要走一次时钟,flushMicrotasks 不够
      async.elapse(const Duration(milliseconds: 1));
      expect(result, isFalse);
    });
  });
}

/// 模拟"连接被拒"。ping 内部 catch 所有异常,所以具体类型不重要。
class _ConnectionRefused implements Exception {
  const _ConnectionRefused();
  @override
  String toString() => 'Connection refused';
}
