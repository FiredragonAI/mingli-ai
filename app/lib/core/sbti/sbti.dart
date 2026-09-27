/// SBTI 玩梗测试(Silly Big Type Indicator)。
///
/// 2026 年 4 月刷屏的那个"MBTI 过时了,SBTI 来了"的戏仿测试的同款玩法:
/// 30 道三选一,15 个维度,每维两题;维度分压成低/中/高三档,
/// 再和一组人格模板比对——先看总差最小,再看完全命中的维度最多。
/// 题目、维度、类型和文案都是本项目原创,只借了"玩法"和"自嘲的味道"。
///
/// 全部纯 Dart、确定性:同一组答案永远得到同一个类型,方便测试和分享截图对得上。
/// 内容分级对齐 Play 的"所有人":损人但不刻薄,没有脏字。
library;

import '../bazi/five_elements.dart';

enum SbtiTier { low, mid, high }

class SbtiDimension {
  const SbtiDimension(this.zh, this.en, {required this.zhHigh, required this.enHigh, required this.zhLow, required this.enLow});
  final String zh;
  final String en;

  /// 该维度拉满 / 见底时,结果页里怎么说这个人。
  final String zhHigh;
  final String enHigh;
  final String zhLow;
  final String enLow;
}

class SbtiOption {
  const SbtiOption(this.zh, this.en, this.score) : assert(score >= 1 && score <= 3);
  final String zh;
  final String en;
  final int score;
}

class SbtiQuestion {
  const SbtiQuestion(this.dim, this.zh, this.en, this.options);
  final int dim;
  final String zh;
  final String en;
  final List<SbtiOption> options;
}

class SbtiType {
  const SbtiType({
    required this.code,
    required this.zhName,
    required this.enName,
    required this.zhTagline,
    required this.enTagline,
    required this.zhRoast,
    required this.enRoast,
    required this.zhTip,
    required this.enTip,
    required this.rarityPct,
    required String profile,
  }) : _profile = profile;

  final String code;
  final String zhName;
  final String enName;

  /// 一句可以被截图转发的话。
  final String zhTagline;
  final String enTagline;
  final String zhRoast;
  final String enRoast;
  final String zhTip;
  final String enTip;

  /// "稀有度"——玩梗用的数字,全部类型加起来正好 100。
  final int rarityPct;

  final String _profile;

  /// 15 维模板,L/M/H 各一位,顺序同 [sbtiDimensions]。
  List<SbtiTier> get profile => [
        for (final c in _profile.split(''))
          switch (c) { 'L' => SbtiTier.low, 'H' => SbtiTier.high, _ => SbtiTier.mid },
      ];
}

class SbtiResult {
  const SbtiResult({
    required this.type,
    required this.scores,
    required this.tiers,
    required this.totalDiff,
    required this.exactMatches,
  });

  final SbtiType type;

  /// 每维 2–6 分。
  final List<int> scores;
  final List<SbtiTier> tiers;

  /// 与模板的总档差 / 完全命中的维度数,给"匹配度"展示用。
  final int totalDiff;
  final int exactMatches;

  /// 拉满的维度(高档),按分数降序,最多两个。
  List<int> get highDims {
    final hs = [for (var i = 0; i < tiers.length; i++) if (tiers[i] == SbtiTier.high) i]
      ..sort((a, b) => scores[b].compareTo(scores[a]));
    return hs.take(2).toList();
  }

  /// 见底的维度(低档),按分数升序,最多两个。
  List<int> get lowDims {
    final ls = [for (var i = 0; i < tiers.length; i++) if (tiers[i] == SbtiTier.low) i]
      ..sort((a, b) => scores[a].compareTo(scores[b]));
    return ls.take(2).toList();
  }

  /// 0–100,总差为 0 是 100;每差一档扣 5。
  int get matchPct => (100 - totalDiff * 5).clamp(40, 100);
}

// ---------------------------------------------------------------- 维度

