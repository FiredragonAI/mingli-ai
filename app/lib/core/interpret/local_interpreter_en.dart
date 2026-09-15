/// Offline local readings in English.
///
/// Mirrors `local_interpreter.dart`. The engines emit their evidence strings in
/// Chinese (that is the language of the source literature and makes the numbers
/// easy to audit), so the English reading is composed from the **structured**
/// data — enums, scores, percentages — with a short "Notes (中文)" block at the
/// end that keeps the raw evidence available for anyone who reads Chinese.
library;

import '../almanac/almanac.dart';
import '../bazi/bazi_chart.dart';
import '../bazi/element_strength.dart';
import '../bazi/five_elements.dart';
import '../bazi/hidden_stems.dart';
import '../bazi/shen_sha.dart';
import '../bazi/ten_gods.dart';
import '../calendar/sexagenary.dart';
import '../fortune/annual_fortune.dart';
import '../fortune/daily_fortune.dart';
import '../marriage/marriage.dart';
import '../naming/name_analysis.dart';
import '../naming/numerology.dart';
import '../vision/face_features.dart';
import '../vision/palm_features.dart';
import '../zodiac/western_zodiac.dart';
import '../../l10n/glossary.dart';

const _footer =
    '\n\n---\n*Generated on this device by a rule engine — no cloud service involved. Chinese metaphysics is one traditional lens on character and rhythm; for entertainment only.*';

String _h(String t) => '## $t\n';
String _q(String s) => '> $s\n';
String _t(String zh) => termEnglish[zh] ?? zh;
String _el(Element e) => _t(e.label);

// ------------------------------------------------------------------ persona tables

class _Persona {
  const _Persona(this.image, this.traits, this.plain, this.fun, this.tip);
  final String image;
  final String traits;
  final String plain;
  final String fun;
  final String tip;
}

const List<_Persona> _stemPersona = [
  _Persona('a towering tree', 'upright, dependable, does not back down',
      'Once you commit you see it through — the load-bearing type.',
      'Like the old tree at the gate: the wind never moves it and everyone stands in its shade in summer.',
      'Tall trees catch the wind; bending a little now and then is not losing.'),
  _Persona('vines and grasses', 'flexible, adaptive, good at borrowing strength',
      'Soft-looking but remarkably tough; you grow wherever there is something to lean on.',
      'The vine climbs whatever wall is there — and it is usually the vine that flowers at the top.',
      'Borrowing strength is a skill; keep a trunk of your own too.'),
  _Persona('the sun', 'warm, outgoing, lights others up',
      'You carry your own spotlight — generous, frank, unable to hide much.',
      'The friend who is still organising the next dinner before this one is over.',
      'Even the sun sets; keep some time alone to recharge.'),
  _Persona('a lamp flame', 'delicate, focused, warms a corner',
      'Not a scene-stealer, but the one who looks after people down to the details.',
      'The person who leaves a light on for you at night without saying so.',
      'Do not burn yourself out; look after yourself before you light up others.'),
  _Persona('a mountain', 'steady, accommodating, slow to change',
      'Reliable and emotionally stable; you keep the people and things you choose for the long haul.',
      'Friends ask you first when they need a loan — not because you are rich, but because you are steady.',
      'Not moving is a virtue; refusing to move is not.'),
  _Persona('fertile farmland', 'attentive, practical, nourishing',
      'You know how to run a life and quietly give to others; unshowy, but things fall apart without you.',
      'Fridge always stocked, plasters always in the drawer.',
      'Keep a field for yourself while you tend everyone else\'s.'),
  _Persona('a sword', 'resolute, decisive, loyal',
      'Straight talk, quick action, no tolerance for unfairness; all-in for friends.',
      'First in the group chat to say "decided, let\'s go" — and then actually go.',
      'A sharp blade cuts; ask a question before you deliver the verdict.'),
  _Persona('a jewel', 'refined, sensitive, quality-minded',
      'Soft outside, hard inside, a touch of perfectionism; a natural pull towards beauty and order.',
      'Spots the loose thread on someone\'s jacket at ten paces; checks the mirror three times before leaving.',
      'Jade needs polishing to shine — but not every criticism is a scratch.'),
  _Persona('a river', 'wise, expansive, freedom-loving',
      'Quick mind, many ideas, widely read; allergic to boxes and rules.',
      'The one who says "actually there is a third option" halfway through the meeting.',
      'Water carries boats but needs banks — set yourself a few boundaries.'),
  _Persona('dew and rain', 'perceptive, reserved, quietly influential',
      'Quiet, but you see everything; you influence people without raising your voice.',
      'Says little, yet knows everyone\'s secrets — and keeps them.',
      'Ideas kept too deep never reach anyone; say it plainly sometimes.'),
];

// ------------------------------------------------------------------ voice (headline / quote / do / don't)

T _pick<T>(List<T> pool, int seed) => pool[seed.abs() % pool.length];
int _seed(BaziChart c) => c.dayPillar.stemBranch.index * 7 + c.monthPillar.stemBranch.index;

String _baziHeadlineEn(BaziChart c) {
  final img = _stemPersona[c.dayStem].image;
  final st = c.elements.strength;
  final pool = st.isStrongSide
      ? ['$img — plenty of power; the homework is where to aim it', 'You\'re the "I\'ll do it" person, and it\'s usually done', 'Strong isn\'t the same as "only able to carry"']
      : st.isWeakSide
          ? ['Not the tallest $img, but you know where the light is', 'Your talent isn\'t pushing through — it\'s finding the socket', 'Soft on the outside, the best at bending on the inside']
          : ['$img, just right — the hard part is staying just right', 'A balanced chart, most at risk of finding itself boring'];
  return _pick(pool, _seed(c));
}

