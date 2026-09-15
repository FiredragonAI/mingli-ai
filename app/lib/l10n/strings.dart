/// 界面文案,三语。
///
/// 每条文案在一处同时给简体与英文,繁体由 [S2T] 自动转换(需要特殊写法时用 [_t] 单独给)。
/// 这样不会出现"某个 key 忘了翻"的情况——少一种语言编译就过不了。
///
/// 引擎生成的中文内容(神煞含义、数理释义、宜忌条目……)不在这里,
/// 走 [S.term](术语查表英译)或 [S.text](仅做简繁转换)。
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import 'app_language.dart';
import 'glossary.dart';
import 's2t.dart';

class S {
  const S(this.lang);
  final AppLanguage lang;

  /// 随语言切换自动重建。
  static S of(BuildContext context) => S(context.watch<AppState>().language);

  bool get en => lang == AppLanguage.en;

  String _(String zh, String en) => switch (lang) {
        AppLanguage.zhHans => zh,
        AppLanguage.zhHant => S2T.convert(zh),
        AppLanguage.en => en,
      };

  /// 需要单独指定繁体写法时用。
  String _t(String zh, String zhHant, String en) => switch (lang) {
        AppLanguage.zhHans => zh,
        AppLanguage.zhHant => zhHant,
        AppLanguage.en => en,
      };

  /// 命理术语:英文查 [termEnglish],查不到原样;中文做简繁转换。
  String term(String zh) => en ? (termEnglish[zh] ?? zh) : _(zh, zh);

  /// 引擎生成的中文长文本:只做简繁转换,英文界面下仍显示中文(见 docs/SETUP.md 说明)。
  String text(String zh) => _(zh, zh);

  /// 天干名:中文原字;英文 "Jia (Yang Wood)"。
  String stem(int i) => en ? stemEn(i) : _(heavenlyStemsZh[i], heavenlyStemsZh[i]);
  String branch(int i) => en ? branchEn(i) : _(earthlyBranchesZh[i], earthlyBranchesZh[i]);
  String animal(int i) => en ? animalEnglish[i] : _(zodiacAnimalsZh[i], zodiacAnimalsZh[i]);
  String pillar(int i) => en ? pillarEnglish[i] : _(pillarNamesZh[i], pillarNamesZh[i]);

  // ------------------------------------------------------------ 通用
  String get appTitle => _('命理师 AI', 'Mingli AI');
  String get ok => _('确定', 'OK');
  String get cancel => _('取消', 'Cancel');
  String get agree => _('同意', 'Agree');
  String get disagree => _('不同意', 'Decline');
  String get me => _('本人', 'Me');
  String get points => _('分', 'pts');
  String get weight => _('权重', 'weight');
  String ymd(int y, int m, int d) => en ? '$y-${_p(m)}-${_p(d)}' : _('$y 年 $m 月 $d 日', '');
  String get disclaimer => _(
        '内容基于传统文化整理,仅供娱乐参考,不构成任何医疗、法律、投资建议。解读文字由 AI 生成。',
        'Based on traditional culture, for entertainment only; not medical, legal or financial advice. Readings are AI-generated.',
      );

  // ------------------------------------------------------------ 导航
  String get navToday => _('今日', 'Today');
  String get navChart => _('命盘', 'Chart');
  String get navFortune => _('运势', 'Today');
  String get navAlmanac => _('黄历', 'Almanac');
  String get navMore => _('更多', 'More');

  // ------------------------------------------------------------ 今日仪表盘
  String greeting(String name) => _(name.isEmpty ? '你好' : '$name,你好', name.isEmpty ? 'Hello' : 'Hello, $name');
  String get todayScoreLabel => _('今日综合', 'Today');
  String get todayDoAvoid => _('今日宜忌', "Today's do & avoid");
  String get luckyHoursToday => _('今日吉时', 'Auspicious hours');
  String get quickActions => _('探索', 'Explore');
  String get viewFullAlmanac => _('查看完整黄历', 'Full almanac');
  String get viewChart => _('查看命盘', 'View chart');
  String get personaLabel => _('人设', 'Persona');
  String taiSuiBanner(String kinds) => _('今年$kinds,凡事多想一步', 'Tai Sui year ($kinds) — think twice this year');
  String get taiSuiCombineBanner => _('今年合太岁,贵人运旺', 'Tai Sui in harmony this year — helpful people around');
  String get annualQuick => _('年运', 'Year');
  String clashesYourAnimal(String animal) => _('今日冲$animal,大事缓一缓', 'Today clashes with $animal — postpone big decisions');
  String solarTermBanner(String name) => _('今日交$name,节气换挡', 'Solar term today: $name');