/// 5 个板块 × 3 个维度。索引顺序在题目和模板里都要对上,别乱动。
const List<SbtiDimension> sbtiDimensions = [
  // 自我
  SbtiDimension('自恋度', 'Ego', zhHigh: '自恋拉满', enHigh: 'ego maxed', zhLow: '对自己太狠', enLow: 'too hard on yourself'),
  SbtiDimension('拖延度', 'Procrastination', zhHigh: '拖延成精', enHigh: 'a procrastination pro', zhLow: '一秒都不肯拖', enLow: "can't wait a second"),
  SbtiDimension('松弛度', 'Chill', zhHigh: '松弛到躺平', enHigh: 'chill to the point of horizontal', zhLow: '弦绷得太紧', enLow: 'wound way too tight'),
  // 情绪
  SbtiDimension('玻璃心', 'Fragility', zhHigh: '玻璃心易碎', enHigh: 'glass heart', zhLow: '刀枪不入', enLow: 'bulletproof'),
  SbtiDimension('情绪稳定', 'Stability', zhHigh: '稳得像没插电', enHigh: 'suspiciously stable', zhLow: '情绪过山车', enLow: 'emotional rollercoaster'),
  SbtiDimension('戏精值', 'Drama', zhHigh: '内心小剧场常驻', enHigh: 'resident drama lead', zhLow: '面无表情', enLow: 'zero drama'),
  // 态度
  SbtiDimension('卷度', 'Hustle', zhHigh: '卷王附体', enHigh: 'grinder mode', zhLow: '拒绝内卷', enLow: 'refuses to grind'),
  SbtiDimension('玄学依赖', 'Mysticism', zhHigh: '万事先问水逆', enHigh: 'consults Mercury first', zhLow: '铁杆唯物', enLow: 'hard materialist'),
  SbtiDimension('嘴硬度', 'Stubborn talk', zhHigh: '嘴硬如铁', enHigh: 'never backs down out loud', zhLow: '秒认怂', enLow: 'folds instantly'),
  // 驱动
  SbtiDimension('金钱敏感', 'Money radar', zhHigh: '人间计算器', enHigh: 'walking calculator', zhLow: '钱是数字', enLow: 'money is just numbers'),
  SbtiDimension('三分钟热度', 'Spark', zhHigh: '三分钟热度永动机', enHigh: 'infinite three-minute passions', zhLow: '一件事做到底', enLow: 'finishes what they start'),
  SbtiDimension('精神股东', 'Armchair CEO', zhHigh: '万物精神股东', enHigh: 'armchair CEO of everything', zhLow: '不发表意见', enLow: 'keeps opinions to self'),
  // 社交
  SbtiDimension('社交电量', 'Social battery', zhHigh: '社交永不断电', enHigh: 'social battery never dies', zhLow: '社交电量 5%', enLow: 'social battery at 5%'),
  SbtiDimension('鸽子度', 'Flakiness', zhHigh: '鸽王', enHigh: 'the flake', zhLow: '说到必到', enLow: 'always shows up'),
  SbtiDimension('恋爱脑', 'Lovestruck', zhHigh: '恋爱脑晚期', enHigh: 'terminally lovestruck', zhLow: '感情绝缘体', enLow: 'romance-proof'),
];

// ---------------------------------------------------------------- 题目