String _dailyHeadlineEn(BaziChart c, DailyFortune f) {
  final seed = _seed(c) + f.dayPillar.index;
  final good = f.overall >= 70, low = f.overall < 50;
  final pool = switch (f.theme.group) {
    '财星' => good ? ['Your wallet has a feeling today', 'A day to negotiate'] : low ? ['Guard the wallet, let the rest go', 'Wealth day — don\'t get greedy'] : ['A day for real numbers'],
    '官杀' => good ? ['Reliable pays today', 'The boss will call — pick up'] : low ? ['Don\'t talk back today', 'Rules day — stay inside the lines'] : ['Responsibility day, follow the process'],
    '印星' => good ? ['Someone wants to teach you today', 'Charging day — find the socket'] : low ? ['A day for reading, not deciding', 'Rest day — don\'t push'] : ['A quiet day to learn'],
    '食伤' => good ? ['Your brain is fizzing today', 'Say the idea out loud'] : low ? ['Fast mouth, slow down', 'Ideas ≠ promises today'] : ['Expression day — be clear'],
    _ => good ? ['Team-up day', 'Friends day — don\'t grab the bill'] : low ? ['Don\'t lend to friends today', 'Crowds: fewer is better'] : ['People in, people out'],
  };
  return _pick(pool, seed);
}

String _dailyQuoteEn(BaziChart c, DailyFortune f) {
  final seed = _seed(c) + f.dayPillar.index * 3;
  final pool = switch (f.theme.group) {
    '财星' => ['Money comes: don\'t rush to spend. Money goes: don\'t rush to chase.', 'The most valuable word today is "specific".'],
    '官杀' => ['Don\'t prove yourself today — finishing the job is the proof.', 'Pressure is theirs; the pace is yours.'],
    '印星' => ['Listen to the end before you speak.', 'One question to a mentor beats an hour of scrolling.'],
    '食伤' => ['Write the idea down; it dies in your head.', 'Let the brain go first; the mouth can follow.'],
    _ => ['Don\'t carry all the damage alone today.', 'Friends are a resource — and an expense. Count both.'],
  };
  return _pick([...pool, if (f.overall >= 80) 'Green light. Don\'t waste it.', if (f.overall < 45) 'Low power mode: skip every decision you can.'], seed);
}

String _dailyDontEn(BaziChart c, DailyFortune f) {
  final items = {'Career': f.career, 'Wealth': f.wealth, 'Love': f.love, 'Health': f.health};
  final worst = items.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  final pool = switch (worst) {
    'Career' => ['Don\'t argue in the group chat.', 'Don\'t resign, ask for a raise, or pitch today.', 'Don\'t change a plan that\'s already set.'],
    'Wealth' => ['Don\'t buy the thing that\'s been in your cart for three days.', 'Don\'t lend, don\'t borrow.', 'Don\'t check the investment account.'],
    'Love' => ['Don\'t bring up old fights.', 'Don\'t text while upset.', 'Don\'t guess — ask.'],
    _ => ['Don\'t stay up past midnight.', 'Don\'t swap lunch for coffee.', 'Don\'t sit two hours without standing.'],
  };
  return _pick(pool, _seed(c) + f.dayPillar.index * 5);
}

String _dailyDoEn(BaziChart c, DailyFortune f) {
  final items = {'Career': f.career, 'Wealth': f.wealth, 'Love': f.love, 'Health': f.health};
  final best = items.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  final a = _advice[c.elements.primaryUsefulGod]!;
  final pool = switch (best) {
    'Career' => ['Send the email you\'ve put off for a week.', 'Update your manager before they ask.', 'Write tomorrow\'s three tasks before you log off.'],
    'Wealth' => ['Log every expense today.', 'Send one payment reminder.', 'Cancel one subscription.'],
    'Love' => ['Message someone you haven\'t spoken to in months.', 'Say thank you in person.', 'Ten minutes tonight with the phone down.'],
    _ => ['Walk twenty minutes, heading ${a.direction}.', 'Wear something ${a.colors.split(',').first}.', 'Sleep half an hour earlier.'],
  };
  return _pick(pool, _seed(c) + f.dayPillar.index * 11);
}

String _annualHeadlineEn(BaziChart c, AnnualFortune a) {
  if (a.isOffendingTaiSui) return _pick(['Difficulty up one notch — so are the rewards', 'Tai Sui year: fasten the seatbelt, keep driving', 'This year\'s keyword is steady; everything else is a side dish'], _seed(c) + a.year);
  final pool = switch (a.grade) {
    '顺遂年' => ['Tailwind year — don\'t just enjoy it, use it', 'Escalator year: standing still still goes up'],
    '稳中有进' => ['Not flashy, but you\'ll end richer than you started', 'A year for deep roots'],
    '平年' => ['Cloudy year — bring an umbrella', 'No big drama; polish the small things'],
    '守成年' => ['Low-power year: hold the base', 'Don\'t open new fronts; close the old ones'],
    _ => ['Bamboo year: nothing above ground, everything below', 'Gather now, sprint later'],
  };
  return _pick(pool, _seed(c) + a.year);
}

