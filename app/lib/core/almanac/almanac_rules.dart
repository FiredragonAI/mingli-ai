/// 黄历常量表与宜忌规则。
library;

import '../astro/julian.dart';
import '../calendar/lunar_calendar.dart';
import '../calendar/sexagenary.dart';

/// 建除十二神。
const List<String> jianChuNames = [
  '建', '除', '满', '平', '定', '执', '破', '危', '成', '收', '开', '闭',
];

/// 十二值神,黄道黑道相间。
const List<String> zhiShenNames = [
  '青龙', '明堂', '天刑', '朱雀', '金匮', '天德', '白虎', '玉堂', '天牢', '玄武', '司命', '勾陈',
];

/// 与 [zhiShenNames] 对应:true 黄道,false 黑道。
const List<bool> huangDaoFlags = [
  true, true, false, false, true, true, false, true, false, false, true, false,
];

/// 青龙起例:寅申起子、卯酉起寅、辰戌起辰、巳亥起午、子午起申、丑未起戌。
///
/// 既用于"以月支定日"的值神,也用于"以日支定时"的时辰吉凶。
int zhiShenIndex(int baseBranch, int targetBranch) {
  final start = (((baseBranch - 2) % 6 + 6) % 6) * 2;
  return ((targetBranch - start) % 12 + 12) % 12;
}

/// 二十八宿,按周期顺序。
const List<String> xiuNames = [
  '角木蛟', '亢金龙', '氐土貉', '房日兔', '心月狐', '尾火虎', '箕水豹',
  '斗木獬', '牛金牛', '女土蝠', '虚日鼠', '危月燕', '室火猪', '壁水貐',
  '奎木狼', '娄金狗', '胃土雉', '昴日鸡', '毕月乌', '觜火猴', '参水猿',
  '井木犴', '鬼金羊', '柳土獐', '星日马', '张月鹿', '翼火蛇', '轸水蚓',
];

/// 二十八宿锚点。
///
/// 通书里二十八宿按 28 日一轮连续排布,且与七曜锁定:虚、房、星、昴四宿恒在星期日。
/// 这里假定 2000-01-02(周日)为"虚日鼠"。**四个周日宿哪一个落在该日尚未核实**,
/// 上线前必须对照《通胜》或紫金山天文台历书确认;若不符,把 `- 10` 改为
/// `- 3`(房)、`- 24`(星)或 `- 17`(昴)即可,其余代码不动。
final int xiuAnchorDayNumber =
    julianDayNumberLocal(julianDayFromDate(2000, 1, 2.5)) - 10; // 使该日索引为 10(虚)

/// 煞方:申子辰日煞南,亥卯未日煞西,寅午戌日煞北,巳酉丑日煞东。
String shaDirectionOf(int dayBranch) {
  const map = ['南', '东', '北', '西', '南', '东', '北', '西', '南', '东', '北', '西'];
  return map[dayBranch];
}

/// 喜神方位(以日干):甲己东北、乙庚西北、丙辛西南、丁壬正南、戊癸东南。
String joyDirectionOf(int dayStem) {
  const map = ['东北', '西北', '西南', '正南', '东南'];
  return map[dayStem % 5];
}

/// 财神方位(以日干):甲乙东北、丙丁西南、戊己正北、庚辛正东、壬癸正南。
String wealthDirectionOf(int dayStem) {
  const map = ['东北', '西南', '正北', '正东', '正南'];
  return map[dayStem ~/ 2];
}

/// 彭祖百忌——天干句。
const List<String> pengZuStem = [
  '甲不开仓,财物耗散',
  '乙不栽植,千株不长',
  '丙不修灶,必见灾殃',
  '丁不剃头,头必生疮',
  '戊不受田,田主不祥',
  '己不破券,二比并亡',
  '庚不经络,织机虚张',
  '辛不合酱,主人不尝',
  '壬不汲水,更难提防',
  '癸不词讼,理弱敌强',
];

