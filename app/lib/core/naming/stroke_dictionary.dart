/// 康熙字典笔画字典。
///
/// 五格剖象必须用**康熙笔画**(繁体、且氵算 4 画、艹算 6 画、阝左 8 右 7 等),
/// 与现代简体笔画差异很大。完整字典约 2 万字,放在 `assets/data/kangxi_strokes.json`,
/// 格式:
/// ```json
/// { "王": {"s": 4, "r": "玉", "e": "土"}, "李": {"s": 7, "r": "木", "e": "木"} }
/// ```
/// s = 康熙笔画,r = 部首,e = 字义五行(木火土金水)。
///
/// 下面内置的 [builtinStrokes] 只是**常用姓名字的兜底**,方便离线和测试;
/// 字典文件加载后以文件为准。
library;

import 'dart:convert';

import '../bazi/five_elements.dart';

class CharInfo {
  const CharInfo({required this.strokes, this.radical, this.element});
  final int strokes;
  final String? radical;
  final Element? element;
}

class StrokeDictionary {
  StrokeDictionary._(this._map);

  final Map<String, CharInfo> _map;

  static StrokeDictionary? _instance;

  /// 当前字典(未加载文件时为内置兜底)。
  static StrokeDictionary get instance => _instance ??= StrokeDictionary._({
        for (final e in builtinStrokes.entries)
          e.key: CharInfo(strokes: e.value, element: _builtinElements[e.key]),
      });

  /// 从 JSON 文本加载完整字典并覆盖内置兜底。
  static void loadFromJson(String jsonText) {
    final raw = jsonDecode(jsonText) as Map<String, dynamic>;
    final map = <String, CharInfo>{};
    raw.forEach((ch, v) {
      final m = v as Map<String, dynamic>;
      map[ch] = CharInfo(
        strokes: m['s'] as int,
        radical: m['r'] as String?,
        element: _elementFromLabel(m['e'] as String?),
      );
    });
    // 文件缺的字仍用内置兜底
    for (final e in builtinStrokes.entries) {
      map.putIfAbsent(
        e.key,
        () => CharInfo(strokes: e.value, element: _builtinElements[e.key]),
      );
    }
    _instance = StrokeDictionary._(map);
  }

  CharInfo? lookup(String ch) => _map[ch];

  int? strokesOf(String ch) => _map[ch]?.strokes;

  bool has(String ch) => _map.containsKey(ch);

  int get size => _map.length;
}

Element? _elementFromLabel(String? label) {
  switch (label) {
    case '木':
      return Element.wood;
    case '火':
      return Element.fire;
    case '土':
      return Element.earth;
    case '金':
      return Element.metal;
    case '水':
      return Element.water;
  }
  return null;
}