/// Persona for the shareable card and the dashboard one-liner.
({String image, String traits, String tip}) enStemPersona(int stem) {
  final p = _stemPersona[stem];
  return (image: p.image, traits: p.traits, tip: p.tip);
}

String _strengthPlain(StrengthLevel l) => switch (l) {
      StrengthLevel.veryStrong => 'Your own side is very strong — big ideas, big drive, and a tendency to do things your own way. Like a phone at 100% still plugged in: the question is where to spend the power.',
      StrengthLevel.strong => 'Energetic and opinionated; you do best when busy and producing. 80% battery — no charger needed, just don\'t scroll all day.',
      StrengthLevel.balanced => 'A balanced chart: go with the flow and top up whichever side runs low. Just enough battery to last the day, with room to sprint.',
      StrengthLevel.weak => 'Plenty of ideas but often short on push; mentors, teams and learning are your boosters. 40% battery — find the charging points, which here are the Resource and Companion stars.',
      StrengthLevel.veryWeak => 'Sensitive and perceptive; going it alone is hard, leaning on others goes far. At 15% the smart move is finding a socket — charts like this often attract helpful people.',
    };

const Map<TenGod, String> _godPlain = {
  TenGod.friend: 'peers and competitors — independence and self-will; your "twin", so ally and rival at once',
  TenGod.robWealth: 'friends, partnerships, spending on others — drive and loyalty; the urge to grab the bill',
  TenGod.eatingGod: 'talent, appetite, enjoyment — gentle creativity; the foodie and the performer',
  TenGod.hurtingOfficer: 'brilliance and edge, dislike of authority — restless creativity; managers love and fear it',
  TenGod.indirectWealth: 'windfalls, networks, generosity — money arrives fast and leaves fast',
  TenGod.directWealth: 'earned income, thrift, steadiness — the salary, the ledger, the price comparison',
  TenGod.sevenKillings: 'pressure and nerve — thrives under deadlines that flatten other people',
  TenGod.directOfficer: 'reputation, discipline, responsibility — the person who genuinely stops at red lights',
  TenGod.indirectResource: 'niche knowledge and intuition — bookmarks full of tutorials nobody else understands',
  TenGod.directResource: 'mother, education, patrons — always someone looking out for you',
};

const Map<String, String> _groupPlain = {
  '比劫': 'Companions day: lots of friends and lots of competition — collaborate, but don\'t fight over the bill.',
  '食伤': 'Output day: ideas and words flow — create, express, eat something good.',
  '财星': 'Wealth day: the keywords are money and practical matters — negotiate, budget, get things done.',
  '官杀': 'Authority day: responsibility and opportunity arrive together — handle official business, see the boss.',
  '印星': 'Resource day: learn, rest, accept help — people are willing to teach you today.',
};

class _Advice {
  const _Advice(this.direction, this.colors, this.industries, this.habits);
  final String direction, colors, industries, habits;
}

const Map<Element, _Advice> _advice = {
  Element.wood: _Advice('east', 'green', 'education, design, horticulture, fashion, timber', 'plants nearby, morning walks, a green desk'),
  Element.fire: _Advice('south', 'red, orange, purple', 'energy, food & drink, performance, media, electronics', 'sunlight, bright rooms, avoid dim spaces'),
  Element.earth: _Advice('centre / local', 'yellow, brown, earth tones', 'property, agriculture, construction, management, collecting', 'regular routine, grounded habits, less late nights'),
  Element.metal: _Advice('west', 'white, gold, silver', 'finance, law, machinery, hardware, jewellery', 'tidy surroundings, metal accessories, rule-based work'),
  Element.water: _Advice('north', 'black, blue', 'logistics, trade, consulting, internet, seafood', 'drink water, be near water, keep thoughts moving'),
};

// ------------------------------------------------------------------ Bazi

