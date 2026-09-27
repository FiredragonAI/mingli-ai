// 生成 SBTI 性格测试 21 个类型的 Q 版形象(SVG),写到 assets/sbti/<slug>.svg。
//
// 为什么程序化生成:一套零件(头、身、发型、眼睛、嘴、道具)拼出 21 个角色,
// 风格天然统一,改一处全局生效;纯几何、纯原创,没有任何第三方素材授权问题;
// 每个文件几 KB,三端离线一致。原版那套低多边形小人是别人的插画,这里一笔不碰。
//
// 用法:dart run tools/gen_sbti_avatars.dart   (在 app/ 目录下)
// 画布 200×200:背景色盘 → 身体 → 手臂 → 头 → 头发 → 脸 → 道具。

import 'dart:io';

// ---------------------------------------------------------------- 零件

const _ink = '#2A2320';
const _skin = '#F6D6BD';
const _skinShade = '#E9B99A';

String _bg(String accent) =>
    '<circle cx="100" cy="104" r="92" fill="$accent" opacity="0.16"/>'
    '<circle cx="100" cy="104" r="92" fill="none" stroke="$accent" stroke-opacity="0.45" stroke-width="2"/>';

String _body(String shirt) =>
    '<rect x="64" y="126" width="72" height="62" rx="24" fill="$shirt"/>'
    '<rect x="88" y="118" width="24" height="16" rx="8" fill="$_skinShade"/>';

String _arms({String left = 'down', String right = 'down'}) {
  String arm(String side, String pose) {
    final x = side == 'l' ? 48 : 130;
    switch (pose) {
      case 'up': // 举起
        return '<rect x="$x" y="112" width="22" height="42" rx="11" fill="$_skin"/>';
      case 'cross': // 叉手:斜着横在胸前
        return side == 'l'
            ? '<rect x="62" y="146" width="46" height="18" rx="9" fill="$_skin" transform="rotate(-14 85 155)"/>'
            : '<rect x="92" y="146" width="46" height="18" rx="9" fill="$_skin" transform="rotate(14 115 155)"/>';
      case 'hold': // 抱东西:收到胸前
        return side == 'l'
            ? '<rect x="56" y="140" width="20" height="36" rx="10" fill="$_skin" transform="rotate(-30 66 158)"/>'
            : '<rect x="124" y="140" width="20" height="36" rx="10" fill="$_skin" transform="rotate(30 134 158)"/>';
      case 'none':
        return '';
      default:
        return '<rect x="$x" y="136" width="22" height="42" rx="11" fill="$_skin"/>';
    }
  }

  return arm('l', left) + arm('r', right);
}

String _head() =>
    '<circle cx="52" cy="92" r="9" fill="$_skin"/><circle cx="148" cy="92" r="9" fill="$_skin"/>'
    '<circle cx="100" cy="88" r="50" fill="$_skin"/>';

