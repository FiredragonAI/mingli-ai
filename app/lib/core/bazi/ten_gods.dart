/// 十神:以日干为"我",其余天干与我的五行生克 + 阴阳同异,共十种关系。
library;

import '../calendar/sexagenary.dart';
import 'five_elements.dart';

/// 十神。
enum TenGod {
  friend('比肩', '比劫', '同我同性'),
  robWealth('劫财', '比劫', '同我异性'),
  eatingGod('食神', '食伤', '我生同性'),
  hurtingOfficer('伤官', '食伤', '我生异性'),
  indirectWealth('偏财', '财星', '我克同性'),
  directWealth('正财', '财星', '我克异性'),
  sevenKillings('七杀', '官杀', '克我同性'),
  directOfficer('正官', '官杀', '克我异性'),
  indirectResource('偏印', '印星', '生我同性'),
  directResource('正印', '印星', '生我异性');

  const TenGod(this.label, this.group, this.rule);

  /// 名称,如"正官"。
  final String label;

  /// 归类:比劫 / 食伤 / 财星 / 官杀 / 印星。
  final String group;

  /// 定义口诀。
  final String rule;
}

/// 求 [otherStem] 相对于日干 [dayStem] 的十神。
TenGod tenGodOf(int dayStem, int otherStem) {
  final me = stemElements[dayStem];
  final other = stemElements[otherStem];
  final samePolarity = isStemYang(dayStem) == isStemYang(otherStem);

  switch (me.relationTo(other)) {
    case ElementRelation.same:
      return samePolarity ? TenGod.friend : TenGod.robWealth;
    case ElementRelation.iGenerate:
      return samePolarity ? TenGod.eatingGod : TenGod.hurtingOfficer;
    case ElementRelation.iControl:
      return samePolarity ? TenGod.indirectWealth : TenGod.directWealth;
    case ElementRelation.controlsMe:
      return samePolarity ? TenGod.sevenKillings : TenGod.directOfficer;
    case ElementRelation.generatesMe:
      return samePolarity ? TenGod.indirectResource : TenGod.directResource;
  }
}

/// 十神通俗释义,供 AI 提示词与 UI 使用。
const Map<TenGod, String> tenGodMeanings = {
  TenGod.friend: '自我、同伴、竞争者;独立心与主见',
  TenGod.robWealth: '兄弟朋友、合伙、破财;行动力与冲动',
  TenGod.eatingGod: '才艺、口福、表达、子女(女命);温和的创造力',
  TenGod.hurtingOfficer: '才华、叛逆、锋芒;不受约束的创造力',
  TenGod.indirectWealth: '横财、投机、父亲、异性缘;豪爽善交际',
  TenGod.directWealth: '正当收入、妻子(男命)、务实;稳健守成',
  TenGod.sevenKillings: '压力、竞争、魄力、丈夫(女命,无正官时);威严果决',
  TenGod.directOfficer: '名誉、职位、纪律、丈夫(女命);正直自律',
  TenGod.indirectResource: '偏门学问、直觉、继母;孤独思辨',
  TenGod.directResource: '母亲、学历、贵人、庇护;仁慈好学',
};