String enInterpretBazi(BaziChart c) {
  final e = c.elements;
  final p = _stemPersona[c.dayStem];
  final b = StringBuffer();

  b.writeln('# ${_baziHeadlineEn(c)}\n');
  b.writeln(_q('${p.image[0].toUpperCase()}${p.image.substring(1)}: ${p.tip}'));
  b.writeln(_h('🪞 In plain words: who you are'));
  b.writeln('${_t(c.input.gender.chartLabel)}, Four Pillars **${summaryEn(c)}**, Day Master **${stemEn(c.dayStem)}** '
      '(the Day Master, 日主, is the stem of your birth day — it stands for you).');
  b.writeln('${stemPinyin[c.dayStem]} is **${p.image}** — ${p.plain}');
  b.writeln(_q(p.fun));
  b.writeln('Layer on the strength reading, **${_t(e.strength.label)}**: ${_strengthPlain(e.strength)}\n');
  if (c.input.timeMode.isEstimated) {
    b.writeln(_q('Birth time unknown: the Hour Pillar, Life Palace and luck-cycle start are estimated from noon. Treat anything that depends on them as approximate.'));
  }

  b.writeln(_h('The four pillars'));
  const scope = [
    'ancestors & childhood, first impressions',
    'parents, siblings & youth, your career stage',
    'yourself & spouse, the marriage palace',
    'children & later life, your inner colour',
  ];
  for (var i = 0; i < 4; i++) {
    final pl = c.pillars[i];
    final god = pl.stemGod;
    b.writeln('- **${pillarEnglish[i]} ${stemBranchEn(pl.stemBranch)}** · ${scope[i]}. '
        'Stem: ${god == null ? 'the Day Master itself' : _t(god.label)}; hidden stems: '
        '${pl.hiddenStems.map((h) => '${stemPinyin[h.stem]} (${_t(h.tenGod.label)})').join(', ')}; '
        'life stage ${lifeStageEnglish[lifeStages.indexOf(pl.lifeStage)]}.');
  }
  b.writeln();

  b.writeln(_h('Five-element check-up'));
  b.writeln(Element.values.map((el) => '${_el(el)} ${e.percentages[el]!.round()}%').join(' · '));
  b.writeln();
  final gets = [
    e.gotSeason ? 'the season supports you' : 'the season does not support you',
    e.gotRoot ? 'you have roots in the branches' : 'no roots in the branches',
    e.gotSupport ? 'you have helpers among the stems' : 'few helpers among the stems',
  ];
  b.writeln('Timing, roots, support: ${gets.join('; ')}. Day Master judged **${_t(e.strength.label)}**.');
  if (e.missing.isNotEmpty) {
    b.writeln('Missing element(s): **${e.missing.map(_el).join(', ')}** — not a flaw, just a missing seasoning you now know to add.');
  }
  b.writeln();

  final primary = e.primaryUsefulGod;
  final a = _advice[primary]!;
  b.writeln(_h('Your supplements and your allergens'));
  b.writeln('Useful god (the element that helps you most): **${_el(primary)}**. Favourable: ${e.favorable.map(_el).join(', ')}; avoid: ${e.unfavorable.map(_el).join(', ')}.');
  b.writeln('- Direction: ${a.direction}; colours: ${a.colors}');
  b.writeln('- Fields: ${a.industries}');
  b.writeln('- Habits: ${a.habits}');
  b.writeln(_q('"Avoid" means don\'t make it your staple diet, not never touch it.'));

  b.writeln(_h('The supporting cast: Ten Gods'));
  final gods = <TenGod, int>{};
  for (final pl in c.pillars) {
    if (pl.stemGod != null) gods[pl.stemGod!] = (gods[pl.stemGod!] ?? 0) + 2;
    for (final h in pl.hiddenStems) {
      gods[h.tenGod] = (gods[h.tenGod] ?? 0) + (h.weight >= 0.6 ? 1 : 0);
    }
  }
  final top = gods.entries.where((x) => x.value > 0).toList()..sort((x, y) => y.value.compareTo(x.value));
  for (final g in top.take(3)) {
    b.writeln('- **${_t(g.key.label)}** (appears ${g.value}×): ${_godPlain[g.key]}');
  }
  b.writeln();

  if (c.shenSha.isNotEmpty) {
    b.writeln(_h('Badges on the chart: symbolic stars'));
    for (final s in c.shenSha) {
      final tag = switch (s.nature) {
        ShenShaNature.auspicious => 'auspicious',
        ShenShaNature.inauspicious => 'take care',
        ShenShaNature.neutral => 'neutral',
      };
      b.writeln('- **${_t(s.name)}** ($tag, ${s.positions.map((i) => pillarEnglish[i]).join('/')} pillar) — ${s.meaning}');
    }
    b.writeln();
  }

  b.writeln(_h('Weather forecast: luck cycles'));
  final l = c.luck;
  b.writeln('Cycles run ${_t(l.direction)}, starting ${l.startYears}y ${l.startMonths}m ${l.startDays}d after birth; each cycle lasts ten years.');
  final now = DateTime.now().year;
  final cur = l.cycleForYear(now);
  if (cur != null) {
    final sg = tenGodOf(c.dayStem, cur.pillar.stem);
    final bg = tenGodOf(c.dayStem, mainHiddenStem(cur.pillar.branch));
    final el = stemElements[cur.pillar.stem];
    final verdict = e.favorable.contains(el)
        ? 'a favourable element for you — a tailwind decade'
        : e.unfavorable.contains(el)
            ? 'an element you should avoid — a headwind decade: steady steps, no big bets'
            : 'neutral for you — a decade for accumulating';
    b.writeln('**Current cycle ${stemBranchEn(cur.pillar)} (${cur.startYear}–${cur.endYear})**: stem ${_t(sg.label)}, branch ${_t(bg.label)}; the stem is ${_el(el)}, $verdict.');
  }
  b.writeln();

  b.writeln(_h('One-line version'));
  b.writeln('${p.image[0].toUpperCase()}${p.image.substring(1)}, ${_t(e.strength.label).toLowerCase()}, powered by ${_el(primary)} — '
      '${e.strength.isStrongSide ? 'produce more, carry more' : e.strength.isWeakSide ? 'lean on people, keep learning' : 'go with the flow'}. ${p.tip}');

  b.writeln(_notes(e.reasoning));
  return b.toString() + _footer;
}

String _notes(List<String> lines) {
  if (lines.isEmpty) return '';
  return '\n${_h('Notes (中文, raw evidence)')}${lines.map((l) => '- $l').join('\n')}\n';
}

// ------------------------------------------------------------------ Daily