String _hair(String style, String color) {
  const base = 'M50 90 Q50 36 100 36 Q150 36 150 90 Q150 66 100 62 Q50 66 50 90Z';
  switch (style) {
    case 'bob':
      return '<path d="M50 96 Q48 34 100 34 Q152 34 150 96 L150 104 Q146 70 100 66 Q54 70 50 104Z" fill="$color"/>';
    case 'spiky':
      return '<path d="M50 84 L58 44 L70 66 L82 30 L100 58 L118 30 L130 66 L142 44 L150 84 Q100 60 50 84Z" fill="$color"/>';
    case 'messy':
      return '<path d="M48 92 Q44 44 76 40 Q86 22 104 36 Q124 24 134 44 Q158 44 152 92 Q142 64 100 62 Q58 64 48 92Z" fill="$color"/>';
    case 'flat':
      return '<path d="$base" fill="$color"/>';
    case 'big':
      return '<path d="M40 100 Q30 26 100 24 Q170 26 160 100 Q152 62 100 58 Q48 62 40 100Z" fill="$color"/>'
          '<path d="M44 96 Q40 130 54 150 Q56 120 60 100Z M156 96 Q160 130 146 150 Q144 120 140 100Z" fill="$color"/>';
    case 'swoop':
      return '<path d="M50 92 Q46 40 96 34 Q150 28 162 60 Q166 44 176 38 Q168 76 150 92 Q144 64 100 62 Q56 66 50 92Z" fill="$color"/>';
    case 'sidepart':
      return '<path d="$base" fill="$color"/>'
          '<path d="M78 40 Q86 56 82 66" fill="none" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="3" stroke-linecap="round"/>';
    case 'bedhead':
      return '<path d="$base" fill="$color"/>'
          '<path d="M66 44 L60 24 L74 40Z M98 38 L104 16 L112 38Z M128 44 L140 28 L134 46Z" fill="$color"/>';
    case 'cowlick':
      return '<path d="$base" fill="$color"/>'
          '<path d="M104 38 Q112 14 126 30" fill="none" stroke="$color" stroke-width="7" stroke-linecap="round"/>';
    case 'round':
      return '<path d="M48 100 Q46 30 100 30 Q154 30 152 100 Q148 68 100 64 Q52 68 48 100Z" fill="$color"/>';
    case 'blown':
      return '<path d="M50 88 Q52 40 100 36 Q140 34 162 50 L178 40 Q164 62 150 90 Q144 64 100 62 Q56 66 50 88Z" fill="$color"/>';
    case 'long':
      return '<path d="M50 96 Q48 34 100 34 Q152 34 150 96 L150 104 Q146 70 100 66 Q54 70 50 104Z" fill="$color"/>'
          '<path d="M50 90 L44 156 Q58 154 62 118Z M150 90 L156 156 Q142 154 138 118Z" fill="$color"/>';
    case 'slick':
      return '<path d="M50 90 Q50 34 100 34 Q150 34 150 90 Q150 62 100 60 Q50 62 50 90Z" fill="$color"/>'
          '<path d="M62 48 Q80 40 98 44" fill="none" stroke="#FFFFFF" stroke-opacity="0.4" stroke-width="3" stroke-linecap="round"/>';
    case 'buzz':
      return '<path d="M52 86 Q52 40 100 40 Q148 40 148 86 Q148 70 100 68 Q52 70 52 86Z" fill="$color" opacity="0.55"/>';
    case 'none':
      return '';
    default:
      throw ArgumentError('unknown hair $style');
  }
}