  // ------------------------------------------------------------ 流年
  String get annualTitle => _('流年运势', 'Year ahead');
  String get annualSub => _('今年运程 · 犯太岁 · 十二流月', 'This year · Tai Sui · Month by month');
  String annualHeader(int year, String pillar, int age) => _('$year 年 · $pillar年 · $age 虚岁', '$year · $pillar year · age $age');
  String get taiSuiTitle => _('太岁', 'Tai Sui');
  String get offendingTaiSui => _('犯太岁', 'Tai Sui alert');
  String get noTaiSui => _('今年与太岁无刑冲,常规年份', 'No Tai Sui conflict this year');
  String inLuckCycle(String pillar, int nth) => _('所行大运 $pillar · 第 $nth 年', 'Luck cycle $pillar · year $nth');
  String get beforeLuckStart => _('尚未起运', 'Before first luck cycle');
  String get monthlyTitle => _('十二流月', 'Month by month');
  String get monthlyHint => _('按节气月,立春起算;⭐ 最顺 ⚠ 留意', 'Solar-term months from Start of Spring; ⭐ best ⚠ take care');
  String monthApprox(String zhLabel) => en ? const {'1月': 'Jan', '2月': 'Feb', '3月': 'Mar', '4月': 'Apr', '5月': 'May', '6月': 'Jun', '7月': 'Jul', '8月': 'Aug', '9月': 'Sep', '10月': 'Oct', '11月': 'Nov', '12月': 'Dec'}[zhLabel] ?? zhLabel : _(zhLabel, zhLabel);
  String get aiAnnual => _('AI 年运解读', 'AI year reading');
  String get thisYear => _('今年', 'This year');

  // ------------------------------------------------------------ 分享卡
  String get shareCard => _('生成海报', 'Share card');
  String get saveImage => _('保存图片', 'Save image');
  String get shareImage => _('分享', 'Share');
  String get savedTo => _('已保存', 'Saved');
  String get shareCardFooter => _('命理师 AI · 排盘在本机完成 · 仅供娱乐参考', 'Mingli AI · computed on device · for entertainment');
  String get favorableShort => _('喜用', 'Favorable');
  String get dayMasterShort => _('日主', 'Day Master');

  // ------------------------------------------------------------ 大运时间轴
  String get nowMarker => _('现在', 'now');
  String get yearlyLuck => _('流年', 'Years');
  String get tapCycleHint => _('点选一步大运查看十个流年', 'Tap a cycle to see its ten years');

  // ------------------------------------------------------------ 出生信息
  String get birthDetails => _('出生信息', 'Birth details');
  String get partnerBirthDetails => _('对方出生信息', "Partner's birth details");
  String get firstRunTitle => _('请填写出生信息', 'Enter your birth details');
  String get privacyNote => _('所有推算均在本机完成,信息不会上传。', 'All calculations run on this device; nothing is uploaded.');
  String get nameOptional => _('姓名(选填,用于姓名测试)', 'Name (optional, for name analysis)');
  String get male => _('男 · 乾造', 'Male');
  String get female => _('女 · 坤造', 'Female');
  String get birthDate => _('出生日期(公历)', 'Date of birth');
  String get birthTime => _('出生时间', 'Time of birth');
  String get timeExact => _('精确时间', 'Exact time');
  String get timeShichen => _('只知时辰', 'Two-hour period');
  String get timeUnknown => _('不确定', 'Unknown');
  String get timeUnknownHint => _('按正午估算,时柱仅供参考', 'Estimated at noon; the hour pillar is approximate');
  String get timeShichenHint => _('按该时辰中点排盘', 'Chart uses the midpoint of the period');
  String shichen(int b) => en ? shichenEnglish[b] : _('${earthlyBranchesZh[b]}时 ${_shichenRange(b)}', '');
  String get birthPlace => _('出生地(省/直辖市)', 'Birthplace (province / region)');
  String get startChart => _('开始排盘', 'Create chart');