String enInterpretDaily(BaziChart c, DailyFortune f) {
  final b = StringBuffer();
  final verdict = f.overall >= 85
      ? 'Excellent — a green-light day; do the important things today.'
      : f.overall >= 70
          ? 'Good — a tailwind day; things in motion move with less effort.'
          : f.overall >= 55
              ? 'Average — stick to the plan, no forcing.'
              : f.overall >= 40
                  ? 'Caution — a low-battery day; fewer decisions, more tidying.'
                  : 'Hold — guard what you have and don\'t open new fronts.';
  b.writeln('# ${_dailyHeadlineEn(c, f)}\n');
  b.writeln(_q(_dailyQuoteEn(c, f)));
  b.writeln('${ymdEn(f.year, f.month, f.day)} · ${stemBranchEn(f.dayPillar)} day · Overall **${f.overall}**. $verdict\n');

  b.writeln(_h('Today\'s theme: ${_t(f.theme.label)}'));
  b.writeln('Today\'s stem ${stemPinyin[f.dayPillar.stem]} is your **${_t(f.theme.label)}** (${_godPlain[f.theme]}). ${_groupPlain[f.theme.group] ?? ''}\n');

  final items = {'Career': f.career, 'Wealth': f.wealth, 'Love': f.love, 'Health': f.health};
  final best = items.entries.reduce((x, y) => x.value >= y.value ? x : y);
  final worst = items.entries.reduce((x, y) => x.value <= y.value ? x : y);
  b.writeln(_h('The four scores'));
  b.writeln(items.entries.map((x) => '${x.key} ${x.value}').join(' · '));
  b.writeln('Brightest: **${best.key}** (${best.value}) — schedule the important ${best.key.toLowerCase()} matters today. Watch: **${worst.key}** (${worst.value}).\n');

  b.writeln(_h('🚫 One thing not to do today'));
  b.writeln('**${_dailyDontEn(c, f)}**\n');
  b.writeln(_h('✅ One small thing to do today'));
  b.writeln('**${_dailyDoEn(c, f)}**\n');

  b.writeln(_h('Cheat sheet'));
  b.writeln('Lucky colour **${_t(f.luckyColor)}** · lucky numbers **${f.luckyNumbers.join(', ')}** · direction **${_t(f.luckyDirection)}**');

  b.writeln(_notes(f.factors));
  return b.toString() + _footer;
}

String ymdEn(int y, int m, int d) => '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

// ------------------------------------------------------------------ Annual

const Map<TaiSuiKind, String> _taiSuiEn = {
  TaiSuiKind.same: 'Same as your birth animal — a "Ben Ming" year: change, pressure and turning points; steadiness over haste.',
  TaiSuiKind.clash: 'Clashes with your birth animal: moves, separations, upheaval; better to choose change than have it chosen for you.',
  TaiSuiKind.punish: 'Punishes your birth animal: disputes, gossip, friction; leave room in every deal.',
  TaiSuiKind.harm: 'Harms your birth animal: hidden obstacles, unreliable people; guard against people more than events.',
  TaiSuiKind.destroy: 'Breaks your birth animal: leaks and interrupted plans; protect savings, avoid big moves.',
  TaiSuiKind.combine: 'Combines with your birth animal: good connections and helpful people; a year to collaborate.',
};

String enInterpretAnnual(BaziChart c, AnnualFortune a) {
  final b = StringBuffer();
  final gradeEn = switch (a.grade) {
    '顺遂年' => 'Smooth year — like riding an escalator: projects, proposals and job moves take less effort than usual.',
    '稳中有进' => 'Steady progress — not flashy, but you end the year with more than you started.',
    '平年' => 'An ordinary year — "cloudy", bring an umbrella and carry on.',
    '守成年' => 'A holding year — low-power mode: keep what you have, dig roots, grow next year.',
    _ => 'A gathering year — like bamboo growing roots underground: quiet now, fast later.',
  };
  b.writeln('# ${_annualHeadlineEn(c, a)}\n');
  const approxQ = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
  b.writeln(_q('Best months: ${a.bestMonths.map((i) => approxQ[i]).join(' and ')} — put the big moves there. '
      'Ease off in ${a.cautionMonths.map((i) => approxQ[i]).join(' and ')}.'));
  b.writeln(_h('${a.year} · ${stemBranchEn(a.yearPillar)} year · age ${a.nominalAge} · ${_t(a.grade)}'));
  b.writeln('Overall **${a.overall}**. $gradeEn');
  if (a.luckPillar != null) {
    b.writeln('This is year ${a.year - a.luckPillar!.startYear + 1} of your **${stemBranchEn(a.luckPillar!.pillar)}** luck cycle (${a.luckPillar!.ageRange}).');
  }
  b.writeln();

  if (a.taiSui.isNotEmpty) {
    b.writeln(_h(a.isOffendingTaiSui ? 'Tai Sui alert (犯太岁)' : 'Tai Sui in harmony (合太岁)'));
    for (final t in a.taiSui) {
      b.writeln('- **${_t(t.label)}**: ${_taiSuiEn[t]}');
    }
    b.writeln(_q(a.isOffendingTaiSui
        ? '"Offending Tai Sui" doesn\'t mean disaster — it means the year\'s default difficulty is one notch higher: think twice, read contracts twice, sleep an extra hour. The traditional red clothing is really a reminder to be careful, and the reminder is the point.'
        : 'A harmonious Tai Sui year is rare — helpful people and opportunities are closer than usual, so take the initiative.'));
  }

  b.writeln(_h('Theme of the year: ${_t(a.theme.label)}'));
  b.writeln('The year\'s stem ${stemPinyin[a.yearPillar.stem]} is your **${_t(a.theme.label)}** — ${_godPlain[a.theme]}. ${_groupPlain[a.theme.group] ?? ''}\n');

  final items = {'Career': a.career, 'Wealth': a.wealth, 'Love': a.love, 'Health': a.health};
  final best = items.entries.reduce((x, y) => x.value >= y.value ? x : y);
  final worst = items.entries.reduce((x, y) => x.value <= y.value ? x : y);
  b.writeln(_h('Four areas'));
  b.writeln(items.entries.map((x) => '${x.key} ${x.value}').join(' · '));
  b.writeln('Brightest: **${best.key}** (${best.value}) — put the big moves here. Needs care: **${worst.key}** (${worst.value}).\n');

  b.writeln(_h('Month by month'));
  b.writeln('Solar-term months, starting from Start of Spring:');
  const approx = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
  for (final m in a.months) {
    final tag = a.bestMonths.contains(m.index) ? ' ⭐' : a.cautionMonths.contains(m.index) ? ' ⚠' : '';
    b.writeln('- **${stemBranchEn(m.pillar)}** (≈${approx[m.index]}) ${m.score}$tag — ${_t(m.theme.label)} month');
  }
  b.writeln();
  b.writeln('Best months: **${a.bestMonths.map((i) => approx[i]).join(', ')}**; take it easy in **${a.cautionMonths.map((i) => approx[i]).join(', ')}**.\n');

  b.writeln(_h('One-line version'));
  b.writeln('${a.year} is a "${_t(a.grade)}" with a ${_t(a.theme.group)} theme${a.isOffendingTaiSui ? ', with a Tai Sui caution' : ''} — '
      '${a.overall >= 65 ? 'act when the moment comes' : a.overall >= 50 ? 'steady as she goes' : 'protect the base and save strength for next year'}.');

  b.writeln(_notes(a.factors));
  return b.toString() + _footer;
}