/// 30 题,每维两题;顺序故意把五个板块打散,连着答不容易看出在测什么。
const List<SbtiQuestion> sbtiQuestions = [
  // 第一轮
  SbtiQuestion(0, '照镜子的时候,你通常在想:', 'Looking in the mirror, you usually think:', [
    SbtiOption('这谁啊,这么好看', 'Who is this stunning person', 3),
    SbtiOption('还行吧,能出门', "Fine, presentable", 2),
    SbtiOption('镜子今天有点脏', 'The mirror seems dirty today', 1),
  ]),
  SbtiQuestion(3, '朋友聊天里回你"哦",你会:', 'A friend replies "ok." to your message. You:', [
    SbtiOption('翻来覆去想是不是我哪句说错了', 'Replay the whole conversation looking for your mistake', 3),
    SbtiOption('也回一个"哦"', 'Reply "ok." back', 1),
    SbtiOption('心里咯噔一下,然后忘了', 'Wince, then forget about it', 2),
  ]),
  SbtiQuestion(6, '周末下午两点,你在:', "It's 2 pm on a Saturday. You are:", [
    SbtiOption('上课/加班/学新技能', 'In a class, at work, or learning a new skill', 3),
    SbtiOption('刚醒', 'Just waking up', 1),
    SbtiOption('看别人上课/加班的视频', 'Watching videos of other people being productive', 2),
  ]),
  SbtiQuestion(9, '朋友请客吃饭,你的第一反应:', 'A friend picks up the bill. Your first thought:', [
    SbtiOption('这顿多少钱,我下次得回请一样的', 'How much was that? I owe an equal dinner', 3),
    SbtiOption('谢谢,下次我来', 'Thanks, next one is on me', 2),
    SbtiOption('好吃', 'Yum', 1),
  ]),
  SbtiQuestion(12, '一场三小时的饭局结束后,你:', 'After a three-hour dinner party, you:', [
    SbtiOption('提议再去第二场', 'Suggest a second venue', 3),
    SbtiOption('回家躺平,明天不想见人', 'Go home, lie down, and need a people-free tomorrow', 1),
    SbtiOption('刚好,再多一小时就不行了', 'That was exactly enough; one more hour would have broken you', 2),
  ]),
  SbtiQuestion(1, '一件不急的事,你一般什么时候做:', 'A task with no deadline gets done:', [
    SbtiOption('等它变急了', 'Once it becomes urgent', 3),
    SbtiOption('当天顺手做掉', 'The same day, while you are at it', 1),
    SbtiOption('列进清单,然后看着清单', 'It goes on a list; you then look at the list', 2),
  ]),
  SbtiQuestion(4, '手机掉进水里,你的表情:', 'Your phone falls into water. Your face:', [
    SbtiOption('毫无波澜,捞起来擦干', 'Blank. Fish it out, dry it off', 3),
    SbtiOption('一声尖叫', 'One scream', 1),
    SbtiOption('深呼吸三次', 'Three deep breaths', 2),
  ]),
  SbtiQuestion(7, '早上出门前,你会:', 'Before leaving the house, you:', [
    SbtiOption('看一眼今天的运势/黄历', "Check today's horoscope or almanac", 3),
    SbtiOption('看天气', 'Check the weather', 1),
    SbtiOption('偶尔看运势,主要看天气', 'Mostly the weather, occasionally the horoscope', 2),
  ]),
  SbtiQuestion(10, '你手机里没打开超过一个月的 App 大概有:', 'Apps on your phone untouched for a month:', [
    SbtiOption('数不清,好几屏', 'Too many to count; several screens', 3),
    SbtiOption('三五个', 'Three to five', 2),
    SbtiOption('没有,不用就删', 'None; unused gets deleted', 1),
  ]),
  SbtiQuestion(13, '约好的聚会当天,你:', 'The day of a planned meetup, you:', [
    SbtiOption('准时出现', 'Show up on time', 1),
    SbtiOption('开始盘算怎么说"临时有事"', 'Start drafting a "something came up"', 3),
    SbtiOption('去,但心里已经想回家了', 'Go, already wishing you were home', 2),
  ]),
  SbtiQuestion(2, '你对"计划"的态度:', 'Your relationship with plans:', [
    SbtiOption('随缘,走哪算哪', 'Go with the flow', 3),
    SbtiOption('精确到小时', 'Scheduled to the hour', 1),
    SbtiOption('有个大概方向就行', 'A rough direction is enough', 2),
  ]),
  SbtiQuestion(5, '别人当众夸你,你:', 'Someone compliments you in front of others. You:', [
    SbtiOption('嘴上说没有没有,内心已经开始领奖', 'Say "oh no, not at all" while accepting an award internally', 3),
    SbtiOption('说声谢谢', 'Say thanks', 1),
    SbtiOption('有点脸红', 'Blush a little', 2),
  ]),
  SbtiQuestion(8, '吵架的时候发现自己错了,你会:', 'Mid-argument you realise you are wrong. You:', [
    SbtiOption('继续吵,错的方向也要吵赢', 'Keep arguing; being wrong is no reason to lose', 3),
    SbtiOption('马上认', 'Admit it right away', 1),
    SbtiOption('换个话题', 'Change the subject', 2),
  ]),
  SbtiQuestion(11, '看到公司/球队/国家队做决定,你:', 'Your company, team, or national squad makes a decision. You:', [
    SbtiOption('"要是我来管……"', '"If I were in charge…"', 3),
    SbtiOption('关我什么事', 'Not my department', 1),
    SbtiOption('看看评论区怎么说', 'Check what the comments say', 2),
  ]),
  SbtiQuestion(14, '对方发来一句"在吗",你:', 'Your crush texts "you there?" You:', [
    SbtiOption('已经开始想我们孩子叫什么了', 'Already naming your future children', 3),
    SbtiOption('"在,怎么了"', '"Yes, what is up"', 1),
    SbtiOption('心跳快了一点', 'Heart rate ticks up slightly', 2),
  ]),
  // 第二轮
  SbtiQuestion(0, '看自己的照片时,你:', 'Looking at photos of yourself, you:', [
    SbtiOption('越看越顺眼', 'They grow on you every time', 3),
    SbtiOption('这拍得也太丑了', 'Who took this terrible picture', 1),
    SbtiOption('有的行,有的不行', 'Some work, some do not', 2),
  ]),
  SbtiQuestion(3, '发的动态半天没人点赞,你:', 'Your post gets no likes for hours. You:', [
    SbtiOption('删了', 'Delete it', 3),
    SbtiOption('无所谓,发给自己看的', 'Whatever, it was for you anyway', 1),
    SbtiOption('刷新几次', 'Refresh a few times', 2),
  ]),
  SbtiQuestion(6, '朋友说"最近好累",你的回应:', 'A friend says they are exhausted. You:', [
    SbtiOption('累说明在进步', 'Tired means growing', 3),
    SbtiOption('那就歇着,别硬撑', 'Then rest; do not push', 1),
    SbtiOption('我也累', 'Same', 2),
  ]),
  SbtiQuestion(9, '购物车里的东西,你一般:', 'Items in your shopping cart usually:', [
    SbtiOption('比三家、等折扣、算凑单', 'Get price-compared, discount-timed, and bundle-optimised', 3),
    SbtiOption('想要就买', 'Get bought when wanted', 1),
    SbtiOption('放几天,还想要再买', 'Sit a few days; bought if still wanted', 2),
  ]),
  SbtiQuestion(12, '一个人的周末,你的感受:', 'A weekend entirely alone feels:', [
    SbtiOption('太爽了,充电', 'Amazing. Recharging', 1),
    SbtiOption('有点闷,找人出来', 'A bit dull; time to call someone', 3),
    SbtiOption('一天可以,两天有点多', 'One day is great, two is a lot', 2),
  ]),
  SbtiQuestion(1, '闹钟响了,你:', 'The alarm goes off. You:', [
    SbtiOption('起', 'Get up', 1),
    SbtiOption('再睡五分钟(×6)', 'Five more minutes (times six)', 3),
    SbtiOption('再睡五分钟(×1)', 'Five more minutes (once)', 2),
  ]),
  SbtiQuestion(4, '朋友形容你的情绪,更像:', 'Friends would describe your moods as:', [
    SbtiOption('恒温', 'Thermostat', 3),
    SbtiOption('天气', 'Weather', 2),
    SbtiOption('股市', 'The stock market', 1),
  ]),
  SbtiQuestion(7, '连续倒霉三天,你会觉得:', 'Three unlucky days in a row. You conclude:', [
    SbtiOption('水逆了/犯太岁了', 'Mercury is in retrograde, or it is a Tai Sui year', 3),
    SbtiOption('巧合', 'Coincidence', 1),
    SbtiOption('虽然不信,但还是查了一下', 'You do not believe it, but you looked it up anyway', 2),
  ]),
  SbtiQuestion(10, '你开始过的爱好里,坚持超过一年的:', 'Of the hobbies you have started, those lasting over a year:', [
    SbtiOption('基本都坚持了', 'Most of them', 1),
    SbtiOption('想不起来有哪个', 'None come to mind', 3),
    SbtiOption('一两个', 'One or two', 2),
  ]),
  SbtiQuestion(13, '"改天约"这句话,你说的时候:', 'When you say "let us do this some other day", you:', [
    SbtiOption('是认真的,并且会定日子', 'Mean it, and will pick a date', 1),
    SbtiOption('就是客气', 'Are being polite', 3),
    SbtiOption('五五开', 'Fifty-fifty', 2),
  ]),
  SbtiQuestion(2, '出门旅行,你的行李:', 'Packing for a trip, your luggage is:', [
    SbtiOption('前一晚随便塞', 'Stuffed the night before', 3),
    SbtiOption('提前一周列清单打包', 'Listed and packed a week early', 1),
    SbtiOption('提前一天,大概齐', 'Done the day before, roughly', 2),
  ]),
  SbtiQuestion(5, '看电影哭的次数:', 'How often you cry at movies:', [
    SbtiOption('片头曲就能哭', 'The opening credits can do it', 3),
    SbtiOption('基本不哭', 'Rarely', 1),
    SbtiOption('看片子', 'Depends on the film', 2),
  ]),
  SbtiQuestion(8, '别人指出你的错误,你的第一句话:', 'Someone points out your mistake. Your first words:', [
    SbtiOption('"我知道啊"', '"I know"', 3),
    SbtiOption('"啊,谢谢"', '"Oh, thanks"', 1),
    SbtiOption('"嗯……"', '"Hmm…"', 2),
  ]),
  SbtiQuestion(11, '看比赛/看剧的时候,你:', 'Watching a match or a show, you:', [
    SbtiOption('全程指挥,"换人!这不对!"', 'Direct the whole thing. "Sub him off! Wrong call!"', 3),
    SbtiOption('安静看', 'Watch quietly', 1),
    SbtiOption('偶尔吐槽', 'Occasional commentary', 2),
  ]),
  SbtiQuestion(14, '你对"暧昧"的容忍度:', 'Your tolerance for a situationship:', [
    SbtiOption('可以暧昧一辈子', 'Could stay in one forever', 3),
    SbtiOption('三天不表态就拉黑', 'Three days without clarity and they are blocked', 1),
    SbtiOption('一两个月吧', 'A month or two', 2),
  ]),
];

