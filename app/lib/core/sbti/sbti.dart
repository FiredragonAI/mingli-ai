/// SBTI 性格测试(Silly Big Type Indicator)。
///
/// 2026 年 4 月刷屏的那个"MBTI 过时了,SBTI 来了"的戏仿测试的同款玩法:
/// 15 道三选一,15 个维度,每维一题;选项分值 1/2/3 就是低/中/高三档,
/// 再和一组人格模板比对——先看总差最小,再看完全命中的维度最多。
///
/// 类型不是"性格形容词",而是**一种人**:吃瓜群众、乐子人、内耗人、显眼包、杠精……
/// 网友能对号入座、能截图发"我是 XX"的那种身份标签。代码带梗带标点(NOPE!、OK-R)。
/// 题目、维度、类型和文案都是本项目原创,只借了原版的玩法和自嘲的味道,
/// 原版的类型名与插画一个都不用。
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
    required this.emoji,
    required this.lottieCode,
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

  /// 结果页的动画表情:glyph 是兜底显示的字符,lottieCode 对应 assets/emoji/<code>.json
  /// (Noto Animated Emoji,CC BY 4.0)。动画文件缺失时退回显示 glyph。
  final String emoji;
  final String lottieCode;

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

  /// 每维 1–3 分。
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

/// 15 题,每维一题;顺序故意把五个板块打散,连着答不容易看出在测什么。
const List<SbtiQuestion> sbtiQuestions = [
  SbtiQuestion(0, '朋友发来一张合照,你第一眼看的是:', 'A friend sends a group photo. The first thing you look at:', [
    SbtiOption('自己,嗯,今天状态不错', 'Yourself. Looking good today', 3),
    SbtiOption('整体,大家都挺好', 'The whole picture; everyone looks fine', 2),
    SbtiOption('自己,怎么又是最垮的那个', 'Yourself. Why are you the worst one again', 1),
  ]),
  SbtiQuestion(3, '发了条动态,一个熟人给别人点赞了,没给你:', "You post something. A friend likes someone else's post but not yours:", [
    SbtiOption('记住了,记一辈子', 'Noted. Forever', 3),
    SbtiOption('有点在意,过一会儿就忘了', 'A little stung, forgotten in an hour', 2),
    SbtiOption('压根没注意', 'Did not even notice', 1),
  ]),
  SbtiQuestion(6, '假期第一天早上,你:', 'First morning of a holiday. You:', [
    SbtiOption('已经报了一门课', 'Have already signed up for a course', 3),
    SbtiOption('列了个"假期计划",然后看着它', 'Wrote a "holiday plan" and are now looking at it', 2),
    SbtiOption('睡到自然醒,醒了继续躺', 'Sleep in, then keep lying there', 1),
  ]),
  SbtiQuestion(9, '群里发了个红包,你抢到 0.02:', 'You grab a group red packet and get two cents:', [
    SbtiOption('难受一下午,并算了算谁抢得最多', 'Ruined afternoon; also calculated who got the most', 3),
    SbtiOption('笑一下,发个表情', 'Chuckle, send a sticker', 2),
    SbtiOption('抢了吗?我没点', 'Was there a packet? You did not tap', 1),
  ]),
  SbtiQuestion(12, '周五晚上,同事临时约你去 K 歌:', 'Friday night, coworkers spontaneously invite you to karaoke:', [
    SbtiOption('冲,今晚不醉不归', 'In. Tonight goes late', 3),
    SbtiOption('去一小时,唱一首就撤', 'One hour, one song, then out', 2),
    SbtiOption('"我有事"——我的事是回家躺着', '"I have plans" — the plan is lying on the couch', 1),
  ]),
  SbtiQuestion(1, '"明天开始"这四个字,你今年说过:', 'How many times this year have you said "starting tomorrow":', [
    SbtiOption('数不清,每周都说', 'Countless. Weekly', 3),
    SbtiOption('几次吧', 'A few', 2),
    SbtiOption('从不说,想到当天就开始', 'Never. If it is worth doing, it starts today', 1),
  ]),
  SbtiQuestion(4, '外卖迟到四十分钟,还撒了一半:', 'Delivery is forty minutes late and half spilled:', [
    SbtiOption('拍个照,默默吃剩下的', 'Take a photo, quietly eat the rest', 3),
    SbtiOption('深呼吸,给个差评', 'Deep breath, one-star review', 2),
    SbtiOption('当场炸了', 'Detonate on the spot', 1),
  ]),
  SbtiQuestion(7, '新手机到了,你先:', 'Your new phone arrives. First you:', [
    SbtiOption('挑个吉时再开机', 'Wait for an auspicious hour to power it on', 3),
    SbtiOption('先贴膜', 'Put the screen protector on', 2),
    SbtiOption('直接开', 'Turn it on immediately', 1),
  ]),
  SbtiQuestion(10, '你手机备忘录里"马上要学"的东西有:', 'Your "going to learn soon" list currently holds:', [
    SbtiOption('十几样,全停在第一课', 'A dozen things, all stuck at lesson one', 3),
    SbtiOption('两三样', 'Two or three', 2),
    SbtiOption('没有,正在学的这个学完再说', 'Nothing; finishing the current one first', 1),
  ]),
  SbtiQuestion(13, '你说"我快到了"的时候,实际上:', 'When you say "almost there", you are actually:', [
    SbtiOption('还没出门', 'Still at home', 3),
    SbtiOption('在路上', 'On the way', 2),
    SbtiOption('真的快到了', 'Actually almost there', 1),
  ]),
  SbtiQuestion(2, '领导发来一句"来我办公室一下":', 'Your boss messages "come to my office for a sec":', [
    SbtiOption('顺路买杯咖啡再过去', 'Grab a coffee on the way', 3),
    SbtiOption('边走边想是什么事', 'Walk over wondering what it is', 2),
    SbtiOption('慌了一路,把这周的事全过了一遍', 'Panic the whole walk, replaying the week', 1),
  ]),
  SbtiQuestion(5, '你感冒了,在群里:', 'You have a cold. In the group chat you:', [
    SbtiOption('发一句"我没事",然后等人来问', "Post \"I'm fine\" and wait to be asked", 3),
    SbtiOption('说一句"感冒了,今天不来了"', 'Say "got a cold, not coming today"', 2),
    SbtiOption('不说,谁问都说没事', 'Say nothing; tell anyone who asks it is nothing', 1),
  ]),
  SbtiQuestion(8, '导航说右转,你觉得应该左转:', 'The sat-nav says right, you think left:', [
    SbtiOption('左转,导航懂什么', 'Left. What does the sat-nav know', 3),
    SbtiOption('先看一眼地图', 'Check the map first', 2),
    SbtiOption('听导航的', 'Follow the sat-nav', 1),
  ]),
  SbtiQuestion(11, '公司出了个新政策,你:', 'Your company announces a new policy. You:', [
    SbtiOption('写了三百字分析发到群里', 'Post a 300-word analysis in the chat', 3),
    SbtiOption('吐槽一句', 'One line of complaint', 2),
    SbtiOption('关我什么事', 'Not your department', 1),
  ]),
  SbtiQuestion(14, '对方回消息慢了两个小时:', 'Your crush takes two hours to reply:', [
    SbtiOption('已经在脑补 TA 有别人了', 'Already imagining they met someone else', 3),
    SbtiOption('心里嘀咕了一下', 'A small inner grumble', 2),
    SbtiOption('我压根没注意时间', 'Did not notice the time', 1),
  ]),
];

