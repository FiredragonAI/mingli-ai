/// 五行及其生克关系。
library;

/// 五行。顺序即相生顺序:木生火、火生土、土生金、金生水、水生木。
enum Element {
  wood('木'),
  fire('火'),
  earth('土'),
  metal('金'),
  water('水');

  const Element(this.label);
  final String label;

  /// 我生者。
  Element get generates => Element.values[(index + 1) % 5];

  /// 生我者。
  Element get generatedBy => Element.values[(index + 4) % 5];

  /// 我克者(隔一位)。
  Element get controls => Element.values[(index + 2) % 5];

  /// 克我者。
  Element get controlledBy => Element.values[(index + 3) % 5];

  /// [other] 相对于本五行的关系。
  ElementRelation relationTo(Element other) {
    if (other == this) return ElementRelation.same;
    if (other == generates) return ElementRelation.iGenerate;
    if (other == generatedBy) return ElementRelation.generatesMe;
    if (other == controls) return ElementRelation.iControl;
    return ElementRelation.controlsMe;
  }
}

/// 两个五行之间的关系,以"我"为视角。
enum ElementRelation {
  same('同我'),
  iGenerate('我生'),
  generatesMe('生我'),
  iControl('我克'),
  controlsMe('克我');

  const ElementRelation(this.label);
  final String label;
}

/// 五行颜色,UI 层使用。
const Map<Element, int> elementColors = {
  Element.wood: 0xFF3E8E5A,
  Element.fire: 0xFFD9534F,
  Element.earth: 0xFFB8860B,
  Element.metal: 0xFFC0A062,
  Element.water: 0xFF2F6FB3,
};

/// 五行对应方位、季节、脏腑等,AI 解读与展示用。
const Map<Element, Map<String, String>> elementAttributes = {
  Element.wood: {'方位': '东', '季节': '春', '脏腑': '肝胆', '性情': '仁', '色': '青绿'},
  Element.fire: {'方位': '南', '季节': '夏', '脏腑': '心小肠', '性情': '礼', '色': '红紫'},
  Element.earth: {'方位': '中', '季节': '四季末', '脏腑': '脾胃', '性情': '信', '色': '黄棕'},
  Element.metal: {'方位': '西', '季节': '秋', '脏腑': '肺大肠', '性情': '义', '色': '白金'},
  Element.water: {'方位': '北', '季节': '冬', '脏腑': '肾膀胱', '性情': '智', '色': '黑蓝'},
};