// ---------------------------------------------------------------- 类型

/// 21 个类型。模板按 [sbtiDimensions] 顺序,L/M/H 各一位;稀有度加起来正好 100。
const List<SbtiType> sbtiTypes = [
  SbtiType(
    code: 'TANG',
    zhName: '躺平仙',
    enName: 'The Horizontal',
    zhTagline: '你不是懒,你是提前退休。',
    enTagline: 'You are not lazy. You retired early.',
    zhRoast: '全国只有 8% 的人能像你这样,把"算了"说得如此心安理得。别人在卷,你在看云;别人焦虑,你在想晚饭吃什么。松弛感这个词就是照着你发明的——问题是它已经松到快掉地上了。',
    enRoast: 'Only 8% of people can say "never mind" with your level of inner peace. Others grind; you watch clouds. Others panic; you think about dinner. "Chill" was coined with you in mind — the trouble is it has gone so slack it is about to hit the floor.',
    zhTip: '躺着挺好,记得偶尔翻个身。',
    enTip: 'Lying down is fine. Just turn over now and then.',
    rarityPct: 8,
    profile: 'MMHMMMLMMMLMMMM',
  ),
  SbtiType(
    code: 'JUAN',
    zhName: '卷王附体',
    enName: 'The Grinder',
    zhTagline: '你的休息,是换一种方式工作。',
    enTagline: 'Your idea of rest is working differently.',
    zhRoast: '6% 的人和你一样,把日程表排得比地铁还准。你不是不会放松,你是放松的时候会愧疚。朋友约你吃饭要提前两周,你连做梦都在复盘。世界确实需要你这样的人——但你也需要睡觉。',
    enRoast: 'Like 6% of people, your calendar runs tighter than a subway timetable. It is not that you cannot relax; you just feel guilty while doing it. Friends need two weeks notice for dinner and you debrief in your dreams. The world needs people like you. You also need sleep.',
    zhTip: '把"休息"也写进日程,不然你不会做。',
    enTip: 'Schedule rest, or it will never happen.',
    rarityPct: 6,
    profile: 'MLLMMMHMMMMMMMM',
  ),
  SbtiType(
    code: 'GEZI',
    zhName: '鸽王',
    enName: 'The Flake',
    zhTagline: '你说"改天",天知道是哪天。',
    enTagline: '"Some other day" — nobody, including you, knows which.',
    zhRoast: '5% 的稀有物种。你答应的时候是真心的,放鸽子的时候也是真心的——真心不想出门。你的朋友已经学会把你的"一定来"自动翻译成"看心情"。奇怪的是,他们还是会约你。',
    enRoast: 'A 5% rarity. You mean it when you say yes, and you mean it when you cancel — you truly do not want to leave the house. Friends now auto-translate your "definitely coming" to "depends on the mood". Strangely, they keep inviting you.',
    zhTip: '下次想鸽的时候,先鸽自己一次。',
    enTip: 'Next time you want to flake, flake on the flaking.',
    rarityPct: 5,
    profile: 'MHMMMMMMMMMMLHM',
  ),
  SbtiType(
    code: 'SOC',
    zhName: '社交省电模式',
    enName: 'Low-Battery Socialite',
    zhTagline: '电量 5%,只够回一个表情。',
    enTagline: 'Battery at 5% — enough for one emoji.',
    zhRoast: '7% 的人像你一样,聚会两小时就开始偷偷看表。你不是不合群,你是合群成本太高。嘴上很稳,心里的小人已经打车走了。好消息是:你的朋友虽然少,但都是充电宝。',
    enRoast: 'Like 7% of people, you start sneaking looks at the clock two hours into any gathering. You are not antisocial; being social is just expensive. Composed on the outside, your inner self already called a cab. Good news: your few friends are all power banks.',
    zhTip: '省电没错,别忘了充。',
    enTip: 'Saving power is fine. Remember to charge.',
    rarityPct: 7,
    profile: 'MMMMHMMMHMMMLMM',
  ),
  SbtiType(
    code: 'MOUTH',
    zhName: '嘴上功夫',
    enName: 'All Talk',
    zhTagline: '你的计划,在讲出来的那一刻就完成了。',
    enTagline: 'Your plans are complete the moment you say them out loud.',
    zhRoast: '4% 的人拥有你这样的口才:减肥、学英语、开店,每一样都在饭桌上成功过。你讲得太好了,好到自己都以为已经做了。别人拖延是不动,你拖延是——说得更详细一点。',
    enRoast: 'Only 4% have your gift: the diet, the language course, the business — all succeeded at the dinner table. You tell it so well you believe it is done. Others procrastinate by not moving; you procrastinate by explaining in more detail.',
    zhTip: '下一个计划,先做三天再讲。',
    enTip: 'Do the next plan for three days before you mention it.',
    rarityPct: 4,
    profile: 'MHMMMHMMHMMMMMM',
  ),
  SbtiType(
    code: 'DDL',
    zhName: '死线战神',
    enName: 'Deadline Warrior',
    zhTagline: '截止日期不是压力,是燃料。',
    enTagline: 'The deadline is not pressure. It is fuel.',
    zhRoast: '6% 的人和你一样,前二十九天在想,最后一天在飞。你不是没能力,你是没到时候。交上去的东西居然还不错,这才是最气人的——你都快把"临时抱佛脚"练成正规武术了。',
    enRoast: 'Like 6% of people, you spend twenty-nine days thinking and the last one flying. It is not a lack of ability; it is a lack of deadline. The infuriating part is the work turns out fine — you have turned last-minute panic into a martial art.',
    zhTip: '把截止日期往前挪三天,骗自己一次。',
    enTip: 'Move every deadline three days earlier. Lie to yourself once.',
    rarityPct: 6,
    profile: 'MHMMLMHMMMMMMMM',
  ),
  SbtiType(
    code: 'CALC',
    zhName: '人间计算器',
    enName: 'The Calculator',
    zhTagline: '你不是抠,你是精确。',
    enTagline: 'You are not cheap. You are precise.',
    zhRoast: '3% 的人能像你这样,AA 的时候算到小数点后两位。凑单、比价、返现,你的购物车是一份财务报表。感情上也一样——投入产出比不对,你连暧昧都不开始。稳,是真的稳;冷,也是真的冷。',
    enRoast: 'Only 3% split a bill to two decimal places like you. Bundling, comparing, cashback — your cart is a balance sheet. Romance gets the same treatment: if the return on investment is off, the flirting never starts. Steady, genuinely. Cold, also genuinely.',
    zhTip: '有些账不用算,比如请朋友喝一杯。',
    enTip: 'Some things are not worth calculating. Like buying a friend a drink.',
    rarityPct: 3,
    profile: 'MMMMHMMMMHMMMML',
  ),
  SbtiType(
    code: 'CRY',
    zhName: '情绪币',
    enName: 'Volatile Coin',
    zhTagline: '一天之内涨停跌停各一次。',
    enTagline: 'Hits the ceiling and the floor in one trading day.',
    zhRoast: '5% 的人拥有你这样的行情。早上因为一杯咖啡幸福到发光,中午因为一个"哦"跌进谷底,晚上又因为一首歌满血复活。你不是脆弱,你是灵敏——只是灵敏到没有减震。',
    enRoast: 'Only 5% trade like you. Glowing at breakfast over a good coffee, bottoming out at noon over a one-word reply, fully recovered by evening thanks to a song. You are not fragile; you are sensitive — just with no suspension.',
    zhTip: '情绪来的时候,先等十分钟再做决定。',
    enTip: 'When the feeling hits, wait ten minutes before deciding anything.',
    rarityPct: 5,
    profile: 'MMMHLHMMMMMMMMM',
  ),
  SbtiType(
    code: 'STAB',
    zhName: '稳得可疑',
    enName: 'Suspiciously Stable',
    zhTagline: '你没有情绪,你只有状态。',
    enTagline: 'You do not have moods. You have settings.',
    zhRoast: '3% 的人像你一样,手机掉水里都不换表情。朋友哭你递纸,朋友笑你点头。大家怀疑你有没有心,其实你只是把心放在了一个别人够不着的地方。稳是好事——但偶尔也可以让别人看见你在意。',
    enRoast: 'Only 3% keep a straight face while their phone sinks. Friends cry, you hand over tissues; friends laugh, you nod. People wonder if you have a heart. You do; you just keep it somewhere out of reach. Stability is a gift — but you are allowed to let people see you care.',
    zhTip: '下次高兴的时候,把嘴角抬高两毫米。',
    enTip: 'Next time you are happy, raise the corners of your mouth two millimetres.',
    rarityPct: 3,
    profile: 'MMMLHLMMMMMMMMM',
  ),
  SbtiType(
    code: 'LICK',
    zhName: '恋爱脑晚期',
    enName: 'Terminally Lovestruck',
    zhTagline: '对方说"在吗",你已经在选婚纱。',
    enTagline: 'They say "you there?" and you are choosing a wedding dress.',
    zhRoast: '4% 的人和你一样,把一句晚安听成一生承诺。钱可以不算,时间可以不要,朋友劝你的话左耳进右耳出。你不是傻,你是把全部的热情都押在了一个人身上——这份勇气值得敬佩,只是记得留一点给自己。',
    enRoast: 'Like 4% of people, you hear "goodnight" as a lifetime commitment. Money is irrelevant, time is free, and friends warnings go in one ear and out the other. You are not foolish; you have bet everything on one person. The courage is admirable — just keep a little for yourself.',
    zhTip: '每天留一小时,做一件和对方无关的事。',
    enTip: 'Keep one hour a day for something that has nothing to do with them.',
    rarityPct: 4,
    profile: 'MMMHMMMMMLMMMMH',
  ),
  SbtiType(
    code: 'HARD',
    zhName: '嘴硬心软',
    enName: 'Tough Talker',
    zhTagline: '嘴上"随便",心里已经写了三页。',
    enTagline: 'Out loud: "whatever." Inside: three pages.',
    zhRoast: '3% 的稀有款。你对喜欢的人最凶,对在意的事最装不在乎。吵架的时候能把对方气走,然后自己在房间里难过一整晚。全世界都以为你不需要哄,其实你只是没学会怎么开口。',
    enRoast: 'A 3% rarity. You are hardest on the people you like most and most dismissive of what you care about most. You can drive someone away in an argument, then spend the whole night miserable alone. Everyone assumes you need no comforting. You just never learned how to ask.',
    zhTip: '试着把"随便"换成"我其实想要"。',
    enTip: 'Try replacing "whatever" with "actually, I would like".',
    rarityPct: 3,
    profile: 'LMMHMMMMHMMMMMH',
  ),
  SbtiType(
    code: 'XUAN',
    zhName: '万事问水逆',
    enName: "Mercury's Victim",
    zhTagline: '你不是倒霉,你是水逆的忠实用户。',
    enTagline: 'You are not unlucky. You are a loyal Mercury retrograde subscriber.',
    zhRoast: '5% 的人和你一样,把手机壁纸换成转运图。考试、面试、表白之前都要看一眼运势;运势不好就改天,改天运势还不好就再改天。你最厉害的地方是——总能找到一个天象来解释今天为什么不努力。',
    enRoast: 'Like 5% of people, your phone wallpaper is a good-luck charm. Every exam, interview and confession waits for a horoscope check; bad omen means postpone, and postpone again. Your true talent is always finding a celestial reason for not trying today.',
    zhTip: '运势是参考,不是请假条。',
    enTip: 'A horoscope is a reference, not a sick note.',
    rarityPct: 5,
    profile: 'MMMMLMMHMMHMMMM',
  ),
  SbtiType(
    code: 'BROKE',
    zhName: '月光侠',
    enName: 'Broke Hero',
    zhTagline: '钱只是数字,而你的数字是零。',
    enTagline: 'Money is just a number, and yours is zero.',
    zhRoast: '7% 的人像你一样,发工资那天是全年最富的一天。看中就买,买了就忘,忘了再买一个。你对生活的热情是真的,只是每样热情都要花钱。好在你活得开心——账单不开心而已。',
    enRoast: 'Like 7% of people, payday is the richest day of your year. See it, buy it, forget it, buy another. Your enthusiasm for life is real; it just all costs money. The upside is you are happy. The bills are not.',
    zhTip: '买之前放购物车三天,一半会消失。',
    enTip: 'Leave it in the cart for three days. Half of it will vanish.',
    rarityPct: 7,
    profile: 'MMHMMMMMMLHMMMM',
  ),
  SbtiType(
    code: 'CEO',
    zhName: '精神股东',
    enName: 'Armchair CEO',
    zhTagline: '公司不听你的,是公司的损失。',
    enTagline: "The company's loss for not listening to you.",
    zhRoast: '2% 的顶级稀有。你没有股份,但有意见;没有决策权,但有方案。看球你是教练,看剧你是编剧,看新闻你是总理。你的战略眼光可能是真的——只是从没人给你机会试,而你也没主动要过。',
    enRoast: 'A top-tier 2% rarity. No shares, but plenty of opinions; no authority, but a full plan. Watching sport you are the coach; watching drama you are the writer; watching news you run the country. Your strategic eye may well be real — nobody has offered you the chance, and you have never asked.',
    zhTip: '把"要是我来管"改成"我可以试试"。',
    enTip: 'Turn "if I were in charge" into "let me try".',
    rarityPct: 2,
    profile: 'MMMMMMMMHHMHMMM',
  ),
  SbtiType(
    code: 'NINJA',
    zhName: '忍者神龟',
    enName: 'The Endurer',
    zhTagline: '你什么都能忍,除了别人问你"还好吗"。',
    enTagline: 'You can endure anything except being asked "are you okay?"',
    zhRoast: '3% 的人像你一样,把委屈全部吞进去,面上一点不显。不争、不吵、不解释,吃亏了也说"没事"。大家都觉得你好相处,只有你知道那是憋出来的。忍是本事,但你已经忍到快内伤了。',
    enRoast: 'Like 3% of people, you swallow every grievance without a flicker. No fighting, no arguing, no explaining; shortchanged, you still say "it is fine". Everyone finds you easy to get along with. Only you know it is held in. Endurance is a skill — but you are at internal-bleeding levels.',
    zhTip: '这周挑一件小事,说一次"我不太舒服"。',
    enTip: 'Pick one small thing this week and say "I am not okay with this".',
    rarityPct: 3,
    profile: 'LMMMHMMMLMMMLMM',
  ),
  SbtiType(
    code: 'BUDDHA',
    zhName: '假佛系',
    enName: 'Faux Zen',
    zhTagline: '一切随缘,但缘分最好现在就来。',
    enTagline: 'Everything happens for a reason — preferably right now.',
    zhRoast: '4% 的人和你一样,嘴上"都行、随便、看缘分",心里已经排好了三套剧本。你信水逆也信努力,信随缘也信抢先。别人以为你无欲无求,其实你只是把"求"藏得比较艺术。',
    enRoast: 'Like 4% of people, you say "anything, whatever, fate will tell" while holding three finished scripts inside. You believe in Mercury and in hard work, in fate and in getting there first. People think you want nothing; you just hide the wanting artfully.',
    zhTip: '想要就说想要,佛也不拦你。',
    enTip: 'If you want it, say so. Even the Buddha would not stop you.',
    rarityPct: 4,
    profile: 'MMHMMHMHMMMMMMM',
  ),
  SbtiType(
    code: 'BURN',
    zhName: '三分钟热度永动机',
    enName: 'The Spark',
    zhTagline: '你的热情从不熄灭,只是每次点燃的是新东西。',
    enTagline: 'Your passion never dies. It just picks a new target every time.',
    zhRoast: '6% 的人像你一样,爱好比朋友换得还勤。吉他、健身、日语、烘焙,每一样都买了全套装备,每一样都停在第三周。你不是没毅力,你是好奇心太旺盛——世界这么大,凭什么只学一样?',
    enRoast: 'Like 6% of people, you rotate hobbies faster than friends. Guitar, gym, Japanese, baking — full kit for each, all abandoned in week three. It is not a lack of grit; your curiosity is simply enormous. The world is huge; why learn only one thing?',
    zhTip: '下一个爱好,先别买装备。',
    enTip: 'For the next hobby, do not buy the gear first.',
    rarityPct: 6,
    profile: 'MLMMMMHMMMHMMMM',
  ),
  SbtiType(
    code: 'ACT',
    zhName: '人生演技派',
    enName: 'Method Actor',
    zhTagline: '你的人生没有观众,但你从没停过演。',
    enTagline: 'No audience, but the performance never stops.',
    zhRoast: '3% 的人拥有你这样的表演天赋。被夸的时候"没有没有",被批评的时候"我早知道",难过的时候发一条"没事"然后等人来问。你活得太有镜头感了——只是别忘了,谢幕以后也得有个人陪你卸妆。',
    enRoast: 'Only 3% have your acting range. Praised: "oh, not at all". Criticised: "I already knew". Sad: post "I am fine" and wait to be asked. You live camera-ready — just remember someone has to help you take the makeup off after the curtain.',
    zhTip: '今天找一个人,说一句不演的话。',
    enTip: 'Today, find one person and say one unscripted thing.',
    rarityPct: 3,
    profile: 'HMMMMHMMHMMMMMM',
  ),
  SbtiType(
    code: 'SUS',
    zhName: '怂但不认',
    enName: 'Denial Mode',
    zhTagline: '你不是怂,你是"战略性回避"。',
    enTagline: 'You are not scared. You are "strategically avoiding".',
    zhRoast: '4% 的人像你一样,心里怕得要死,嘴上一句不服。不敢开口的事情说成"没必要",不敢去的场合说成"没意思"。你保护自己的方式是把所有"不敢"翻译成"不屑"——翻译得挺好,就是骗不过自己。',
    enRoast: 'Like 4% of people, you are terrified inside and defiant out loud. What you dare not say becomes "no need"; where you dare not go becomes "boring". Your defence is translating every "I am scared" into "I am above it". Good translation. You are still not fooled.',
    zhTip: '把一件"没必要"的事,试一次。',
    enTip: 'Try one thing you have filed under "no need".',
    rarityPct: 4,
    profile: 'MMMHMMLMHMMMLMM',
  ),
  SbtiType(
    code: 'GOD',
    zhName: '自信过头',
    enName: 'God Mode',
    zhTagline: '世界上只有两种人:你,和还没认识你的人。',
    enTagline: 'There are two kinds of people: you, and those who have not met you yet.',
    zhRoast: '2% 的顶级稀有。照镜子会被自己迷住,被批评会觉得对方没眼光,输了是裁判的问题。你的自信是真的能量,走到哪都发光——只是偶尔也照照别人,他们也想被看见。',
    enRoast: 'A top-tier 2% rarity. Mirrors are mesmerising, critics lack taste, and losses are the referee\'s fault. Your confidence is real energy and it lights every room — just aim it at other people now and then; they want to be seen too.',
    zhTip: '今天夸一个人,而且是真心的。',
    enTip: 'Compliment someone today. Mean it.',
    rarityPct: 2,
    profile: 'HMMLMMMMHMMMMMM',
  ),
  SbtiType(
    code: 'NPC',
    zhName: '路人甲',
    enName: 'Background NPC',
    zhTagline: '你哪都不极端,这本身就很极端。',
    enTagline: 'You are extreme at nothing, which is itself extreme.',
    zhRoast: '10% 的人和你一样,每个维度都刚刚好。不卷不躺、不疯不木、不抠不散。别人测出来是"稀有款",你测出来是"标准件"——这不是无聊,这是全场唯一一个还没被生活逼出怪癖的人。珍惜。',
    enRoast: 'Like 10% of people, you land in the middle on every single scale. Neither grinding nor horizontal, neither wild nor wooden, neither stingy nor loose. Others test as "rare editions"; you test as "reference model". That is not dull — you are the one person life has not yet warped into a quirk. Treasure it.',
    zhTip: '挑一个维度,故意过分一次。',
    enTip: 'Pick one scale and overdo it on purpose, once.',
    rarityPct: 10,
    profile: 'MMMMMMMMMMMMMMM',
  ),
];