  // ------------------------------------------------------------ 命盘
  String get chartTitle => _('八字命盘', 'Four Pillars');
  String get editBirth => _('编辑出生信息', 'Edit birth details');
  String get gregorian => _('公历', 'Gregorian');
  String trueSolar(String clock, String lon, String eot) => _(
        '真太阳时 $clock(经度 $lon 分,均时差 $eot 分)',
        'True solar time $clock (longitude $lon min, equation of time $eot min)',
      );
  String termDistance(String prev, String daysAfter, String next, String daysBefore) => _(
        '$prev后 $daysAfter 天,距$next $daysBefore 天',
        '$daysAfter days after $prev, $daysBefore days before $next',
      );
  String get hourEstimated => _('时柱为估算(出生时间不确定),涉及时柱的结论仅供参考', 'Hour pillar is estimated (birth time unknown); conclusions involving it are approximate');
  String get zodiacChip => _('生肖', 'Animal');
  String get dayMasterChip => _('日主', 'Day Master');
  String get taiYuan => _('胎元', 'Tai Yuan');
  String get mingGong => _('命宫', 'Life Palace');
  String get shenGong => _('身宫', 'Body Palace');
  String get interactions => _('刑冲合害', 'Interactions');
  String get shenSha => _('神煞', 'Stars');
  String get noShenSha => _('无显著神煞', 'No notable stars');
  String get luckCycles => _('大运', 'Luck cycles');
  String get aiBazi => _('AI 命理解读', 'AI reading');
  String get pillarSuffix => _('柱', ' Pillar');
  String get tenGods => _('十神', 'Ten Gods');
  String get stemRow => _('天干', 'Stem');
  String get branchRow => _('地支', 'Branch');
  String get hiddenRow => _('藏干', 'Hidden');
  String get naYinRow => _('纳音', 'Na Yin');
  String get lifeStageRow => _('长生', 'Stage');
  String get voidMark => _('空', 'void');
  String get elementStrength => _('五行力量', 'Five Elements');
  String get favorable => _('喜', 'Favorable');
  String get unfavorable => _('忌', 'Avoid');
  String get missing => _('缺', 'Missing');
  String get reasoning => _('推断依据', 'Reasoning');
  String get age => _('岁', 'y');

  // ------------------------------------------------------------ AI 卡片
  String get badgeFallback => _('云端暂不可用 · 本机生成', 'Cloud unavailable · generated locally');
  String get badgeLocal => _('本机生成 · 未联网', 'Generated locally · offline');
  String get badgeCached => _('已缓存', 'Cached');
  String get hintCloud => _('点击下方按钮,由 AI 为您解读这份盘面。', 'Tap below and the AI will interpret this chart.');
  String get hintLocal => _('点击下方按钮,由本机规则引擎生成解读(无需联网)。', 'Tap below to generate a reading on this device (no internet needed).');
  String get hintFallback => _('当前连不上云端,将由本机规则引擎生成解读;联网后点"重新生成"可获得 AI 版本。', 'Cloud is unreachable; a reading will be generated on this device. Regenerate when online for the AI version.');
  String get hintUnavailable => _('当前无法连接解读服务,请检查网络。', 'Cannot reach the reading service. Check your connection.');
  String get generate => _('开始解读', 'Generate');
  String get regenerate => _('重新生成', 'Regenerate');
  String failed(String e) => _('解读失败:$e', 'Failed: $e');