// ------------------------------------------------------------------ Marriage

String enInterpretMarriage(MarriageResult m) {
  final b = StringBuffer();
  final pa = _stemPersona[m.a.dayStem], pb = _stemPersona[m.b.dayStem];
  b.writeln(_h('Verdict: ${_t(m.grade)} · ${m.overall}/100'));
  b.writeln('${_t(m.a.input.gender.chartLabel)} ${summaryEn(m.a)} (${stemPinyin[m.a.dayStem]}, ${pa.image}) × '
      '${_t(m.b.input.gender.chartLabel)} ${summaryEn(m.b)} (${stemPinyin[m.b.dayStem]}, ${pb.image})\n');

  b.writeln(_h('The two of you in one picture'));
  b.writeln('One is **${pa.image}** (${pa.traits}), the other **${pb.image}** (${pb.traits}).');
  final rel = m.a.dayMaster.relationTo(m.b.dayMaster);
  b.writeln(switch (rel) {
    ElementRelation.same => 'Same element — zero-cost understanding, but you also make the same mistakes at the same time.',
    ElementRelation.iGenerate || ElementRelation.generatesMe => 'One element feeds the other — one of you is the power supply; remember to recharge that person.',
    _ => 'One element controls the other — one of you tends to drive; fine, as long as nobody grabs the wheel.',
  });
  b.writeln();

  b.writeln(_h('Six dimensions'));
  for (final d in m.dimensions) {
    b.writeln('**${_t(d.name)} ${d.clamped}** (weight ${(d.weight * 100).round()}%)');
    for (final r in d.reasons) {
      b.writeln('- $r');
    }
    b.writeln();
  }

  b.writeln(_h('Advice'));
  final lowest = m.dimensions.reduce((x, y) => x.clamped <= y.clamped ? x : y);
  b.writeln('1. The lowest score is **${_t(lowest.name)}** — start there; talk about money, chores and holidays early.');
  b.writeln('2. ${pa.tip} (for ${_t(m.a.input.gender.label).toLowerCase()} partner)');
  b.writeln('3. ${pb.tip} (for ${_t(m.b.input.gender.label).toLowerCase()} partner)');
  b.writeln('\nA compatibility reading is a user manual, not a verdict: the score describes default settings, and people change settings.');
  return b.toString() + _footer;
}

// ------------------------------------------------------------------ Name

String enInterpretName(NameAnalysis n) {
  final b = StringBuffer();
  b.writeln(_h('${n.fullName} · ${n.overallScore}/100'));
  b.writeln('Kangxi strokes: ${n.strokes.join(' · ')}.\n');
  b.writeln(_h('The five grids'));
  b.writeln('Five-grid analysis splits a name into five numbers, each governing a part of life. Person and Total matter most.');
  const plain = {
    '天格': 'Heaven — inherited, little personal effect',
    '人格': 'Person — you yourself, the core',
    '地格': 'Earth — roughly the first 35 years, family and foundation',
    '外格': 'Outer — social life and helpful people',
    '总格': 'Total — roughly after 35, career and later life',
  };
  for (final g in [n.ren, n.zong, n.di, n.wai, n.tian]) {
    final icon = switch (g.meaning.luck) { Luck.auspicious => '🟢', Luck.half => '🟡', Luck.inauspicious => '🔴' };
    b.writeln('- $icon **${_t(g.name)} ${g.number}** (${_t(g.meaning.luck.label)}): ${plain[g.name]}. ${g.meaning.title} — ${g.meaning.text}');
  }
  b.writeln();
  b.writeln(_h('Three Talents'));
  b.writeln('${n.sanCaiText} (Heaven · Person · Earth), ${n.sanCaiScore}/100. ${n.sanCaiComment}\n');
  if (n.elementNotes.isNotEmpty) b.writeln(_notes([...n.elementNotes, ...n.zodiacNotes]));
  if (n.unknownChars.isNotEmpty) {
    b.writeln(_q('Stroke count unknown for 「${n.unknownChars.join('、')}」 (counted as 0); treat the result as approximate.'));
  }
  return b.toString() + _footer;
}