// ---------------------------------------------------------------- 评分

SbtiTier _tierOf(int score) => score <= 3 ? SbtiTier.low : (score >= 5 ? SbtiTier.high : SbtiTier.mid);

/// [answers] 是 30 个选项下标(0–2),顺序同 [sbtiQuestions]。
SbtiResult sbtiEvaluate(List<int> answers) {
  if (answers.length != sbtiQuestions.length) {
    throw ArgumentError('需要 ${sbtiQuestions.length} 个答案,收到 ${answers.length}');
  }
  final scores = List<int>.filled(sbtiDimensions.length, 0);
  for (var i = 0; i < answers.length; i++) {
    final q = sbtiQuestions[i];
    final a = answers[i];
    if (a < 0 || a >= q.options.length) throw ArgumentError('第 ${i + 1} 题选项下标越界:$a');
    scores[q.dim] += q.options[a].score;
  }
  final tiers = scores.map(_tierOf).toList();

  // 先总差最小,再完全命中最多,再靠前者胜(模板顺序即优先级)
  SbtiType? best;
  var bestDiff = 1 << 30;
  var bestExact = -1;
  for (final t in sbtiTypes) {
    final p = t.profile;
    var diff = 0;
    var exact = 0;
    for (var d = 0; d < tiers.length; d++) {
      final delta = (tiers[d].index - p[d].index).abs();
      diff += delta;
      if (delta == 0) exact++;
    }
    if (diff < bestDiff || (diff == bestDiff && exact > bestExact)) {
      best = t;
      bestDiff = diff;
      bestExact = exact;
    }
  }
  return SbtiResult(type: best!, scores: scores, tiers: tiers, totalDiff: bestDiff, exactMatches: bestExact);
}