/// 彭祖百忌——地支句。
const List<String> pengZuBranch = [
  '子不问卜,自惹祸殃',
  '丑不冠带,主不还乡',
  '寅不祭祀,神鬼不尝',
  '卯不穿井,水泉不香',
  '辰不哭泣,必主重丧',
  '巳不远行,财物伏藏',
  '午不苫盖,屋主更张',
  '未不服药,毒气入肠',
  '申不安床,鬼祟入房',
  '酉不会客,醉坐颠狂',
  '戌不吃犬,作怪上床',
  '亥不嫁娶,不利新郎',
];

/// 建除十二神的基础宜忌。
const Map<String, (List<String>, List<String>)> jianChuAdvice = {
  '建': (['出行', '上任', '会友', '求职', '拜访', '订盟'], ['动土', '开仓', '掘井', '乘船', '修坟']),
  '除': (['祭祀', '沐浴', '扫舍', '求医', '拆卸', '除服', '出行'], ['嫁娶', '赴任', '求官', '出财']),
  '满': (['祈福', '祭祀', '订婚', '开市', '交易', '移徙', '出行', '纳财'], ['栽种', '服药', '求医', '安葬']),
  '平': (['修饰垣墙', '平治道涂', '会友', '祭祀'], ['移徙', '入宅', '嫁娶', '开市', '动土']),
  '定': (['嫁娶', '祭祀', '祈福', '交易', '入宅', '修造', '入学', '求医', '纳畜'], ['诉讼', '出行', '移徙', '栽种']),
  '执': (['造屋', '嫁娶', '祭祀', '祈福', '捕捉', '纳畜', '立券'], ['移徙', '出行', '开市', '入宅', '出财']),
  '破': (['破屋', '坏垣', '求医治病'], ['嫁娶', '开市', '入宅', '出行', '交易', '签约', '动土']),
  '危': (['祭祀', '祈福', '安床', '纳畜', '安机械'], ['登高', '乘船', '出行', '涉险', '动土']),
  '成': (['嫁娶', '开市', '修造', '入宅', '入学', '出行', '交易', '祭祀', '求嗣', '上梁', '订盟'], ['诉讼', '安葬']),
  '收': (['纳财', '收账', '索债', '纳畜', '栽种', '入学', '祭祀'], ['开市', '出行', '安葬', '放债', '开仓']),
  '开': (['开市', '交易', '出行', '嫁娶', '入宅', '修造', '祭祀', '上任', '入学', '动土', '开光'], ['安葬', '破土', '埋葬']),
  '闭': (['安葬', '筑堤', '补垣', '塞穴', '修坟', '断蚁'], ['开市', '出行', '嫁娶', '求医', '入宅', '动土']),
};

/// 受死日:正月戌、二月辰、三月亥、四月巳、五月子、六月午、七月丑、八月未、九月寅、十月申、十一月卯、十二月酉。
/// 以节气月序(0 = 寅月)索引。
const List<int> shouSiBranchByMonth = [10, 4, 11, 5, 0, 6, 1, 7, 2, 8, 3, 9];

/// 杨公忌日(农历 月 → 日 列表)。
const Map<int, List<int>> yangGongDays = {
  1: [13], 2: [11], 3: [9], 4: [7], 5: [5], 6: [3],
  7: [1, 29], 8: [27], 9: [25], 10: [23], 11: [21], 12: [19],
};

/// 三娘煞:农历初三、初七、十三、十八、廿二、廿七。
const Set<int> sanNiangDays = {3, 7, 13, 18, 22, 27};

/// 天德(以节气月序 0 = 寅):丁 申 壬 辛 亥 甲 癸 寅 丙 乙 巳 庚——干支混排,用字符串。
const List<String> tianDeByMonth = ['丁', '申', '壬', '辛', '亥', '甲', '癸', '寅', '丙', '乙', '巳', '庚'];

/// 月德(以节气月序):寅午戌丙、申子辰壬、亥卯未甲、巳酉丑庚。
const List<int> yueDeByMonth = [2, 0, 8, 6, 2, 0, 8, 6, 2, 0, 8, 6];

/// 规则评估结果。
class RuleOutcome {
  RuleOutcome({
    required this.suitable,
    required this.unsuitable,
    required this.auspiciousGods,
    required this.inauspiciousGods,
    required this.notes,
  });