// ------------------------------------------------------------------ Almanac

String enInterpretAlmanac(AlmanacDay a, {BaziChart? chart}) {
  final b = StringBuffer();
  b.writeln(_h('${ymdEn(a.year, a.month, a.day)} · ${stemBranchEn(a.yearPillar)} year, ${stemBranchEn(a.monthPillar)} month, ${stemBranchEn(a.dayPillar)} day'));
  b.writeln('${lunarEn(a.lunar)} · ${a.xiu}');
  if (a.solarTerm != null) b.writeln('Solar term today: **${_t(a.solarTerm!.name)}** — a change of season; give body and schedule some slack.');
  b.writeln();
  b.writeln(_h('What kind of day'));
  b.writeln('Officer of the day: **${_t(a.jianChu)}**; presiding spirit: **${_t(a.zhiShen)}** (${a.isHuangDao ? 'auspicious' : 'inauspicious'} day).');
  b.writeln(a.isHuangDao && ['成', '开', '定', '满'].contains(a.jianChu)
      ? 'Both signals green: **a good day to get things done.**'
      : !a.isHuangDao && ['破', '危', '闭'].contains(a.jianChu)
          ? 'Both signals weak: **a day for rest and tidying, not new ventures.**'
          : 'Mixed signals: **an ordinary usable day** — put important matters in the auspicious hours.');
  b.writeln();
  b.writeln(_h('Do / Avoid (中文)'));
  b.writeln('**Do**: ${a.suitable.isEmpty ? '—' : a.suitable.join('、')}');
  b.writeln('**Avoid**: ${a.unsuitable.isEmpty ? '—' : a.unsuitable.join('、')}\n');
  b.writeln(_h('Clash and directions'));
  b.writeln('Clashes with the **${animalEnglish[a.clashPillar.branch]}** (${stemBranchEn(a.clashPillar)}); Sha direction ${_t(a.shaDirection)}. Joy god ${_t(a.joyDirection)}, wealth god ${_t(a.wealthDirection)}.\n');
  final good = a.hourFortunes.where((h) => h.isHuangDao).toList();
  if (good.isNotEmpty) {
    b.writeln(_h('Golden hours'));
    b.writeln(good.map((h) => '${stemBranchEn(h.stemBranch)} ${h.range} (${_t(h.zhiShen)})').join(' · '));
    b.writeln();
  }
  if (chart != null) {
    b.writeln(_h('For you personally'));
    final dayEl = branchElements[a.dayPillar.branch];
    b.writeln(a.clashZodiac == chart.zodiac
        ? 'Today clashes with your own animal (${animalEnglish[chart.yearPillar.stemBranch.branch]}) — not a ban on going out, just avoid decisions that need luck.'
        : 'No clash with your animal today.');
    b.writeln(chart.elements.favorable.contains(dayEl)
        ? 'The day\'s branch is ${_el(dayEl)}, one of your favourable elements: almanac and chart point the same way.'
        : chart.elements.unfavorable.contains(dayEl)
            ? 'The day\'s branch is ${_el(dayEl)}, an element you should avoid: discount the almanac a little — fine to act, not to gamble.'
            : 'The day\'s branch is ${_el(dayEl)}, neutral for you.');
  }
  b.writeln(_notes(a.notes));
  return b.toString() + _footer;
}

// ------------------------------------------------------------------ Palm / Face

String enInterpretPalm(PalmFeatures p) {
  final b = StringBuffer();
  b.writeln(_h('${_t(p.hand)} · ${_t(p.handShape)}'));
  b.writeln('Palm length/width ${p.palmAspect.toStringAsFixed(2)} · middle finger/palm ${p.fingerToPalm.toStringAsFixed(2)} · thumb angle ${p.thumbAngle.toStringAsFixed(0)}°');
  b.writeln(switch (p.handShape) {
    '土型' => 'Earth hand: the doer — grounded, allergic to empty talk.',
    '火型' => 'Fire hand: the mover — warm, direct, acts on impulse.',
    '风型' => 'Air hand: the thinker — analytical, talkative, argumentative.',
    _ => 'Water hand: the feeler — sensitive, artistic, first to spot the plot twist.',
  });
  b.writeln();
  b.writeln(_h('The three main lines'));
  b.writeln('Life line = energy and rhythm, head line = thinking style, heart line = emotional expression. **None of them predict lifespan or outcomes — they describe style.**');
  for (final l in p.lines) {
    b.writeln('- **${_t(l.name)}**: length ${l.length.toStringAsFixed(2)} · curve ${l.curvature.toStringAsFixed(2)}${l.segments > 1 ? ' · ${l.segments - 1} break(s) — traditionally "life stages", very common' : ''}');
  }
  b.writeln();
  b.writeln(_h('Fingers'));
  for (final e in p.fingerRatios.entries) {
    b.writeln('- ${_t(e.key)} ${e.value.toStringAsFixed(2)}');
  }
  b.writeln(_notes(p.notes));
  b.writeln('Palm lines change with age and use — this is a snapshot of who you are now.');
  return b.toString() + _footer;
}

