/// 八十一数理。
library;

enum Luck {
  auspicious('吉'),
  half('半吉'),
  inauspicious('凶');

  const Luck(this.label);
  final String label;
}

class NumberMeaning {
  const NumberMeaning(this.number, this.luck, this.title, this.text);
  final int number;
  final Luck luck;
  final String title;
  final String text;
}

/// 取某数的数理,超过 81 者减 80 循环。
NumberMeaning numberMeaningOf(int n) {
  var k = n;
  while (k > 81) {
    k -= 80;
  }
  if (k < 1) k = 1;
  return numerology81[k - 1];
}

const List<NumberMeaning> numerology81 = [
  NumberMeaning(1, Luck.auspicious, '太极之数', '万物开泰,生发无穷,利禄亨通'),
  NumberMeaning(2, Luck.inauspicious, '两仪之数', '混沌未开,进退保守,志望难达'),
  NumberMeaning(3, Luck.auspicious, '三才之数', '天地人和,大事大业,繁荣昌隆'),
  NumberMeaning(4, Luck.inauspicious, '四象之数', '待于生发,万事慎重,不具营谋'),
  NumberMeaning(5, Luck.auspicious, '五行俱权', '循环相生,圆通畅达,福祉无穷'),
  NumberMeaning(6, Luck.auspicious, '六爻之数', '发展变化,天赋美德,吉祥安泰'),
  NumberMeaning(7, Luck.auspicious, '七政之数', '精悍严谨,天赋之力,吉星照耀'),
  NumberMeaning(8, Luck.auspicious, '八卦之数', '乾坎艮震,巽离坤兑,无穷无尽'),
  NumberMeaning(9, Luck.inauspicious, '大成之数', '蕴涵凶险,或成或败,难以把握'),
  NumberMeaning(10, Luck.inauspicious, '终结之数', '雪暗飘零,偶或有成,回顾茫然'),
  NumberMeaning(11, Luck.auspicious, '旱苗逢雨', '枯木逢春,稳健着实,必得人望'),
  NumberMeaning(12, Luck.inauspicious, '掘井无泉', '意志薄弱,家庭寂寞,劳而无功'),
  NumberMeaning(13, Luck.auspicious, '春日牡丹', '才艺多能,智谋奇略,忍柔当事'),
  NumberMeaning(14, Luck.inauspicious, '沦落天涯', '失意烦闷,家庭缘薄,多有不幸'),
  NumberMeaning(15, Luck.auspicious, '福寿双全', '立身兴家,福寿圆满,富贵荣誉'),
  NumberMeaning(16, Luck.auspicious, '厚重载德', '安富尊荣,财官双美,功成名就'),
  NumberMeaning(17, Luck.auspicious, '突破万难', '刚柔兼备,权威刚强,意志坚定'),
  NumberMeaning(18, Luck.auspicious, '有志竟成', '内外有运,权威显达,博得名利'),
  NumberMeaning(19, Luck.inauspicious, '风云蔽日', '辛苦重来,虽有智谋,万事挫折'),
  NumberMeaning(20, Luck.inauspicious, '非业破运', '灾难重重,进退维谷,万事难成'),
  NumberMeaning(21, Luck.auspicious, '明月光照', '独立权威,光风霁月,万物确立'),
  NumberMeaning(22, Luck.inauspicious, '秋草逢霜', '怀才不遇,忧愁怨苦,事不如意'),
  NumberMeaning(23, Luck.auspicious, '旭日东升', '壮丽壮观,权威旺盛,功名荣达'),
  NumberMeaning(24, Luck.auspicious, '家门余庆', '金钱丰盈,白手成家,财源广进'),
  NumberMeaning(25, Luck.auspicious, '资性英敏', '才能奇特,克服傲慢,尚可成功'),
  NumberMeaning(26, Luck.half, '变怪之谜', '英雄豪杰,波澜重叠,而奏大功'),
  NumberMeaning(27, Luck.half, '增长之数', '欲望无止,自我强烈,多受毁谤'),
  NumberMeaning(28, Luck.inauspicious, '遭难之数', '豪杰气概,四海漂泊,终身劳苦'),
  NumberMeaning(29, Luck.auspicious, '智谋兼备', '财力归集,名闻海内,成就大业'),
  NumberMeaning(30, Luck.half, '非运之数', '沉浮不定,凶吉难变,若明若暗'),
  NumberMeaning(31, Luck.auspicious, '春日花开', '智勇得志,博得名利,统领众人'),
  NumberMeaning(32, Luck.auspicious, '宝马金鞍', '侥幸多望,贵人得助,财帛如裕'),
  NumberMeaning(33, Luck.auspicious, '旭日升天', '鸾凤相会,名闻天下,隆昌至极'),
  NumberMeaning(34, Luck.inauspicious, '破家之身', '见识短小,辛苦遭逢,灾祸至极'),
  NumberMeaning(35, Luck.auspicious, '高楼望月', '温和平静,智达通畅,文昌技艺'),
  NumberMeaning(36, Luck.inauspicious, '波澜重叠', '沉浮万状,侠肝义胆,舍己成仁'),
  NumberMeaning(37, Luck.auspicious, '猛虎出林', '权威显达,热诚忠信,宜着雅量'),
  NumberMeaning(38, Luck.half, '磨铁成针', '意志薄弱,刻意经营,才识不凡'),
  NumberMeaning(39, Luck.auspicious, '富贵荣华', '财帛丰盈,暗藏险象,德泽四方'),
  NumberMeaning(40, Luck.inauspicious, '退安保平', '智谋胆力,冒险投机,沉浮不定'),
  NumberMeaning(41, Luck.auspicious, '纯阳独秀', '德高望重,和顺畅达,博得名利'),
  NumberMeaning(42, Luck.half, '寒蝉在柳', '博识多能,精通世情,专心可成'),
  NumberMeaning(43, Luck.inauspicious, '散财破产', '诸事不遂,虚饰之象,无事生非'),
  NumberMeaning(44, Luck.inauspicious, '须眉难展', '力量有限,破家亡身,暗藏悲惨'),
  NumberMeaning(45, Luck.auspicious, '新生泰和', '顺风扬帆,智谋经纬,富贵繁荣'),
  NumberMeaning(46, Luck.inauspicious, '载宝沉舟', '浪里淘金,大难尝尽,方成大功'),
  NumberMeaning(47, Luck.auspicious, '点石成金', '开花之象,万事如意,祯祥吉庆'),
  NumberMeaning(48, Luck.auspicious, '古松立鹤', '德智兼备,威望成师,洋洋大观'),
  NumberMeaning(49, Luck.inauspicious, '转变之象', '吉临则吉,凶来则凶,转凶为吉'),
  NumberMeaning(50, Luck.inauspicious, '小舟入海', '吉凶参半,须防倾覆,始保安然'),
  NumberMeaning(51, Luck.half, '沉浮盛衰', '盛衰交加,波澜重叠,晚年凋零'),
  NumberMeaning(52, Luck.auspicious, '达眼之数', '先见之明,智谋超群,名利双收'),
  NumberMeaning(53, Luck.inauspicious, '曲卷难伸', '外祥内苦,先富后贫,盛衰交加'),
  NumberMeaning(54, Luck.inauspicious, '石上栽花', '多难悲运,难望成功,忧闷频来'),
  NumberMeaning(55, Luck.half, '善恶之数', '外美内苦,克服难关,开出泰运'),
  NumberMeaning(56, Luck.inauspicious, '浪里行舟', '历尽艰辛,四周障碍,万事龃龉'),
  NumberMeaning(57, Luck.auspicious, '日照春松', '寒雪青松,夜莺吟春,必遭一过'),
  NumberMeaning(58, Luck.half, '晚行遇月', '先苦后甘,宽宏扬名,富贵繁荣'),
  NumberMeaning(59, Luck.inauspicious, '寒蝉悲风', '意志衰退,缺乏勇气,毁灭之象'),
  NumberMeaning(60, Luck.inauspicious, '无谋之数', '漫无目的,不知东西,烦闷苦难'),
  NumberMeaning(61, Luck.auspicious, '牡丹芙蓉', '名利双收,繁荣富贵,定享天赋'),
  NumberMeaning(62, Luck.inauspicious, '衰败之数', '内外不和,信用缺乏,艰难困厄'),
  NumberMeaning(63, Luck.auspicious, '舟归平海', '富贵荣华,身心安泰,雨露惠泽'),
  NumberMeaning(64, Luck.inauspicious, '骨肉分离', '孤独悲愁,难望成功,穷困之数'),
  NumberMeaning(65, Luck.auspicious, '巨流归海', '天长地久,家运隆昌,福寿绵长'),
  NumberMeaning(66, Luck.inauspicious, '岩头步马', '进退维谷,艰难不堪,内外不和'),
  NumberMeaning(67, Luck.auspicious, '顺风通达', '天赋幸运,四通八达,家道繁昌'),
  NumberMeaning(68, Luck.auspicious, '顺风吹帆', '智虑周密,发明能力,名利双收'),
  NumberMeaning(69, Luck.inauspicious, '非业之数', '精神不安,孤独病弱,无望之象'),
  NumberMeaning(70, Luck.inauspicious, '惨淡孤独', '残菊逢霜,寂寞无常,忧愁苦难'),
  NumberMeaning(71, Luck.half, '石上金花', '内忧外患,毫无实质,养神耐劳'),
  NumberMeaning(72, Luck.inauspicious, '劳苦之数', '先甘后苦,先苦后甜,凶多吉少'),
  NumberMeaning(73, Luck.half, '无勇之数', '盛衰交加,徒有高志,平安自守'),
  NumberMeaning(74, Luck.inauspicious, '残菊逢霜', '无智无能,坐食山空,不得成功'),
  NumberMeaning(75, Luck.half, '守分之数', '进不如守,不知自省,妄动招祸'),
  NumberMeaning(76, Luck.inauspicious, '离散之数', '倾覆离散,骨肉分离,内外不和'),
  NumberMeaning(77, Luck.half, '家庭有悦', '吉凶参半,乐极生悲,守成保平'),
  NumberMeaning(78, Luck.half, '晚苦之数', '祸福参半,先天智能,晚年寒冷'),
  NumberMeaning(79, Luck.inauspicious, '云头望月', '身疲力尽,穷迫不伸,精神不定'),
  NumberMeaning(80, Luck.inauspicious, '遁世之数', '辛苦不绝,一生困苦,晚年得安'),
  NumberMeaning(81, Luck.auspicious, '万物回春', '还元复始,最极之数,吉祥重叠'),
];