// ---------------------------------------------------------------- 类型

/// 21 种人。模板按 [sbtiDimensions] 顺序,L/M/H 各一位;稀有度加起来正好 100。
const List<SbtiType> sbtiTypes = [
  SbtiType(
    code: 'MELON',
    emoji: '🍉',
    lottieCode: '1f349',
    zhName: '吃瓜群众',
    enName: 'Melon Muncher',
    zhTagline: '你不站队,你只搬凳子。',
    enTagline: 'You do not pick sides. You bring the chair.',
    zhRoast: '10% 的人和你一样,哪儿有热闹哪儿有你,但你从不下场。群里吵翻天,你只发一个"👀";朋友分手,你是第一个知道全过程的人。你不是没立场,你是觉得当观众性价比最高。',
    enRoast: 'Like 10% of people, you are wherever the drama is — and never in it. The group chat explodes and you post a single 👀. A friend breaks up and you are the first with the full timeline. It is not that you have no opinion; you just know the audience gets the best value.',
    zhTip: '下次挑一个瓜,亲自下场一次。',
    enTip: 'Next time, pick one drama and actually get involved.',
    rarityPct: 10,
    profile: 'MMMMMMMMMMMMMMM',
  ),
  SbtiType(
    code: 'LOL-R',
    emoji: '🍿',
    lottieCode: '1f37f',
    zhName: '乐子人',
    enName: 'Here For The Chaos',
    zhTagline: '天塌下来,你先笑一声。',
    enTagline: 'If the sky falls, you laugh first.',
    zhRoast: '6% 的人有你这种体质:什么事到你这儿都能变成段子。公司裁员你在想梗,朋友失恋你在想文案。别人觉得你没心没肺,其实你只是把"没办法"翻译成了"挺好笑"。',
    enRoast: 'Only 6% have your constitution: everything that reaches you becomes a joke. Layoffs at work and you are drafting the meme; a friend gets dumped and you are writing the caption. People think you are heartless. You have simply translated "nothing to be done" into "kind of funny".',
    zhTip: '有些事可以不好笑,你也可以不笑。',
    enTip: 'Some things are allowed to not be funny. You are allowed to not laugh.',
    rarityPct: 6,
    profile: 'MMHLMHMMMMMMMMM',
  ),
  SbtiType(
    code: 'LOOP',
    emoji: '🧠',
    lottieCode: '1f9e0',
    zhName: '内耗人',
    enName: 'The Overthinker',
    zhTagline: '别人一句话,你脑内三集连续剧。',
    enTagline: 'One sentence from them, a three-episode drama in your head.',
    zhRoast: '7% 的人和你一样,把"他刚才是不是不高兴"想成了论文。事情还没做就先累了,做完了又开始复盘。你不是效率低,你是同一件事在脑子里做了五遍。',
    enRoast: 'Like 7% of people, you have turned "was he annoyed just now?" into a dissertation. You are tired before you start and reviewing after you finish. It is not low productivity — you just did the same task five times in your head.',
    zhTip: '想第三遍的时候,直接去做。',
    enTip: 'The third time you think about it, just go do it.',
    rarityPct: 7,
    profile: 'MHMHLMMMMMMMMMM',
  ),
  SbtiType(
    code: 'LITE',
    emoji: '😐',
    lottieCode: '1f610',
    zhName: '淡人',
    enName: 'The Lite Version',
    zhTagline: '你的情绪是低糖版的。',
    enTagline: 'Your feelings ship in the low-sugar edition.',
    zhRoast: '6% 的人像你一样,高兴是"还行",难过是"还好",恋爱是"就那样"。朋友聚会你像在旁听,别人哭你递纸,别人笑你点头。不是你冷,是你所有情绪都自带 0.5 倍速。',
    enRoast: 'Like 6% of people, happy is "fine", sad is "okay", in love is "it is what it is". At parties you look like an auditor; friends cry and you pass tissues, friends laugh and you nod. You are not cold — all your emotions simply run at half speed.',
    zhTip: '这周挑一件事,反应过度一次。',
    enTip: 'Pick one thing this week and overreact to it.',
    rarityPct: 6,
    profile: 'MMMMHLMMMMMMLML',
  ),
  SbtiType(
    code: 'MAX',
    emoji: '🤩',
    lottieCode: '1f929',
    zhName: '浓人',
    enName: 'Extra Strength',
    zhTagline: '你不是来参加聚会的,你是聚会本身。',
    enTagline: 'You do not attend the party. You are the party.',
    zhRoast: '5% 的人有你这个浓度:开心要蹦、难过要哭、看到好吃的要拍二十张。你的朋友圈是别人的电视剧。别人觉得你累,其实你只是把每一天都过成了大结局。',
    enRoast: "Only 5% come at your concentration: happiness means jumping, sadness means crying, good food means twenty photos. Your feed is other people's TV. They think it must be exhausting; you just live every day like the season finale.",
    zhTip: '偶尔也让别人当一次主角。',
    enTip: 'Let someone else be the main character now and then.',
    rarityPct: 5,
    profile: 'MMMMMHMMMMHMHMM',
  ),
  SbtiType(
    code: 'SHOW-Y',
    emoji: '🦩',
    lottieCode: '1f9a9',
    zhName: '显眼包',
    enName: 'The Show-Off',
    zhTagline: '低调这个词,在你的字典里被删除了。',
    enTagline: '"Low-key" has been removed from your dictionary.',
    zhRoast: '4% 的人和你一样,进门自带背景音乐。合照永远在 C 位,群里永远第一个说话,连排队都能排出一种表演感。别人说你显眼,你听成了夸奖——好吧,也确实是。',
    enRoast: 'Like 4% of people, you enter rooms with your own soundtrack. Always centre of the group photo, always first to speak in the chat, somehow even queuing looks like a performance. People call you conspicuous; you hear a compliment. Fair enough — it is one.',
    zhTip: '今天让别人先说完。',
    enTip: 'Today, let someone else finish talking first.',
    rarityPct: 4,
    profile: 'HMMMMHMMMMMMHMM',
  ),
  SbtiType(
    code: 'JUAN',
    emoji: '🔥',
    lottieCode: '1f525',
    zhName: '卷王',
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
    code: 'LAN',
    emoji: '🥱',
    lottieCode: '1f971',
    zhName: '摆烂人',
    enName: 'The Rot',
    zhTagline: '既然做不好,那就不做了。',
    enTagline: 'If it cannot be done well, it will not be done.',
    zhRoast: '7% 的人像你一样,把"算了"练成了肌肉记忆。不是不会努力,是努力过一次发现没用,从此坚决不再上当。你的床是你的根据地,你的口头禅是"再说吧"。',
    enRoast: 'Like 7% of people, "never mind" has become muscle memory. You can try; you just tried once, it did not work, and you refuse to be fooled again. Your bed is your headquarters and "later" is your catchphrase.',
    zhTip: '烂归烂,今天先把一件小事做完。',
    enTip: 'Rot all you like — after finishing one small thing today.',
    rarityPct: 7,
    profile: 'MHHMMMLMMMMMMMM',
  ),
  SbtiType(
    code: 'NOPE!',
    emoji: '😤',
    lottieCode: '1f624',
    zhName: '杠精',
    enName: 'Professional Objector',
    zhTagline: '你不是在反驳,你是在呼吸。',
    enTagline: 'You are not arguing. You are breathing.',
    zhRoast: '4% 的人拥有你这种反射弧:别人说东你想西,别人说好你找茬。不是你故意的,是"但是"两个字已经长在了舌头上。你的观点可能是对的——只是没人听到那儿。',
    enRoast: 'Only 4% have your reflex: they say east, you think west; they say great, you find the flaw. It is not deliberate — "but" is simply grown onto your tongue. Your point might be right. Nobody ever gets that far.',
    zhTip: '下次先说"有道理",再说"但是"。',
    enTip: 'Next time say "fair point" before "but".',
    rarityPct: 4,
    profile: 'MMMLMMMMHMMHMMM',
  ),
  SbtiType(
    code: 'OK-R',
    emoji: '🙃',
    lottieCode: '1f643',
    zhName: '老好人',
    enName: 'The Yes-Person',
    zhTagline: '你说"都行",其实哪个都不行。',
    enTagline: 'You say "either is fine". Neither is.',
    zhRoast: '5% 的人和你一样,把"不好意思拒绝"活成了人生主线。帮同事干活,替朋友背锅,聚会选了你最不想吃的那家。大家都说你好相处,只有你知道那是憋出来的。',
    enRoast: "Like 5% of people, \"too awkward to say no\" is your main plot. You do coworkers' work, take the blame for friends, and eat at the one restaurant you hate. Everyone says you are easy to get along with. Only you know it is held in.",
    zhTip: '这周说一次"不行"。就一次。',
    enTip: 'Say "no" once this week. Just once.',
    rarityPct: 5,
    profile: 'MMMHMMMMLMMMMLM',
  ),
  SbtiType(
    code: 'DDL',
    emoji: '⏰',
    lottieCode: '23f0',
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
    code: 'ZZZ',
    emoji: '😴',
    lottieCode: '1f634',
    zhName: '装睡人',
    enName: 'Cannot Be Woken',
    zhTagline: '你不是叫不醒,你是不想醒。',
    enTagline: 'It is not that you cannot be woken. You would rather not.',
    zhRoast: '4% 的人和你一样,把"没看到""没听见""再说吧"练成了组合技。群里 @ 你,你等它沉下去;朋友劝你,你说"你说得对"然后照旧。你不是懒,你是主动选择了不参与这个世界。',
    enRoast: "Like 4% of people, \"didn't see it\", \"didn't hear\", and \"later\" are your signature combo. Tagged in the chat, you wait for it to scroll away; a friend gives advice, you say \"you're right\" and change nothing. Not lazy — you have simply opted out of the world.",
    zhTip: '今天回一条你一直装没看见的消息。',
    enTip: 'Reply to one message you have been pretending not to see.',
    rarityPct: 4,
    profile: 'MMHMMMLMHMMMLMM',
  ),
  SbtiType(
    code: 'SIMP',
    emoji: '😍',
    lottieCode: '1f60d',
    zhName: '恋爱脑',
    enName: 'The Simp',
    zhTagline: '对方说"在吗",你已经在选婚纱。',
    enTagline: 'They say "you there?" and you are choosing a wedding dress.',
    zhRoast: '4% 的人和你一样,把一句晚安听成一生承诺。钱可以不算,时间可以不要,朋友劝你的话左耳进右耳出。你不是傻,你是把全部的热情都押在了一个人身上——这份勇气值得敬佩,只是记得留一点给自己。',
    enRoast: "Like 4% of people, you hear \"goodnight\" as a lifetime commitment. Money is irrelevant, time is free, and friends' warnings go in one ear and out the other. You are not foolish; you have bet everything on one person. The courage is admirable — just keep a little for yourself.",
    zhTip: '每天留一小时,做一件和对方无关的事。',
    enTip: 'Keep one hour a day for something that has nothing to do with them.',
    rarityPct: 4,
    profile: 'MMMHMMMMMLMMMMH',
  ),
  SbtiType(
    code: 'CEO',
    emoji: '🧐',
    lottieCode: '1f9d0',
    zhName: '精神股东',
    enName: 'Armchair CEO',
    zhTagline: '公司不听你的,是公司的损失。',
    enTagline: "The company's loss for not listening to you.",
    zhRoast: '3% 的顶级稀有。你没有股份,但有意见;没有决策权,但有方案。看球你是教练,看剧你是编剧,看新闻你是总理。你的战略眼光可能是真的——只是从没人给你机会试,而你也没主动要过。',
    enRoast: 'A top-tier 3% rarity. No shares, but plenty of opinions; no authority, but a full plan. Watching sport you are the coach; watching drama you are the writer; watching news you run the country. Your strategic eye may well be real — nobody has offered you the chance, and you have never asked.',
    zhTip: '把"要是我来管"改成"我可以试试"。',
    enTip: 'Turn "if I were in charge" into "let me try".',
    rarityPct: 3,
    profile: 'MMMMMMMMHHMHMMM',
  ),
  SbtiType(
    code: 'ZERO',
    emoji: '💸',
    lottieCode: '1f4b8',
    zhName: '月光侠',
    enName: 'Paycheck Zero',
    zhTagline: '钱只是数字,而你的数字是零。',
    enTagline: 'Money is just a number, and yours is zero.',
    zhRoast: '6% 的人像你一样,发工资那天是全年最富的一天。看中就买,买了就忘,忘了再买一个。你对生活的热情是真的,只是每样热情都要花钱。好在你活得开心——账单不开心而已。',
    enRoast: 'Like 6% of people, payday is the richest day of your year. See it, buy it, forget it, buy another. Your enthusiasm for life is real; it just all costs money. The upside is you are happy. The bills are not.',
    zhTip: '买之前放购物车三天,一半会消失。',
    enTip: 'Leave it in the cart for three days. Half of it will vanish.',
    rarityPct: 6,
    profile: 'MMHMMMMMMLHMMMM',
  ),
  SbtiType(
    code: 'XUAN',
    emoji: '🔮',
    lottieCode: '1f52e',
    zhName: '玄学人',
    enName: "Mercury's Victim",
    zhTagline: '你不是倒霉,你是水逆的忠实用户。',
    enTagline: 'You are not unlucky. You are a loyal Mercury retrograde subscriber.',
    zhRoast: '4% 的人和你一样,把手机壁纸换成转运图。考试、面试、表白之前都要看一眼运势;运势不好就改天,改天运势还不好就再改天。你最厉害的地方是——总能找到一个天象来解释今天为什么不努力。',
    enRoast: 'Like 4% of people, your phone wallpaper is a good-luck charm. Every exam, interview and confession waits for a horoscope check; bad omen means postpone, and postpone again. Your true talent is always finding a celestial reason for not trying today.',
    zhTip: '运势是参考,不是请假条。',
    enTip: 'A horoscope is a reference, not a sick note.',
    rarityPct: 4,
    profile: 'MMMMLMMHMMHMMMM',
  ),
  SbtiType(
    code: 'MUYU',
    emoji: '🙏',
    lottieCode: '1f64f',
    zhName: '电子佛',
    enName: 'Cyber Buddha',
    zhTagline: '一切随缘,但功德最好现在就到账。',
    enTagline: 'Everything is fate — preferably credited to your account now.',
    zhRoast: '3% 的人和你一样,嘴上"都行、随便、看缘分",手机里敲了三万下电子木鱼。你信水逆也信努力,信随缘也信抢先。别人以为你无欲无求,其实你只是把"求"藏得比较艺术。',
    enRoast: 'Like 3% of people, you say "anything, whatever, fate will tell" while tapping a digital wooden fish thirty thousand times. You believe in Mercury and in hard work, in fate and in getting there first. People think you want nothing; you just hide the wanting artfully.',
    zhTip: '想要就说想要,佛也不拦你。',
    enTip: 'If you want it, say so. Even the Buddha would not stop you.',
    rarityPct: 3,
    profile: 'MMHMMHMHMMMMMMM',
  ),
  SbtiType(
    code: 'ECHO',
    emoji: '🗣',
    lottieCode: '1f5e3',
    zhName: '复读机',
    enName: 'The Echo',
    zhTagline: '你没有观点,但你有 +1。',
    enTagline: 'You have no opinion, but you have "+1".',
    zhRoast: '3% 的人和你一样,群里永远是第二个说话的人,内容永远是"同意""确实""哈哈哈哈"。不是你没想法,是你觉得别人说得都挺对。你是每个群的气氛担当——只是没人记得你说过什么。',
    enRoast: "Like 3% of people, you are always the second to speak in the chat, and it is always \"agreed\", \"true\", or \"hahaha\". It is not that you have no thoughts; everyone else just seems right. You are every group's vibe keeper — nobody remembers a thing you said.",
    zhTip: '下次说"同意"之前,先说一句自己的。',
    enTip: 'Before the next "agreed", say one sentence of your own.',
    rarityPct: 3,
    profile: 'MMMMMMMMLMMLHMM',
  ),
  SbtiType(
    code: 'GHOST',
    emoji: '👻',
    lottieCode: '1f47b',
    zhName: '已读不回人',
    enName: 'Left On Read',
    zhTagline: '你看到了,你只是选择了沉默。',
    enTagline: 'You saw it. You simply chose silence.',
    zhRoast: '3% 的稀有物种。消息你都看了,回不回看心情;约你都答应了,去不去看天气。朋友以为你忙,其实你在刷手机。你不是不在乎,你是回复这件事本身太累了。',
    enRoast: 'A 3% rarity. You read every message; replying depends on mood. You accept every invite; showing up depends on weather. Friends assume you are busy; you are scrolling. It is not that you do not care — replying itself is just exhausting.',
    zhTip: '今天把一条"稍后回"真的回了。',
    enTip: 'Actually reply to one "later" message today.',
    rarityPct: 3,
    profile: 'MMMMHMMMMMMMLHM',
  ),
  SbtiType(
    code: 'GOD',
    emoji: '😎',
    lottieCode: '1f60e',
    zhName: '自信过头',
    enName: 'God Mode',
    zhTagline: '世界上只有两种人:你,和还没认识你的人。',
    enTagline: 'There are two kinds of people: you, and those who have not met you yet.',
    zhRoast: '2% 的顶级稀有。照镜子会被自己迷住,被批评会觉得对方没眼光,输了是裁判的问题。你的自信是真的能量,走到哪都发光——只是偶尔也照照别人,他们也想被看见。',
    enRoast: "A top-tier 2% rarity. Mirrors are mesmerising, critics lack taste, and losses are the referee's fault. Your confidence is real energy and it lights every room — just aim it at other people now and then; they want to be seen too.",
    zhTip: '今天夸一个人,而且是真心的。',
    enTip: 'Compliment someone today. Mean it.',
    rarityPct: 2,
    profile: 'HMMLMMMMHMMMMMM',
  ),
  SbtiType(
    code: 'IRON',
    emoji: '🤑',
    lottieCode: '1f911',
    zhName: '铁公鸡',
    enName: 'The Tightwad',
    zhTagline: '你不是抠,你是有原则地不花钱。',
    enTagline: 'You are not cheap. You have principles about not spending.',
    zhRoast: '2% 的顶级稀有。AA 算到小数点后两位,红包抢到几分都记得,凑单比价是你的日常修行。感情上也一样——投入产出比不对,连暧昧都不开始。你的账永远是清的,只是朋友有时候会觉得自己也被算进去了。',
    enRoast: 'A top-tier 2% rarity. You split bills to two decimal places, remember every red-packet cent, and price-comparing is your daily practice. Romance gets the same treatment: wrong return on investment, no flirting. Your books always balance — friends just sometimes feel like a line item.',
    zhTip: '有些账不用算,比如请朋友喝一杯。',
    enTip: 'Some things are not worth calculating. Like buying a friend a drink.',
    rarityPct: 2,
    profile: 'MMMMHMMMMHMMMML',
  ),
];

