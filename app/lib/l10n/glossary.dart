/// 命理术语英译表 + 英文格式化辅助。
///
/// 引擎内部全部用中文字符串(与文献口径一致,便于核对),英文界面用这里查表。
/// 原则:术语首次给"英文(拼音)",例如 Day Master (rì zhǔ);干支用拼音连字,如 Jia-Zi。
library;

import '../core/bazi/bazi_chart.dart';
import '../core/calendar/lunar_calendar.dart';
import '../core/calendar/sexagenary.dart';

const List<String> stemPinyin = ['Jia', 'Yi', 'Bing', 'Ding', 'Wu', 'Ji', 'Geng', 'Xin', 'Ren', 'Gui'];
const List<String> branchPinyin = ['Zi', 'Chou', 'Yin', 'Mao', 'Chen', 'Si', 'Wu', 'Wei', 'Shen', 'You', 'Xu', 'Hai'];
const List<String> stemEnglish = [
  'Yang Wood', 'Yin Wood', 'Yang Fire', 'Yin Fire', 'Yang Earth',
  'Yin Earth', 'Yang Metal', 'Yin Metal', 'Yang Water', 'Yin Water',
];
const List<String> animalEnglish = [
  'Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake', 'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig',
];
const List<String> pillarEnglish = ['Year', 'Month', 'Day', 'Hour'];
const List<String> lifeStageEnglish = [
  'Birth', 'Bath', 'Youth', 'Prime', 'Peak', 'Decline', 'Illness', 'Death', 'Grave', 'Extinction', 'Conception', 'Nurture',
];
const List<String> shichenEnglish = [
  'Zi (23–01)', 'Chou (01–03)', 'Yin (03–05)', 'Mao (05–07)', 'Chen (07–09)', 'Si (09–11)',
  'Wu (11–13)', 'Wei (13–15)', 'Shen (15–17)', 'You (17–19)', 'Xu (19–21)', 'Hai (21–23)',
];