  final List<String> suitable;
  final List<String> unsuitable;
  final List<String> auspiciousGods;
  final List<String> inauspiciousGods;
  final List<String> notes;
}

/// 宜忌规则引擎。
RuleOutcome evaluateRules({
  required int jianChuIdx,
  required bool isHuangDao,
  required String zhiShen,
  required StemBranch daySb,
  required StemBranch monthSb,
  required StemBranch yearSb,
  required LunarDate lunar,
  required bool isTermEve,
  required String? termName,
}) {
  final jianChu = jianChuNames[jianChuIdx];
  final base = jianChuAdvice[jianChu]!;
  final suitable = <String>{...base.$1};
  final unsuitable = <String>{...base.$2};
  final good = <String>[];
  final bad = <String>[];
  final notes = <String>['建除值"$jianChu"'];

  good.add(zhiShen);
  notes.add(isHuangDao ? '$zhiShen黄道日,诸事咸宜' : '$zhiShen黑道日,大事宜慎');

  final monthIdx = ((monthSb.branch - 2) % 12 + 12) % 12;

  // 天德、月德
  final tianDe = tianDeByMonth[monthIdx];
  if (daySb.stemName == tianDe || daySb.branchName == tianDe) {
    good.add('天德');
    suitable.addAll(['祈福', '嫁娶', '修造', '出行']);
    notes.add('日逢天德,凶煞可解');
  }
  if (daySb.stem == yueDeByMonth[monthIdx]) {
    good.add('月德');
    suitable.addAll(['祈福', '嫁娶', '修造', '安床']);
    notes.add('日逢月德,宜行善举');
  }

  // 月破:日支冲月支
  if ((daySb.branch - monthSb.branch).abs() == 6) {
    bad.add('月破');
    unsuitable.addAll(['嫁娶', '开市', '入宅', '动土', '签约', '出行']);
    suitable
      ..clear()
      ..addAll(['破屋', '坏垣', '求医']);
    notes.add('日支冲月建为月破,大事勿用');
  }

  // 岁破:日支冲年支
  if ((daySb.branch - yearSb.branch).abs() == 6) {
    bad.add('岁破');
    unsuitable.addAll(['出行', '移徙', '动土', '嫁娶']);
    notes.add('日支冲太岁为岁破');
  }

  // 受死
  if (daySb.branch == shouSiBranchByMonth[monthIdx]) {
    bad.add('受死');
    unsuitable.addAll(['嫁娶', '出行', '入宅', '开市']);
    suitable.removeWhere((s) => !{'祭祀', '捕捉', '畋猎'}.contains(s));
    suitable.addAll(['捕捉', '畋猎']);
    notes.add('日值受死,惟宜捕猎');
  }

  // 杨公忌
  if (!lunar.isLeapMonth && (yangGongDays[lunar.month]?.contains(lunar.day) ?? false)) {
    bad.add('杨公忌');
    unsuitable.addAll(['嫁娶', '开市', '入宅', '出行', '动土', '签约']);
    notes.add('杨公十三忌日,百事不宜');
  }

  // 三娘煞
  if (sanNiangDays.contains(lunar.day)) {
    bad.add('三娘煞');
    unsuitable.add('嫁娶');
    suitable.remove('嫁娶');
    notes.add('三娘煞日,忌嫁娶');
  }

  // 四离四绝
  if (isTermEve) {
    bad.add('四离/四绝');
    unsuitable.addAll(['嫁娶', '出行', '开市', '动土']);
    notes.add('节气前一日为离绝之日,忌大事');
  }

  // 交节当日
  if (termName != null) {
    notes.add('今日交$termName');
  }

  // 黑道日削弱宜项
  if (!isHuangDao && bad.isEmpty) {
    suitable.removeAll(['嫁娶', '开市', '入宅']);
  }

  // 保证宜忌不重复:忌优先
  suitable.removeAll(unsuitable);

  return RuleOutcome(
    suitable: suitable.toList(),
    unsuitable: unsuitable.toList(),
    auspiciousGods: good,
    inauspiciousGods: bad,
    notes: notes,
  );
}