/// 内置兜底:常用姓氏与取名用字的康熙笔画(简体字形作键)。
///
/// 注意几个高频陷阱:王 4(玉部 5 但"王"本字 4)、李 7、张 11、刘 15、陈 16、
/// 杨 13、黄 12、赵 14、周 8、吴 7、郑 19、罗 20、谢 17、韩 17、邓 19、萧/肖 需分辨。
const Map<String, int> builtinStrokes = {
  // ---- 姓氏 ----
  '王': 4, '李': 7, '张': 11, '刘': 15, '陈': 16, '杨': 13, '黄': 12, '赵': 14,
  '吴': 7, '周': 8, '徐': 10, '孙': 10, '马': 10, '朱': 6, '胡': 11, '郭': 15,
  '何': 7, '林': 8, '高': 10, '罗': 20, '郑': 19, '梁': 11, '谢': 17, '宋': 7,
  '唐': 10, '许': 11, '韩': 17, '冯': 12, '邓': 19, '曹': 11, '彭': 12, '曾': 12,
  '萧': 19, '肖': 9, '田': 5, '董': 15, '袁': 10, '潘': 16, '于': 3, '蒋': 17,
  '蔡': 17, '余': 7, '杜': 7, '叶': 15, '程': 12, '苏': 22, '魏': 18, '吕': 7,
  '丁': 2, '任': 6, '沈': 8, '姚': 9, '卢': 16, '姜': 9, '崔': 11, '钟': 17,
  '谭': 19, '陆': 16, '汪': 8, '范': 15, '金': 8, '石': 5, '廖': 14, '贾': 13,
  '夏': 10, '韦': 9, '付': 5, '方': 4, '白': 5, '邹': 17, '孟': 8, '熊': 14,
  '秦': 10, '邱': 12, '江': 7, '尹': 4, '薛': 19, '闵': 12, '段': 9, '雷': 13,
  '侯': 9, '龙': 16, '史': 5, '陶': 16, '黎': 15, '贺': 12, '顾': 21, '毛': 4,
  '郝': 14, '龚': 22, '邵': 12, '万': 15, '钱': 16, '严': 20, '覃': 12, '武': 8,
  '戴': 18, '莫': 13, '孔': 4, '向': 6, '汤': 13, '欧': 15, '施': 9,
  // ---- 常用名字 ----
  '伟': 11, '芳': 10, '娜': 10, '敏': 11, '静': 16, '丽': 19, '强': 11, '磊': 15,
  '军': 9, '洋': 10, '勇': 9, '艳': 24, '杰': 12, '涛': 18, '明': 8, '超': 12,
  '秀': 7, '霞': 17, '平': 5, '刚': 10, '桂': 10, '英': 11, '华': 14, '玲': 10,
  '燕': 16, '红': 9, '文': 4, '辉': 15, '力': 2, '成': 7, '云': 12, '海': 11,
  '峰': 10, '婷': 12, '雪': 11, '琳': 13, '宇': 6, '浩': 11, '鑫': 24, '欣': 8,
  '子': 3, '轩': 10, '涵': 12, '晨': 11, '思': 9, '雨': 8, '泽': 17, '睛': 13,
  '梓': 11, '若': 11, '一': 1, '诺': 16, '语': 14, '晴': 12, '心': 4, '怡': 9,
  '嘉': 14, '瑞': 14, '博': 12, '航': 10, '天': 4, '安': 6, '乐': 15, '佳': 8,
  '慧': 15, '颖': 16, '婉': 11, '琪': 13, '雅': 12, '妍': 7, '萱': 15, '菲': 14,
  '蕾': 19, '莹': 15, '倩': 10, '茜': 12, '瑶': 15, '玥': 9, '妮': 8, '悦': 11,
  '康': 11, '健': 11, '德': 15, '志': 7, '国': 11, '建': 9, '家': 10, '永': 5,
  '福': 14, '禄': 13, '祥': 11, '瑜': 14, '琦': 13, '锐': 15, '锋': 15, '铭': 14,
  '钧': 12, '鹏': 19, '飞': 9, '腾': 20, '龄': 20, '凌': 10, '梦': 14, '宸': 10,
  '沐': 8, '沁': 8, '汐': 7, '淼': 12, '润': 16, '清': 12, '波': 9, '源': 14,
  '木': 4, '森': 12, '柏': 9, '松': 8, '桐': 10, '杉': 7, '楷': 13,
  '炎': 8, '炫': 9, '烁': 19, '煜': 13, '焓': 11, '灿': 17, '烯': 11, '炅': 8,
  '坤': 8, '培': 11, '垚': 9, '城': 10, '基': 11, '壤': 20, '均': 7, '圣': 13,
  '银': 14, '钰': 13, '铠': 18, '锡': 16, '镇': 18, '锦': 16, '钊': 10,
  '玉': 5, '珍': 10, '珊': 10, '珂': 10, '珮': 11, '琬': 13, '瑾': 16, '璐': 18,
  '月': 4, '日': 4, '星': 9, '辰': 7, '光': 6, '亮': 9, '昊': 8, '昕': 8,
  '旭': 6, '晖': 13, '晗': 11, '曦': 20, '阳': 17, '晓': 16, '春': 9, '秋': 9,
  '冬': 5, '梅': 11, '兰': 23, '竹': 6, '菊': 14, '莲': 17, '荷': 13,
  '芝': 10, '芊': 9, '芸': 10, '茗': 12, '苗': 11, '蓉': 16, '薇': 19, '蔓': 17,
  '智': 12, '慷': 15, '信': 9, '义': 13, '仁': 4, '礼': 18, '孝': 7,
  '善': 12, '和': 8, '顺': 12, '达': 16, '通': 14, '进': 15, '新': 13, '正': 5,
  '大': 3, '小': 3, '中': 4, '上': 3, '下': 3, '东': 8, '西': 6, '南': 9, '北': 5,
  '斯': 12, '尔': 14, '维': 14, '伊': 6, '依': 8, '亦': 6, '也': 3, '之': 4,
  '可': 5, '以': 5, '如': 6, '然': 12, '恒': 10, '远': 17, '长': 8,
  '峻': 10, '岩': 8, '岚': 12, '峥': 11, '崟': 11, '山': 3, '川': 3, '河': 9,
  '湖': 13, '洲': 10, '沧': 14, '潼': 16, '澄': 16, '澜': 21, '瀚': 20, '渝': 13,
  '虎': 8, '豹': 10, '凤': 14, '鸾': 30, '鹤': 21, '鹰': 24, '燊': 16, '骏': 17,
  '骅': 22, '驹': 15, '麒': 19, '麟': 23, '琛': 13, '珑': 21, '玮': 14, '瑄': 14,
};