/// 中文术语 → 英文。找不到返回 null(调用方决定回退)。
const Map<String, String> termEnglish = {
  // 五行
  '木': 'Wood', '火': 'Fire', '土': 'Earth', '金': 'Metal', '水': 'Water',
  // 十神
  '比肩': 'Friend', '劫财': 'Rob Wealth', '食神': 'Eating God', '伤官': 'Hurting Officer',
  '偏财': 'Indirect Wealth', '正财': 'Direct Wealth', '七杀': 'Seven Killings', '正官': 'Direct Officer',
  '偏印': 'Indirect Resource', '正印': 'Direct Resource', '日主': 'Day Master',
  '比劫': 'Companions', '食伤': 'Output', '财星': 'Wealth', '官杀': 'Authority', '印星': 'Resource',
  // 强弱
  '极强': 'Very Strong', '偏强': 'Strong', '中和': 'Balanced', '偏弱': 'Weak', '极弱': 'Very Weak',
  // 性别 / 命造
  '男': 'Male', '女': 'Female', '乾造': 'Male chart', '坤造': 'Female chart',
  // 柱
  '年': 'Year', '月': 'Month', '日': 'Day', '时': 'Hour',
  '年柱': 'Year Pillar', '月柱': 'Month Pillar', '日柱': 'Day Pillar', '时柱': 'Hour Pillar',
  // 吉凶
  '吉': 'Auspicious', '半吉': 'Mixed', '凶': 'Inauspicious', '黄道': 'Auspicious', '黑道': 'Inauspicious',
  // 五格
  '天格': 'Heaven', '人格': 'Person', '地格': 'Earth', '外格': 'Outer', '总格': 'Total',
  // 建除十二神
  '建': 'Establish', '除': 'Remove', '满': 'Full', '平': 'Balance', '定': 'Settle', '执': 'Hold',
  '破': 'Break', '危': 'Danger', '成': 'Success', '收': 'Receive', '开': 'Open', '闭': 'Close',
  // 十二值神
  '青龙': 'Azure Dragon', '明堂': 'Bright Hall', '金匮': 'Golden Chest', '天德': 'Heavenly Virtue',
  '玉堂': 'Jade Hall', '司命': 'Life Governor', '天刑': 'Heavenly Punishment', '朱雀': 'Vermilion Bird',
  '白虎': 'White Tiger', '天牢': 'Heavenly Prison', '玄武': 'Black Tortoise', '勾陈': 'Hooked Array',
  // 神煞
  '天乙贵人': 'Nobleman', '月德贵人': 'Monthly Virtue', '文昌': 'Academic Star', '驿马': 'Travelling Horse',
  '桃花': 'Peach Blossom', '红鸾': 'Red Phoenix', '天喜': 'Heavenly Joy', '华盖': 'Canopy', '羊刃': 'Goat Blade',
  '劫煞': 'Robbery Sha', '亡神': 'Void Spirit', '孤辰': 'Lonely Star', '寡宿': 'Widow Star', '将星': 'General Star',
  '阴差阳错': 'Yin-Yang Error', '魁罡': 'Kui Gang', '金舆': 'Golden Carriage', '禄神': 'Salary Star',
  '学堂': 'Study Hall', '孤鸾': 'Lonely Phoenix', '十恶大败': 'Ten Evils', '童子': 'Child Star', '空亡': 'Void',
  // 星座元素 / 三态
  '火象': 'Fire sign', '土象': 'Earth sign', '风象': 'Air sign', '水象': 'Water sign',
  '基本': 'Cardinal', '固定': 'Fixed', '变动': 'Mutable',
  // 手型 / 脸型
  '土型': 'Earth hand', '火型': 'Fire hand', '风型': 'Air hand', '水型': 'Water hand',
  '田字面': 'Square face', '由字面': 'Pear face', '甲字面': 'Inverted-triangle face', '申字面': 'Diamond face',
  '目字面': 'Oblong face', '圆字面': 'Round face', '同字面': 'Rectangular face',
  '左手': 'Left hand', '右手': 'Right hand',
  '生命线': 'Life line', '智慧线': 'Head line', '感情线': 'Heart line',
  // 流年 / 太岁
  '值太岁': 'Same-animal year', '冲太岁': 'Clash with Tai Sui', '刑太岁': 'Punish Tai Sui',
  '害太岁': 'Harm Tai Sui', '破太岁': 'Break Tai Sui', '合太岁': 'Harmony with Tai Sui',
  '顺遂年': 'Smooth year', '稳中有进': 'Steady progress', '平年': 'Ordinary year', '守成年': 'Holding year', '蓄力年': 'Gathering year',
  // 合婚
  '天作之合': 'Made for each other', '良缘可期': 'Promising match', '中平可为': 'Workable match',
  '需多磨合': 'Needs work', '慎重考虑': 'Think carefully',
  '生肖缘': 'Zodiac affinity', '日柱缘': 'Day-pillar affinity', '五行互补': 'Element balance',
  '配偶星': 'Spouse star', '神煞': 'Stars', '纳音': 'Na Yin',
  // 星座
  '默契天成': 'Natural chemistry', '相处融洽': 'Harmonious', '互补可为': 'Complementary', '需要磨合': 'Needs adjusting',
  // 其他
  '顺行': 'forward', '逆行': 'backward', '真太阳时': 'true solar time',
  '事业': 'Career', '财运': 'Wealth', '感情': 'Love', '健康': 'Health', '综合': 'Overall',
  '大吉': 'Excellent', '小心': 'Caution', '守': 'Hold',
  // 颜色 / 方位
  '青绿': 'Green', '红紫': 'Red / Purple', '黄棕': 'Yellow / Brown', '白金': 'White / Gold', '黑蓝': 'Black / Blue',
  '东': 'East', '南': 'South', '西': 'West', '北': 'North', '中': 'Center',
  '东南': 'Southeast', '东北': 'Northeast', '西南': 'Southwest', '西北': 'Northwest',
  '正东': 'East', '正南': 'South', '正西': 'West', '正北': 'North',
  // 守护星
  '火星': 'Mars', '金星': 'Venus', '水星': 'Mercury', '月亮': 'Moon', '太阳': 'Sun', '木星': 'Jupiter', '土星': 'Saturn',
  '冥王星 / 火星': 'Pluto / Mars', '天王星 / 土星': 'Uranus / Saturn', '海王星 / 木星': 'Neptune / Jupiter',
  // 手指比例
  '食指/中指': 'Index / Middle', '无名指/中指': 'Ring / Middle', '小指/中指': 'Little / Middle',
  '拇指/掌宽': 'Thumb / Palm width', '食指/无名指': 'Index / Ring',
  // 二十四节气
  '立春': 'Start of Spring', '雨水': 'Rain Water', '惊蛰': 'Awakening of Insects', '春分': 'Spring Equinox',
  '清明': 'Pure Brightness', '谷雨': 'Grain Rain', '立夏': 'Start of Summer', '小满': 'Grain Buds',
  '芒种': 'Grain in Ear', '夏至': 'Summer Solstice', '小暑': 'Minor Heat', '大暑': 'Major Heat',
  '立秋': 'Start of Autumn', '处暑': 'End of Heat', '白露': 'White Dew', '秋分': 'Autumn Equinox',
  '寒露': 'Cold Dew', '霜降': "Frost's Descent", '立冬': 'Start of Winter', '小雪': 'Minor Snow',
  '大雪': 'Major Snow', '冬至': 'Winter Solstice', '小寒': 'Minor Cold', '大寒': 'Major Cold',
};