String _eyes(String style) {
  const lx = 82, rx = 118, y = 92;
  String dot(int cx) =>
      '<ellipse cx="$cx" cy="$y" rx="6" ry="8" fill="$_ink"/><circle cx="${cx + 2}" cy="${y - 3}" r="2" fill="#FFFFFF"/>';
  switch (style) {
    case 'normal':
      return dot(lx) + dot(rx);
    case 'wide':
      return '<ellipse cx="$lx" cy="$y" rx="7" ry="9" fill="$_ink"/><ellipse cx="$rx" cy="$y" rx="7" ry="9" fill="$_ink"/>'
          '<circle cx="84" cy="88" r="2.4" fill="#FFFFFF"/><circle cx="120" cy="88" r="2.4" fill="#FFFFFF"/>';
    case 'side': // 眼珠往旁边看:吃瓜
      return '<ellipse cx="$lx" cy="$y" rx="7" ry="8" fill="#FFFFFF"/><ellipse cx="$rx" cy="$y" rx="7" ry="8" fill="#FFFFFF"/>'
          '<circle cx="86" cy="93" r="4" fill="$_ink"/><circle cx="122" cy="93" r="4" fill="$_ink"/>';
    case 'happy':
      return '<path d="M74 92 Q82 82 90 92" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>'
          '<path d="M110 92 Q118 82 126 92" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>';
    case 'half':
      return '<path d="M74 92 Q82 96 90 92" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>'
          '<path d="M110 92 Q118 96 126 92" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>'
          '<path d="M74 84 L90 84 M110 84 L126 84" stroke="$_ink" stroke-width="2.5" stroke-linecap="round"/>';
    case 'sleepy':
      return '<path d="M74 92 Q82 98 90 92" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>'
          '<path d="M110 92 Q118 98 126 92" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>';
    case 'calm':
      return '<path d="M74 92 Q82 87 90 92" fill="none" stroke="$_ink" stroke-width="3" stroke-linecap="round"/>'
          '<path d="M110 92 Q118 87 126 92" fill="none" stroke="$_ink" stroke-width="3" stroke-linecap="round"/>';
    case 'star':
      String star(int cx) =>
          '<path d="M$cx ${y - 9} L${cx + 3} ${y - 3} L${cx + 9} ${y - 2} L${cx + 4} ${y + 2} L${cx + 6} ${y + 9} L$cx ${y + 5} L${cx - 6} ${y + 9} L${cx - 4} ${y + 2} L${cx - 9} ${y - 2} L${cx - 3} ${y - 3}Z" fill="#F2B705" stroke="$_ink" stroke-width="1.5"/>';
      return star(lx) + star(rx);
    case 'heart':
      String heart(int cx) =>
          '<path d="M$cx ${y + 8} C${cx - 12} ${y - 2} ${cx - 8} ${y - 12} $cx ${y - 4} C${cx + 8} ${y - 12} ${cx + 12} ${y - 2} $cx ${y + 8}Z" fill="#E8567C"/>';
      return heart(lx) + heart(rx);
    case 'angry':
      return dot(lx) + dot(rx) +
          '<path d="M70 76 L92 84 M130 76 L108 84" stroke="$_ink" stroke-width="4" stroke-linecap="round"/>';
    case 'panic':
      return '<circle cx="$lx" cy="$y" r="9" fill="#FFFFFF" stroke="$_ink" stroke-width="2"/><circle cx="$rx" cy="$y" r="9" fill="#FFFFFF" stroke="$_ink" stroke-width="2"/>'
          '<circle cx="$lx" cy="$y" r="3.5" fill="$_ink"/><circle cx="$rx" cy="$y" r="3.5" fill="$_ink"/>';
    case 'shades':
      return '<rect x="66" y="82" width="30" height="20" rx="8" fill="$_ink"/><rect x="104" y="82" width="30" height="20" rx="8" fill="$_ink"/>'
          '<path d="M96 88 L104 88" stroke="$_ink" stroke-width="4"/><path d="M70 88 Q78 84 88 88" stroke="#FFFFFF" stroke-opacity="0.5" stroke-width="2" fill="none"/>';
    case 'dizzy':
      return '<path d="M76 86 L88 98 M88 86 L76 98 M112 86 L124 98 M124 86 L112 98" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>';
    case 'monocle':
      return dot(lx) + dot(rx) +
          '<circle cx="$rx" cy="$y" r="13" fill="none" stroke="#C9A227" stroke-width="2.5"/><path d="M131 96 L138 118" stroke="#C9A227" stroke-width="2"/>';
    case 'smug':
      return '<path d="M74 90 Q82 86 90 92" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>'
          '<path d="M110 92 Q118 86 126 90" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round"/>';
    case 'squint':
      return '<path d="M74 92 L90 92 M110 92 L126 92" stroke="$_ink" stroke-width="4" stroke-linecap="round"/>';
    case 'spiral':
      String sp(int cx) =>
          '<path d="M$cx $y m-7 0 a7 7 0 1 1 7 7 a4.5 4.5 0 1 1 -4.5 -4.5 a2 2 0 1 1 2 2" fill="none" stroke="$_ink" stroke-width="2.2" stroke-linecap="round"/>';
      return sp(lx) + sp(rx);
    default:
      throw ArgumentError('unknown eyes $style');
  }
}

String _mouth(String style) {
  switch (style) {
    case 'smile':
      return '<path d="M90 110 Q100 120 110 110" fill="none" stroke="$_ink" stroke-width="3" stroke-linecap="round"/>';
    case 'o':
      return '<ellipse cx="100" cy="113" rx="5" ry="6" fill="$_ink"/>';
    case 'grin':
      return '<path d="M86 108 Q100 128 114 108Z" fill="$_ink"/><path d="M90 109 Q100 114 110 109Z" fill="#FFFFFF"/>';
    case 'flat':
      return '<path d="M92 112 L108 112" stroke="$_ink" stroke-width="3" stroke-linecap="round"/>';
    case 'wavy':
      return '<path d="M88 112 Q94 106 100 112 Q106 118 112 112" fill="none" stroke="$_ink" stroke-width="3" stroke-linecap="round"/>';
    case 'open':
      return '<ellipse cx="100" cy="114" rx="8" ry="7" fill="$_ink"/><ellipse cx="100" cy="117" rx="5" ry="3" fill="#E8567C"/>';
    case 'smirk':
      return '<path d="M90 112 Q102 118 112 106" fill="none" stroke="$_ink" stroke-width="3" stroke-linecap="round"/>';
    case 'tiny':
      return '<path d="M96 112 L104 112" stroke="$_ink" stroke-width="2.5" stroke-linecap="round"/>';
    case 'pout':
      return '<path d="M92 114 Q100 108 108 114" fill="none" stroke="$_ink" stroke-width="3" stroke-linecap="round"/>';
    default:
      throw ArgumentError('unknown mouth $style');
  }
}