const Map<String, Element> _builtinElements = {
  '木': Element.wood, '林': Element.wood, '森': Element.wood, '柏': Element.wood,
  '松': Element.wood, '桐': Element.wood, '杉': Element.wood, '楷': Element.wood,
  '梓': Element.wood, '梅': Element.wood, '竹': Element.wood, '菊': Element.wood,
  '莲': Element.wood, '荷': Element.wood, '芝': Element.wood, '芊': Element.wood,
  '芸': Element.wood, '茗': Element.wood, '苗': Element.wood, '蓉': Element.wood,
  '薇': Element.wood, '蔓': Element.wood, '兰': Element.wood, '萱': Element.wood,
  '菲': Element.wood, '蕾': Element.wood, '茜': Element.wood, '英': Element.wood,
  '芳': Element.wood, '杨': Element.wood, '李': Element.wood, '朱': Element.wood,
  '杜': Element.wood, '桂': Element.wood, '春': Element.wood, '东': Element.wood,
  '炎': Element.fire, '炫': Element.fire, '烁': Element.fire, '煜': Element.fire,
  '焓': Element.fire, '灿': Element.fire, '烯': Element.fire, '炅': Element.fire,
  '日': Element.fire, '星': Element.fire, '光': Element.fire, '亮': Element.fire,
  '昊': Element.fire, '昕': Element.fire, '旭': Element.fire, '晖': Element.fire,
  '晗': Element.fire, '曦': Element.fire, '阳': Element.fire, '晓': Element.fire,
  '晴': Element.fire, '明': Element.fire, '辉': Element.fire, '烨': Element.fire,
  '夏': Element.fire, '南': Element.fire, '丁': Element.fire, '晨': Element.fire,
  '坤': Element.earth, '培': Element.earth, '垚': Element.earth, '城': Element.earth,
  '基': Element.earth, '壤': Element.earth, '均': Element.earth, '圣': Element.earth,
  '山': Element.earth, '岩': Element.earth, '岚': Element.earth, '峥': Element.earth,
  '峻': Element.earth, '峰': Element.earth, '田': Element.earth, '安': Element.earth,
  '宇': Element.earth, '轩': Element.earth, '宸': Element.earth, '嘉': Element.earth,
  '佳': Element.earth, '怡': Element.earth, '磊': Element.earth, '中': Element.earth,
  '金': Element.metal, '银': Element.metal, '钰': Element.metal, '铠': Element.metal,
  '锡': Element.metal, '镇': Element.metal, '锦': Element.metal, '钊': Element.metal,
  '锐': Element.metal, '锋': Element.metal, '铭': Element.metal, '钧': Element.metal,
  '鑫': Element.metal, '钟': Element.metal, '钱': Element.metal, '玉': Element.metal,
  '珍': Element.metal, '珊': Element.metal, '珂': Element.metal, '珮': Element.metal,
  '琬': Element.metal, '瑾': Element.metal, '璐': Element.metal, '琳': Element.metal,
  '琪': Element.metal, '瑞': Element.metal, '瑜': Element.metal, '琦': Element.metal,
  '瑶': Element.metal, '玥': Element.metal, '玲': Element.metal, '琛': Element.metal,
  '珑': Element.metal, '玮': Element.metal, '瑄': Element.metal, '秋': Element.metal,
  '西': Element.metal, '石': Element.metal, '刚': Element.metal, '新': Element.metal,
  '沐': Element.water, '沁': Element.water, '汐': Element.water, '淼': Element.water,
  '润': Element.water, '清': Element.water, '波': Element.water, '源': Element.water,
  '海': Element.water, '涵': Element.water, '雨': Element.water, '泽': Element.water,
  '洋': Element.water, '涛': Element.water, '雪': Element.water, '霞': Element.water,
  '云': Element.water, '河': Element.water, '湖': Element.water, '洲': Element.water,
  '沧': Element.water, '潼': Element.water, '澄': Element.water, '澜': Element.water,
  '瀚': Element.water, '渝': Element.water, '冬': Element.water, '北': Element.water,
  '汪': Element.water, '江': Element.water, '沈': Element.water, '潘': Element.water,
  '文': Element.water, '子': Element.water, '慧': Element.water, '敏': Element.water,
};