// ---------------------------------------------------------------- 评分

SbtiTier _tierOf(int score) => score <= 1 ? SbtiTier.low : (score >= 3 ? SbtiTier.high : SbtiTier.mid);

/// [answers] 是 15 个选项下标(0–2),顺序同 [sbtiQuestions]。
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

/// 把日主五行和类型扯到一起的一句话。纯娱乐,不做任何命理推断。
String sbtiDayMasterLine(Element dayMaster, {required bool en}) => switch (dayMaster) {
      Element.wood => en
          ? 'Day Master Wood: you grow toward the light — which explains why this type keeps reaching for the next thing.'
          : '日主属木:向着光长,难怪这种人总在够下一样东西。',
      Element.fire => en
          ? 'Day Master Fire: you burn bright and fast — this type is basically what happens when the flame has no lid.'
          : '日主属火:烧得亮也烧得快,这种人就是火没盖子的样子。',
      Element.earth => en
          ? 'Day Master Earth: steady, heavy, hard to move — this type is you refusing to be moved, professionally.'
          : '日主属土:稳、沉、推不动,这种人就是把"推不动"练成了专业。',
      Element.metal => en
          ? 'Day Master Metal: sharp edges and clear lines — this type is what those edges look like on a Tuesday.'
          : '日主属金:棱角分明,这种人就是你的棱角在周二的样子。',
      Element.water => en
          ? 'Day Master Water: takes the shape of whatever holds it — this type is the container you picked this week.'
          : '日主属水:装在什么容器里就是什么形状,这种人就是你这周挑的容器。',
    };

/// 分享用的纯文本。
String sbtiShareText(SbtiResult r, {required bool en}) {
  final t = r.type;
  return en
      ? 'My SBTI type: ${t.code} · ${t.enName} (rarity ${t.rarityPct}%)\n"${t.enTagline}"\n— Mingli AI, SBTI Personality Test'
      : '我是 SBTI 里的「${t.zhName}」${t.code}(稀有度 ${t.rarityPct}%)\n「${t.zhTagline}」\n—— 命理师 AI · SBTI 性格测试';
}