const _blush = '<circle cx="66" cy="104" r="6" fill="#F28C8C" opacity="0.55"/><circle cx="134" cy="104" r="6" fill="#F28C8C" opacity="0.55"/>';
const _sweat = '<path d="M146 66 Q152 78 146 82 Q140 78 146 66Z" fill="#7FB8E6"/>';

/// 气泡(左上或右上),内容由调用方画在气泡里。
String _bubble(bool right, String inner) {
  final x = right ? 128 : 22;
  final tail = right ? 'M140 62 L136 74 L150 66Z' : 'M60 62 L64 74 L50 66Z';
  return '<rect x="$x" y="28" width="50" height="36" rx="12" fill="#FFFFFF" stroke="$_ink" stroke-width="2"/><path d="$tail" fill="#FFFFFF" stroke="$_ink" stroke-width="2"/>'
      '<path d="$tail" fill="#FFFFFF"/>$inner';
}

// ---------------------------------------------------------------- 21 个角色

class _Spec {
  const _Spec(this.slug, {required this.accent, required this.shirt, required this.hair, required this.hairColor, required this.eyes, required this.mouth, this.blush = false, this.arms = const ['down', 'down'], this.behind = '', this.front = ''});
  final String slug;
  final String accent;
  final String shirt;
  final String hair;
  final String hairColor;
  final String eyes;
  final String mouth;
  final bool blush;
  final List<String> arms;

  /// 画在人物后面的道具(聚光灯、枕头、气泡……)。
  final String behind;

  /// 画在人物前面的道具(西瓜、爆米花、手机……)。
  final String front;
}