String enInterpretFace(FaceFeatures f) {
  final b = StringBuffer();
  final courts = f.threeCourts.map((c) => (c * 100).round()).toList();
  b.writeln(_h('${_t(f.faceShape)} · symmetry ${(f.symmetry * 100).round()}%'));
  b.writeln(_h('Three courts, five eyes'));
  b.writeln('The face is split into three horizontal bands: upper (hairline–brow) for early life and thinking, middle (brow–nose) for mid-life and action, lower (nose–chin) for later life and will.');
  b.writeln('Yours: **${courts.join(' : ')}** (ideal ≈ 33:33:33); face width ≈ **${f.fiveEyes.toStringAsFixed(1)}** eye-lengths (ideal ≈ 5).');
  final maxIdx = courts.indexOf(courts.reduce((x, y) => x > y ? x : y));
  b.writeln(_q(['Upper court longer: a thinker — plans run ahead of action.', 'Middle court longer: a doer — the thirties to fifties are home turf.', 'Lower court longer: steadier with age — willpower is the long suit.'][maxIdx]));
  b.writeln(_h('Twelve palaces (中文)'));
  b.writeln('Face reading maps twelve "palaces" onto the features; the geometry gives these descriptions (shape only, never beauty):');
  for (final e in f.palaces.entries) {
    b.writeln('- **${e.key}**: ${e.value}');
  }
  b.writeln(_notes(f.notes));
  b.writeln('A face reflects expression, habit and state — so this is a snapshot of recent you, not factory settings.');
  return b.toString() + _footer;
}

// ------------------------------------------------------------------ Zodiac

String enInterpretZodiac(ZodiacProfile p, {ZodiacMatch? match, BaziChart? chart}) {
  final s = p.sun;
  final z = zodiacEn[s.index];
  final b = StringBuffer();
  const elName = {'火': 'Fire', '土': 'Earth', '风': 'Air', '水': 'Water'};
  const modName = {'基本': 'cardinal', '固定': 'fixed', '变动': 'mutable'};

  b.writeln(_h('Sun sign · ${s.symbol} ${s.english}'));
  b.writeln('${elName[s.element.label]} sign · ${modName[s.modality.label]} · ruled by ${_t(s.ruler)}; Sun at ${p.sunDegreeInSign.toStringAsFixed(1)}° of the sign.');
  b.writeln('The Sun sign is your **inner drive** — what makes you feel alive.');
  if (p.nearCusp) {
    b.writeln(_q('Born on a cusp (under 1° from ${p.cuspNeighbour!.english}): traits of both signs may apply — when people say "you don\'t seem like a ${s.english}", you can say you\'re a blend.'));
  }
  b.writeln(_h('Personality'));
  b.writeln('Keywords: ${z.keywords.join(', ')}');
  b.writeln('- Strengths: ${z.strengths.join(', ')}');
  b.writeln('- Watch out: ${z.weaknesses.join(', ')} — each is a strength turned up too far.\n');

  b.writeln(_h('Rising sign: how others see you'));
  if (p.rising == null) {
    b.writeln('No birthplace coordinates, so the rising sign cannot be computed.');
  } else {
    final r = p.rising!;
    b.writeln('${r.symbol} **${r.english}** (${elName[r.element.label]}). ${zodiacEn[r.index].rising}.');
    b.writeln(r.element != s.element
        ? 'Rising (${elName[r.element.label]}) and Sun (${elName[s.element.label]}) are different elements: what people see and what you feel don\'t quite match — a ${r.english} coat over a ${s.english} T-shirt.'
        : 'Rising and Sun share an element: what people see is what you are, which saves a lot of explaining.');
    b.writeln('(The rising sign changes about every two hours and depends on an accurate birth time.)');
  }
  b.writeln();

  if (chart != null) {
    b.writeln(_h('Zodiac × Four Pillars'));
    b.writeln('The Four Pillars call you **${_stemPersona[chart.dayStem].image}** (Day Master ${stemEn(chart.dayStem)}, ${_t(chart.elements.strength.label).toLowerCase()}); astrology calls you a **${s.english}** (${elName[s.element.label]}). '
        'The five elements describe balance, the four classical elements describe temperament — they don\'t convert directly, but when both point the same way, that trait is probably solid.\n');
  }

  if (match != null) {
    b.writeln(_h('Pairing · ${match.a.symbol}${match.a.english} × ${match.b.symbol}${match.b.english}'));
    b.writeln('**${_t(match.summary)}** (${match.score}/100)');
    b.writeln(_notes(match.reasons));
  } else {
    b.writeln(_h('Best matches'));
    b.writeln(bestMatchesFor(s).map((x) => '${x.symbol}${x.english} (${zodiacMatch(s, x).score})').join(', '));
    b.writeln('Your opposite sign ${s.opposite.symbol}${s.opposite.english} is the "complementary attraction" — a mirror of what you lack.\n');
  }

  b.writeln(_h('Tips'));
  b.writeln('Lucky colour ${z.color} · lucky numbers ${s.luckyNumbers.join(', ')}');
  b.writeln('One line: a ${s.english}\'s life lesson is turning "${z.weaknesses.first}" into the other face of "${z.strengths.first}".');
  return b.toString() + _footer;
}