  // ------------------------------------------------------------ 运势
  String get todayFortune => _('今日运势', "Today's fortune");
  String fortuneDate(int y, int m, int d, String pillar) => _('$y 年 $m 月 $d 日 · $pillar日', '${ymd(y, m, d)} · $pillar day');
  String todayTheme(String god, String group) => _('今日$god($group)', 'Today: $god ($group)');
  String get overall => _('综合', 'Overall');
  String get career => _('事业', 'Career');
  String get wealth => _('财运', 'Wealth');
  String get love => _('感情', 'Love');
  String get health => _('健康', 'Health');
  String get luckyColor => _('幸运色', 'Lucky color');
  String get luckyNumbers => _('幸运数', 'Lucky numbers');
  String get luckyDirection => _('吉方', 'Lucky direction');
  String get nextSevenDays => _('未来七天', 'Next 7 days');
  String get factors => _('影响因素', 'Factors');
  String get aiDaily => _('AI 今日指引', 'AI daily guidance');

  // ------------------------------------------------------------ 黄历
  String get almanac => _('黄历', 'Almanac');
  String get backToToday => _('回到今天', 'Today');
  String weekday(int i) => en
      ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i - 1]
      : _('星期${['一', '二', '三', '四', '五', '六', '日'][i - 1]}', '');
  String almanacLine(String animal, String jianChu, String zhiShen, bool huang, String xiu) => _(
        '属$animal · $jianChu日 · $zhiShen(${huang ? '黄道' : '黑道'}) · $xiu',
        '$animal · ${term(jianChu)} day · ${term(zhiShen)} (${huang ? 'auspicious' : 'inauspicious'}) · $xiu',
      );
  String solarTermToday(String name) => _('今日 $name', 'Solar term: $name');
  String get suitable => _('宜', 'Do');
  String get unsuitable => _('忌', 'Avoid');
  String get nothingSuitable => _('—', '—');
  String get clash => _('冲煞', 'Clash');
  String get auspiciousGods => _('吉神', 'Good stars');
  String get inauspiciousGods => _('凶神', 'Bad stars');
  String get joyGod => _('喜神', 'Joy');
  String get wealthGod => _('财神', 'Wealth');
  String get pengZu => _('彭祖', 'Peng Zu');
  String get hourFortunes => _('时辰吉凶', 'Hours');
  String get whyRules => _('宜忌依据', 'Why');
  String get aiAlmanac => _('AI 择日建议', 'AI date advice');

  // ------------------------------------------------------------ 更多
  String get more => _('更多', 'More');
  String get zodiac => _('星座', 'Zodiac');
  String get zodiacSub => _('太阳星座 · 上升星座 · 配对', 'Sun sign · Rising sign · Compatibility');
  String get marriage => _('合婚', 'Compatibility');
  String get marriageSub => _('两人八字六维匹配 · 星座配对', 'Two-chart match · Zodiac pairing');
  String get naming => _('姓名测试', 'Name analysis');
  String get namingSub => _('五格剖象 · 三才 · 八字补益', 'Five grids · Three talents · Chart balance');
  String get palmAi => _('手相 AI', 'Palm AI');
  String get palmSub => _('照片仅在本机分析', 'Photos analysed on device only');
  String get faceAi => _('面相 AI', 'Face AI');
  String get faceSub => _('三停五眼 · 十二宫', 'Proportions · Twelve palaces');
  String get settings => _('设置', 'Settings');
  String settingsSub(String status) => _('档案管理 · 解读服务 $status', 'Profiles · Reading service: $status');
  String get statusLocal => _('离线本地', 'offline/local');
  String get statusConnected => _('已连接', 'connected');
  String get statusDisconnected => _('未连接', 'not connected');

  // ------------------------------------------------------------ 设置
  String get profiles => _('档案', 'Profiles');
  String get addProfile => _('新增档案', 'Add profile');
  String get language => _('语言', 'Language');
  String get readingService => _('解读服务', 'Reading service');
  String get forceLocalTitle => _('始终使用离线本地解读', 'Always use offline local readings');
  String get forceLocalSub => _(
        '开:一律由本机规则引擎生成,不联网。关:能连上云端就用 AI,连不上时自动改用本机生成,不会空白。',
        'On: always generated on this device, never online. Off: use the AI when the cloud is reachable, otherwise fall back to local automatically.',
      );
  String get serverUrl => _('云端服务器地址', 'Cloud server URL');
  String get serverDisabledHint => _('已切换到离线本地解读,此项暂不生效', 'Offline mode is on; this setting is inactive');
  String get resetUrl => _('恢复默认地址', 'Reset to default');
  String get privacy => _('隐私', 'Privacy');
  String get consentTitle => _('允许在本机处理手掌/面部照片', 'Allow on-device palm/face photo analysis');
  String get consentSub => _('关闭后手相、面相功能将再次征求同意', 'If off, Palm/Face AI will ask again');
  String get about => _('关于', 'About');
  String get aboutSub => _('排盘在本机完成;解读文字由 AI 生成,仅供娱乐参考。', 'Charts are computed on device; readings are AI-generated, for entertainment only.');

  // ------------------------------------------------------------ 合婚
  String get addPartner => _('添加对方出生信息', "Add partner's birth details");
  String animalAndDayMaster(String animal, String dm) => _('属$animal · 日主$dm', '$animal · Day Master $dm');
  String get aiMarriage => _('AI 合婚解读', 'AI compatibility reading');
  String get zodiacMatchTitle => _('星座配对', 'Zodiac pairing');

  // ------------------------------------------------------------ 姓名
  String get name => _('姓名', 'Name');
  String get nameHint => _t('如:李思晨', '如:李思晨', 'e.g. 李思晨');
  String get analyze => _('测算', 'Analyze');
  String get nameLengthError => _('请输入 2–6 个汉字的姓名', 'Enter a Chinese name of 2–6 characters');
  String get unknownCharsHint => _('提示:部分字未查到康熙笔画,按 0 画计', 'Some characters have no Kangxi stroke count and were counted as 0');
  String sanCai(String text, int score) => _('三才 $text · $score 分', 'Three Talents $text · $score');
  String get chartBalance => _('八字补益', 'Chart balance');
  String get zodiacChars => _('生肖用字', 'Zodiac characters');
  String get aiName => _('AI 姓名解读', 'AI name reading');

  // ------------------------------------------------------------ 手相 / 面相
  String get consentDialogTitle => _('关于您的照片', 'About your photo');
  String get consentDialogBody => _(
        '手掌或面部照片属于敏感个人信息。\n\n• 照片只在本机内存中分析,不保存、不上传;\n• 发送给解读服务的仅是比例、角度等几何数据,无法还原出您的照片;\n• 您可随时在"设置"中撤回同意。\n\n是否同意在本机处理您的照片?',
        'Palm and face photos are sensitive personal data.\n\n• Photos are analysed in memory on this device only — never saved or uploaded;\n• Only geometric ratios and angles are sent to the reading service; your photo cannot be reconstructed from them;\n• You can withdraw consent anytime in Settings.\n\nAllow on-device processing of your photo?',
      );
  String get palmInstruction => _('张开手掌,掌心朝向镜头,光线均匀无阴影。全身照、生活照也可以,程序会自动定位手掌。', 'Open your palm facing the camera in even light. Full-body or casual photos work too — the palm is located automatically.');
  String get faceInstruction => _('正对镜头,露出额头与下巴,表情自然,光线均匀。全身照、合照也可以,程序会自动定位人脸。', 'Face the camera with forehead and chin visible, neutral expression, even light. Full-body or group photos work too — the face is located automatically.');
  String get takePhoto => _('拍照', 'Take photo');
  String get choosePhoto => _('选择照片', 'Choose photo');
  String get photoLocalOnly => _('照片仅在本机分析,不会上传。', 'Photos are analysed on this device only.');
  String get imagesGroup => _('图片', 'Images');
  String get allFilesGroup => _('所有文件', 'All files');
  String decodeError(String ext) => _(
        '无法解码这张图片$ext。支持 JPG / PNG / WebP / BMP / GIF / TIFF 等常见格式;iPhone 的 HEIC 照片请先在手机相册里"导出为 JPG"再选择。',
        'Cannot decode this image$ext. JPG / PNG / WebP / BMP / GIF / TIFF are supported; for iPhone HEIC photos, export as JPG first.',
      );
  String get noHand => _('未检测到手掌。请让手掌张开、掌心朝向镜头;全身照也可以,但手掌别被遮挡。', 'No palm detected. Open your palm towards the camera; full-body photos are fine as long as the palm is not hidden.');
  String get noFace => _('未检测到人脸。请确保脸部无遮挡、光线均匀;全身照可以,但侧脸或过小的脸识别不了。', 'No face detected. Make sure the face is unobstructed and evenly lit; full-body photos are fine, but profiles or very small faces cannot be read.');
  String get palmAspect => _('掌长/掌宽', 'Palm length/width');
  String get fingerToPalm => _('中指/掌长', 'Middle finger/palm');
  String get thumbAngle => _('拇指张角', 'Thumb angle');
  String lineStats(String len, String curve, int breaks) => _(
        '长 $len · 弯 $curve${breaks > 0 ? ' · 断 $breaks' : ''}',
        'len $len · curve $curve${breaks > 0 ? ' · breaks $breaks' : ''}',
      );
  String get threeCourts => _('三停', 'Three courts');
  String get fiveEyes => _('五眼', 'Five eyes');
  String symmetry(int pct) => _('对称度 $pct%', 'Symmetry $pct%');
  String get aiPalm => _('AI 手相解读', 'AI palm reading');
  String get aiFace => _('AI 面相解读', 'AI face reading');
  String get locatedNote => _('定位说明', 'Detection');

  // ------------------------------------------------------------ 星座元素 / 三态
  String zodiacElement(String zhLabel) => en
      ? const {'火': 'Fire', '土': 'Earth', '风': 'Air', '水': 'Water'}[zhLabel] ?? zhLabel
      : _(zhLabel, zhLabel);
  String zodiacModality(String zhLabel) => en
      ? const {'基本': 'Cardinal', '固定': 'Fixed', '变动': 'Mutable'}[zhLabel] ?? zhLabel
      : _(zhLabel, zhLabel);

  // ------------------------------------------------------------ 星座
  String risingSign(String name) => _('上升 $name', 'Rising $name');
  String get risingUnknown => _('上升星座:信息不足', 'Rising sign: not enough data');
  String get risingNeedsPlace => _('需要出生地经纬度', 'Needs birthplace coordinates');
  String get risingNote => _('上升星座约每两小时换一个,依赖准确出生时间。', 'The rising sign changes about every two hours and depends on an accurate birth time.');
  String elementSign(String el) => _('$el象', '$el sign');
  String modalitySign(String m) => _('$m星座', m);
  String ruler(String r) => _('守护星 $r', 'Ruler: $r');
  String sunDegree(String d) => _('太阳 $d°', 'Sun $d°');
  String cuspNote(String neighbour) => _(
        '出生在换宫日附近,距$neighbour边界不到 1°,两座特质可能兼有。',
        'Born on a cusp — less than 1° from $neighbour; traits of both signs may apply.',
      );
  String get personality => _('性格画像', 'Personality');
  String get keywords => _('关键词', 'Keywords');
  String get strengths => _('优势', 'Strengths');
  String get watchOut => _('需留意', 'Watch out');
  String luckyLine(String color, String nums) => _('幸运色 $color · 幸运数字 $nums', 'Lucky color $color · Lucky numbers $nums');
  String bestMatches(String sign) => _('与$sign较合拍:', 'Best matches for $sign:');
  String get pairingHint => _('在"合婚"里填写对方出生信息后,这里会显示两人的星座配对。', "Add your partner's birth details under Compatibility to see your zodiac pairing here.");
  String get aiZodiac => _('AI 星座解读', 'AI zodiac reading');

  // ------------------------------------------------------------ 内部
  static String _p(int v) => v.toString().padLeft(2, '0');
  static String _shichenRange(int b) {
    final start = (b * 2 + 23) % 24;
    return '${_p(start)}:00–${_p((start + 2) % 24)}:00';
  }
}

// 与 core/calendar/sexagenary.dart 同序;这里复制一份避免 l10n 层反向依赖 UI 之外的东西太多。
const List<String> heavenlyStemsZh = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const List<String> earthlyBranchesZh = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
const List<String> zodiacAnimalsZh = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];
const List<String> pillarNamesZh = ['年', '月', '日', '时'];