final _specs = <_Spec>[
  // 吃瓜群众:抱着一块西瓜,眼珠往旁边瞟
  _Spec('melon', accent: '#4F9D69', shirt: '#7FC8A9', hair: 'bob', hairColor: '#3B2A22', eyes: 'side', mouth: 'o', arms: ['hold', 'hold'],
      front: '<path d="M62 158 A38 38 0 0 0 138 158Z" fill="#E8503A"/><path d="M58 158 A42 42 0 0 0 142 158 L138 158 A38 38 0 0 1 62 158Z" fill="#3E9A5A"/>'
          '<ellipse cx="86" cy="172" rx="2.5" ry="4" fill="$_ink"/><ellipse cx="100" cy="180" rx="2.5" ry="4" fill="$_ink"/><ellipse cx="114" cy="172" rx="2.5" ry="4" fill="$_ink"/>'
          '<circle cx="64" cy="164" r="9" fill="$_skin"/><circle cx="136" cy="164" r="9" fill="$_skin"/>'),
  // 乐子人:笑弯了眼,抱一桶爆米花
  _Spec('lol_r', accent: '#E0563E', shirt: '#F2C14E', hair: 'spiky', hairColor: '#2B2B2B', eyes: 'happy', mouth: 'grin', blush: true, arms: ['hold', 'hold'],
      front: '<rect x="74" y="146" width="52" height="44" rx="6" fill="#FFFFFF" stroke="$_ink" stroke-width="2"/>'
          '<rect x="82" y="146" width="8" height="44" fill="#E0563E"/><rect x="98" y="146" width="8" height="44" fill="#E0563E"/><rect x="114" y="146" width="8" height="44" fill="#E0563E"/>'
          '<circle cx="82" cy="142" r="7" fill="#FFF4D6" stroke="$_ink" stroke-width="1.5"/><circle cx="96" cy="136" r="8" fill="#FFF4D6" stroke="$_ink" stroke-width="1.5"/><circle cx="110" cy="140" r="7" fill="#FFF4D6" stroke="$_ink" stroke-width="1.5"/><circle cx="120" cy="146" r="6" fill="#FFF4D6" stroke="$_ink" stroke-width="1.5"/>'
          '<circle cx="66" cy="168" r="9" fill="$_skin"/><circle cx="134" cy="168" r="9" fill="$_skin"/>'),
  // 内耗人:眼睛转圈,头顶三个越来越大的思考泡
  _Spec('loop', accent: '#7B6BB0', shirt: '#B9A9E0', hair: 'messy', hairColor: '#4A3B6B', eyes: 'spiral', mouth: 'wavy',
      behind: '<circle cx="146" cy="46" r="5" fill="#FFFFFF" stroke="$_ink" stroke-width="1.5"/><circle cx="158" cy="32" r="8" fill="#FFFFFF" stroke="$_ink" stroke-width="1.5"/><circle cx="176" cy="16" r="12" fill="#FFFFFF" stroke="$_ink" stroke-width="1.5"/>'
          '<path d="M176 16 m-5 0 a5 5 0 1 1 5 5 a3 3 0 1 1 -3 -3" fill="none" stroke="$_ink" stroke-width="1.5"/>',
      front: _sweat),
  // 淡人:半睁眼,直线嘴,手里一杯白开水
  _Spec('lite', accent: '#9AA3AD', shirt: '#D5DAE0', hair: 'flat', hairColor: '#8A8F98', eyes: 'half', mouth: 'flat', arms: ['down', 'up'],
      front: '<rect x="134" y="102" width="18" height="24" rx="3" fill="#EAF4FB" stroke="$_ink" stroke-width="1.5"/><rect x="134" y="112" width="18" height="14" rx="2" fill="#BFE0F5"/>'),
  // 浓人:爆炸头,星星眼,礼花
  _Spec('max', accent: '#F26B8A', shirt: '#FF9AB5', hair: 'big', hairColor: '#D94F8A', eyes: 'star', mouth: 'grin', blush: true, arms: ['up', 'up'],
      behind: '<rect x="20" y="40" width="8" height="8" fill="#F2B705" transform="rotate(20 24 44)"/><rect x="170" y="30" width="8" height="8" fill="#4F9D69" transform="rotate(-25 174 34)"/><rect x="30" y="120" width="7" height="7" fill="#2E86AB" transform="rotate(40 33 123)"/><rect x="176" y="112" width="8" height="8" fill="#E0563E" transform="rotate(15 180 116)"/><rect x="160" y="150" width="6" height="6" fill="#F2B705"/><rect x="22" y="160" width="6" height="6" fill="#D94F8A" transform="rotate(30 25 163)"/>'),
  // 显眼包:大背头,眨眼,背后两道聚光灯
  _Spec('show_y', accent: '#F2A900', shirt: '#F5D26B', hair: 'swoop', hairColor: '#F2A900', eyes: 'normal', mouth: 'smirk', blush: true, arms: ['up', 'down'],
      behind: '<path d="M30 8 L70 120 L10 120Z" fill="#FFE27A" opacity="0.5"/><path d="M170 8 L190 120 L130 120Z" fill="#FFE27A" opacity="0.5"/>'
          '<path d="M40 60 l3 -8 l3 8 l8 3 l-8 3 l-3 8 l-3 -8 l-8 -3Z" fill="#FFFFFF"/><path d="M160 76 l2 -6 l2 6 l6 2 l-6 2 l-2 6 l-2 -6 l-6 -2Z" fill="#FFFFFF"/>'),
  // 卷王:三七分,皱眉,笔记本 + 咖啡 + 汗
  _Spec('juan', accent: '#C0392B', shirt: '#E07A5F', hair: 'sidepart', hairColor: '#1F1F1F', eyes: 'angry', mouth: 'flat', arms: ['hold', 'hold'],
      front: '<rect x="66" y="150" width="68" height="36" rx="4" fill="#4A4A4A"/><rect x="72" y="154" width="56" height="26" rx="2" fill="#9FD3F5"/><rect x="60" y="184" width="80" height="6" rx="2" fill="#6B6B6B"/>'
          '<rect x="146" y="150" width="18" height="22" rx="3" fill="#FFFFFF" stroke="$_ink" stroke-width="1.5"/><path d="M164 156 Q172 160 164 168" fill="none" stroke="$_ink" stroke-width="1.5"/><path d="M152 144 Q154 138 152 132 M158 142 Q160 136 158 130" fill="none" stroke="#9A9A9A" stroke-width="1.5" stroke-linecap="round"/>'
          '$_sweat'),
  // 摆烂人:鸡窝头,困眼,裹着毯子
  _Spec('lan', accent: '#A08C7A', shirt: '#C9B79C', hair: 'bedhead', hairColor: '#6B4F3A', eyes: 'sleepy', mouth: 'tiny', arms: ['none', 'none'],
      front: '<path d="M58 132 Q100 118 142 132 L146 190 L54 190Z" fill="#8FB3D9"/><path d="M58 150 L142 150 M58 168 L142 168" stroke="#FFFFFF" stroke-opacity="0.5" stroke-width="3"/>'),
  // 杠精:呆毛,怒眉,叉手,气泡里一个感叹号
  _Spec('nope', accent: '#2E86AB', shirt: '#7EB6D9', hair: 'cowlick', hairColor: '#2E4A62', eyes: 'angry', mouth: 'open', arms: ['cross', 'cross'],
      behind: _bubbleExclaim),
  // 老好人:圆发,笑眼带汗,竖大拇指,气泡里一个对勾
  _Spec('ok_r', accent: '#E9A23B', shirt: '#F5C77E', hair: 'round', hairColor: '#7A5C3E', eyes: 'happy', mouth: 'smile', blush: true, arms: ['down', 'up'],
      behind: _bubbleCheck,
      front: '<rect x="132" y="98" width="20" height="18" rx="6" fill="$_skin"/><rect x="138" y="84" width="9" height="20" rx="4.5" fill="$_skin"/>$_sweat'),
  // 死线战神:头发往后吹,惊恐眼,旁边一个冒闪电的钟,身后速度线
  _Spec('ddl', accent: '#D35400', shirt: '#F39C6B', hair: 'blown', hairColor: '#3A3A3A', eyes: 'panic', mouth: 'open', arms: ['up', 'up'],
      behind: '<path d="M14 120 L44 120 M10 136 L40 136 M16 152 L46 152" stroke="$_ink" stroke-opacity="0.35" stroke-width="3" stroke-linecap="round"/>'
          '<circle cx="164" cy="44" r="20" fill="#FFFFFF" stroke="$_ink" stroke-width="2.5"/><path d="M164 44 L164 30 M164 44 L174 50" stroke="$_ink" stroke-width="2.5" stroke-linecap="round"/>'
          '<path d="M186 10 L176 26 L184 26 L174 42" fill="none" stroke="#F2B705" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
      front: _sweat),
  // 装睡人:闭眼,抱枕头,三个 Z
  _Spec('zzz', accent: '#6C7A89', shirt: '#A9B7C6', hair: 'flat', hairColor: '#5B4636', eyes: 'sleepy', mouth: 'tiny', arms: ['hold', 'hold'],
      behind: '<path d="M144 60 L156 60 L144 72 L156 72" fill="none" stroke="$_ink" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>'
          '<path d="M158 40 L174 40 L158 56 L174 56" fill="none" stroke="$_ink" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'
          '<path d="M174 14 L194 14 L174 34 L194 34" fill="none" stroke="$_ink" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>',
      front: '<rect x="62" y="150" width="76" height="34" rx="14" fill="#FFFFFF" stroke="$_ink" stroke-width="1.5"/><circle cx="66" cy="166" r="9" fill="$_skin"/><circle cx="134" cy="166" r="9" fill="$_skin"/>'),
  // 恋爱脑:心形眼,发夹,举着有红心的手机,周围飘心
  _Spec('simp', accent: '#E56B8C', shirt: '#F4A7B9', hair: 'bob', hairColor: '#B3472A', eyes: 'heart', mouth: 'smile', blush: true, arms: ['down', 'up'],
      behind: '<path d="M30 60 C22 52 26 40 34 44 C42 40 46 52 38 60 L34 64Z" fill="#E8567C"/><path d="M172 100 C166 94 168 86 174 88 C180 86 182 94 176 100 L174 102Z" fill="#E8567C"/><path d="M158 140 C154 136 156 130 160 132 C164 130 166 136 162 140 L160 142Z" fill="#E8567C"/>',
      front: '<rect x="134" y="96" width="20" height="32" rx="4" fill="$_ink"/><rect x="137" y="100" width="14" height="24" rx="2" fill="#FFFFFF"/><path d="M144 116 C138 110 140 104 144 106 C148 104 150 110 144 116Z" fill="#E8567C"/>'
          '<path d="M62 46 L72 42 L70 52Z" fill="#E8567C"/>'),
  // 精神股东:背头,单片镜,领带,气泡里一根往上的箭头
  _Spec('ceo', accent: '#1F5F8B', shirt: '#2F3E4E', hair: 'slick', hairColor: '#2C2C2C', eyes: 'monocle', mouth: 'smirk', arms: ['cross', 'cross'],
      behind: _bubbleArrow,
      front: '<path d="M100 130 L92 140 L100 176 L108 140Z" fill="#C0392B"/>'),
  // 月光侠:蒙圈眼,空钱包里飞出一只飞蛾
  _Spec('zero', accent: '#8E7CC3', shirt: '#B8A9DC', hair: 'messy', hairColor: '#6E5A9E', eyes: 'dizzy', mouth: 'wavy', arms: ['hold', 'hold'],
      front: '<rect x="70" y="150" width="60" height="36" rx="6" fill="#8B5A2B"/><rect x="70" y="150" width="60" height="12" rx="6" fill="#6E4520"/>'
          '<ellipse cx="104" cy="126" rx="9" ry="6" fill="#D9C7A0" transform="rotate(-20 104 126)"/><ellipse cx="116" cy="122" rx="9" ry="6" fill="#D9C7A0" transform="rotate(20 116 122)"/><circle cx="110" cy="126" r="3" fill="$_ink"/>'
          '<circle cx="70" cy="168" r="9" fill="$_skin"/><circle cx="130" cy="168" r="9" fill="$_skin"/>'),
  // 玄学人:长发,闭目,捧水晶球,周围星星
  _Spec('xuan', accent: '#6A4C93', shirt: '#9B7FC9', hair: 'long', hairColor: '#3E2F5B', eyes: 'calm', mouth: 'tiny', arms: ['hold', 'hold'],
      behind: '<path d="M26 40 l2 -7 l2 7 l7 2 l-7 2 l-2 7 l-2 -7 l-7 -2Z" fill="#F2B705"/><path d="M176 66 l2 -6 l2 6 l6 2 l-6 2 l-2 6 l-2 -6 l-6 -2Z" fill="#F2B705"/><circle cx="168" cy="30" r="3" fill="#F2B705"/>',
      front: '<circle cx="100" cy="164" r="24" fill="#B79CE8"/><circle cx="100" cy="164" r="24" fill="none" stroke="#6A4C93" stroke-width="2"/><circle cx="92" cy="156" r="6" fill="#FFFFFF" opacity="0.7"/>'
          '<rect x="80" y="186" width="40" height="8" rx="3" fill="#6A4C93"/><circle cx="72" cy="170" r="9" fill="$_skin"/><circle cx="128" cy="170" r="9" fill="$_skin"/>'),
  // 电子佛:寸头 + 光环,闭目微笑,抱木鱼
  _Spec('muyu', accent: '#C9A227', shirt: '#E8D08A', hair: 'buzz', hairColor: '#3A3A3A', eyes: 'calm', mouth: 'smile', arms: ['hold', 'hold'],
      behind: '<ellipse cx="100" cy="30" rx="34" ry="9" fill="none" stroke="#F2B705" stroke-width="4"/>',
      front: '<path d="M72 152 Q100 136 128 152 Q132 176 100 182 Q68 176 72 152Z" fill="#B0782E"/><path d="M84 160 Q100 154 116 160" fill="none" stroke="#6E4520" stroke-width="3" stroke-linecap="round"/>'
          '<rect x="136" y="128" width="6" height="26" rx="3" fill="#8B5A2B" transform="rotate(-30 139 141)"/><circle cx="146" cy="124" r="5" fill="#B0782E"/>'
          '<circle cx="70" cy="168" r="9" fill="$_skin"/><circle cx="130" cy="168" r="9" fill="$_skin"/>'),
  // 复读机:两边各一个 +1 气泡
  _Spec('echo', accent: '#5A9E5A', shirt: '#9CD39C', hair: 'flat', hairColor: '#4A6B3A', eyes: 'normal', mouth: 'smile',
      behind: _bubblePlusOne(false) + _bubblePlusOne(true)),
  // 已读不回人:整个人是一只小幽灵,手里手机顶着红点
  _Spec('ghost', accent: '#7F8C8D', shirt: '#FFFFFF', hair: 'none', hairColor: '', eyes: 'normal', mouth: 'tiny', blush: true, arms: ['none', 'none'],
      front: '<rect x="128" y="120" width="20" height="32" rx="4" fill="$_ink"/><rect x="131" y="124" width="14" height="24" rx="2" fill="#FFFFFF"/><circle cx="148" cy="120" r="6" fill="#E0563E"/>'),
  // 自信过头:金发,墨镜,王冠,闪光
  _Spec('god', accent: '#F1C40F', shirt: '#F7DC6F', hair: 'swoop', hairColor: '#E8B923', eyes: 'shades', mouth: 'smirk', arms: ['cross', 'cross'],
      behind: '<path d="M64 42 L72 18 L86 36 L100 12 L114 36 L128 18 L136 42Z" fill="#F2B705" stroke="$_ink" stroke-width="2" stroke-linejoin="round"/><circle cx="72" cy="18" r="3" fill="#E0563E"/><circle cx="100" cy="12" r="3" fill="#E0563E"/><circle cx="128" cy="18" r="3" fill="#E0563E"/>'
          '<path d="M24 70 l3 -8 l3 8 l8 3 l-8 3 l-3 8 l-3 -8 l-8 -3Z" fill="#FFFFFF"/><path d="M172 56 l2 -6 l2 6 l6 2 l-6 2 l-2 6 l-2 -6 l-6 -2Z" fill="#FFFFFF"/>'),
  // 铁公鸡:头顶红鸡冠,眯眼,双手死死攥着一枚硬币
  _Spec('iron', accent: '#7F6A4A', shirt: '#BFA97F', hair: 'flat', hairColor: '#8C6A4A', eyes: 'squint', mouth: 'pout', arms: ['hold', 'hold'],
      behind: '<path d="M78 40 Q84 20 92 38 Q100 16 108 38 Q116 20 122 40Z" fill="#E0563E"/>',
      front: '<circle cx="100" cy="160" r="20" fill="#F2B705" stroke="#B8860B" stroke-width="3"/><circle cx="100" cy="160" r="12" fill="none" stroke="#B8860B" stroke-width="2"/>'
          '<circle cx="76" cy="164" r="10" fill="$_skin"/><circle cx="124" cy="164" r="10" fill="$_skin"/>'),
];