// ---------------------------------------------------------------- 命理彩蛋

/// 把日主五行和玩梗类型扯到一起的一句话。纯娱乐,不做任何命理推断。
String sbtiDayMasterLine(Element dayMaster, {required bool en}) => switch (dayMaster) {
      Element.wood => en
          ? 'Day Master Wood: you grow toward the light — which explains why this type keeps reaching for the next thing.'
          : '日主属木:向着光长,难怪这个类型总在够下一样东西。',
      Element.fire => en
          ? 'Day Master Fire: you burn bright and fast — this type is basically what happens when the flame has no lid.'
          : '日主属火:烧得亮也烧得快,这个类型就是火没盖子的样子。',
      Element.earth => en
          ? 'Day Master Earth: steady, heavy, hard to move — this type is you refusing to be moved, professionally.'
          : '日主属土:稳、沉、推不动,这个类型就是你把"推不动"练成了专业。',
      Element.metal => en
          ? 'Day Master Metal: sharp edges and clear lines — this type is what those edges look like on a Tuesday.'
          : '日主属金:棱角分明,这个类型就是你的棱角在周二的样子。',
      Element.water => en
          ? 'Day Master Water: takes the shape of whatever holds it — this type is the container you picked this week.'
          : '日主属水:装在什么容器里就是什么形状,这个类型就是你这周挑的容器。',
    };

/// 分享用的纯文本。
String sbtiShareText(SbtiResult r, {required bool en}) {
  final t = r.type;
  return en
      ? 'My SBTI type: ${t.code} · ${t.enName} (rarity ${t.rarityPct}%)\n"${t.enTagline}"\n— Mingli AI, the meme personality test'
      : '我的 SBTI 人格:${t.code} · ${t.zhName}(稀有度 ${t.rarityPct}%)\n「${t.zhTagline}」\n—— 命理师 AI 玩梗测试';
}