/// 星座英文内容(与 western_zodiac.dart 的中文一一对应)。
class ZodiacEn {
  const ZodiacEn(this.keywords, this.strengths, this.weaknesses, this.rising, this.color);
  final List<String> keywords;
  final List<String> strengths;
  final List<String> weaknesses;
  final String rising;
  final String color;
}

const List<ZodiacEn> zodiacEn = [
  ZodiacEn(['brave', 'direct', 'action-first'], ['decisive', 'passionate', 'pioneering'], ['impatient', 'impulsive', 'short fuse'],
      'Comes across as bold and straightforward — acts first, thinks later, with an unmistakable competitive streak', 'Red'),
  ZodiacEn(['steady', 'practical', 'sensual'], ['reliable', 'patient', 'good taste'], ['stubborn', 'possessive', 'slow to warm'],
      'Comes across as calm and dependable — unhurried but solid, with a natural feel for comfort and quality', 'Green'),
  ZodiacEn(['quick', 'curious', 'communicative'], ['adaptable', 'articulate', 'fast learner'], ['scattered', 'restless', 'hard to pin down'],
      'Comes across as light and talkative — quick reactions, endless topics, clever and a little elusive', 'Yellow'),
  ZodiacEn(['caring', 'home-loving', 'sensitive'], ['considerate', 'loyal', 'intuitive'], ['moody', 'defensive', 'nostalgic'],
      'Comes across as gentle and reserved — watches before approaching, then looks after people fiercely', 'Silver'),
  ZodiacEn(['confident', 'generous', 'a leader'], ['big-hearted', 'loyal', 'magnetic'], ['self-centred', 'proud', 'stubborn'],
      'Comes across as warm and commanding — naturally the centre of attention, happy to take charge and give', 'Gold / Orange'),
  ZodiacEn(['meticulous', 'rational', 'perfectionist'], ['reliable', 'analytical', 'diligent'], ['critical', 'anxious', 'over-self-examining'],
      'Comes across as neat and composed — speaks in order, keeps emotions private, care shows in the details', 'Grey-blue'),
  ZodiacEn(['graceful', 'fair', 'relationship-minded'], ['approachable', 'aesthetic', 'diplomatic'], ['indecisive', 'dependent', 'conflict-avoidant'],
      'Comes across as poised and courteous — attentive to how others feel, the natural mediator in any room', 'Pink / Blue'),
  ZodiacEn(['deep', 'focused', 'perceptive'], ['strong-willed', 'loyal', 'sees through things'], ['suspicious', 'extreme', 'holds grudges'],
      'Comes across as cool and a little distant — intense gaze, few words, each one carrying weight', 'Deep red'),
  ZodiacEn(['optimistic', 'free', 'exploratory'], ['open-minded', 'funny', 'sincere'], ['scattered', 'commitment-shy', 'bluntly honest'],
      'Comes across as cheerful and easy-going — laughs a lot, ignores small stuff, carries a traveller\'s air of freedom', 'Purple'),
  ZodiacEn(['disciplined', 'resilient', 'goal-driven'], ['responsible', 'enduring', 'practical'], ['conservative', 'emotionally guarded', 'workaholic'],
      'Comes across as serious and steady — seems older than their years, and does what they say', 'Black / Brown'),
  ZodiacEn(['independent', 'inventive', 'idealistic'], ['original', 'humanitarian', 'forward-looking'], ['detached', 'rebellious', 'a loner'],
      'Comes across as unusual and slightly distant — always thinking differently, friendly but not intimate', 'Blue'),
  ZodiacEn(['gentle', 'romantic', 'empathetic'], ['imaginative', 'compassionate', 'artistic'], ['escapist', 'over-sensitive', 'blurry boundaries'],
      'Comes across as soft and dreamy — easily moved, and people instinctively want to protect them', 'Sea green'),
];

String stemEn(int stem) => '${stemPinyin[stem]} (${stemEnglish[stem]})';
String branchEn(int branch) => '${branchPinyin[branch]} (${animalEnglish[branch]})';
String stemBranchEn(StemBranch sb) => '${stemPinyin[sb.stem]}-${branchPinyin[sb.branch]}';

/// "Jia-Zi Bing-Yin Jia-Chen Geng-Wu"
String summaryEn(BaziChart c) => c.pillars.map((p) => stemBranchEn(p.stemBranch)).join(' ');

String lunarEn(LunarDate d) =>
    'Lunar ${stemBranchEn(d.yearStemBranch)} year, ${d.isLeapMonth ? 'leap ' : ''}month ${d.month}, day ${d.day}';

String ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
}