// 气泡内容
final _bubbleExclaim = _bubble(true, '<rect x="150" y="34" width="6" height="16" rx="3" fill="#C0392B"/><circle cx="153" cy="57" r="3.5" fill="#C0392B"/>');
final _bubbleCheck = _bubble(true, '<path d="M142 46 L150 54 L164 38" fill="none" stroke="#4F9D69" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>');
final _bubbleArrow = _bubble(true, '<path d="M138 56 L150 44 L156 50 L168 36" fill="none" stroke="#4F9D69" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M160 36 L168 36 L168 44" fill="none" stroke="#4F9D69" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>');
String _bubblePlusOne(bool right) {
  final x = right ? 128 : 22;
  return _bubble(right, '<rect x="${x + 10}" y="44" width="12" height="3" fill="$_ink"/><rect x="${x + 14.5}" y="39.5" width="3" height="12" fill="$_ink"/><rect x="${x + 30}" y="38" width="3.5" height="16" fill="$_ink"/><path d="M${x + 26} 42 L${x + 32} 38" stroke="$_ink" stroke-width="3" stroke-linecap="round"/>');
}

// ---------------------------------------------------------------- 拼装

String _render(_Spec s) {
  final b = StringBuffer()
    ..write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">')
    ..write(_bg(s.accent))
    ..write(s.behind);
  if (s.slug == 'ghost') {
    // 幽灵:一整块白色身体代替头 + 身,底边波浪
    b.write('<path d="M52 96 Q52 40 100 40 Q148 40 148 96 L148 176 Q140 166 132 178 Q124 190 116 178 Q108 166 100 178 Q92 190 84 178 Q76 166 68 178 Q60 190 52 176Z" fill="#FFFFFF" stroke="$_ink" stroke-width="2"/>');
  } else {
    b
      ..write(_body(s.shirt))
      ..write(_arms(left: s.arms[0], right: s.arms[1]))
      ..write(_head())
      ..write(_hair(s.hair, s.hairColor));
  }
  b
    ..write(_eyes(s.eyes))
    ..write(_mouth(s.mouth))
    ..write(s.blush ? _blush : '')
    ..write(s.front)
    ..write('</svg>');
  return b.toString();
}

void main() {
  final dir = Directory('assets/sbti')..createSync(recursive: true);
  var total = 0;
  for (final s in _specs) {
    final svg = _render(s);
    File('${dir.path}/${s.slug}.svg').writeAsStringSync(svg);
    total += svg.length;
    print('${s.slug.padRight(8)} ${svg.length} B');
  }
  print('共 ${_specs.length} 个,合计 ${(total / 1024).toStringAsFixed(1)} KB');
}
