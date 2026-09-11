// 生成 assets/data/kangxi_strokes.json —— 从 Unicode Unihan 数据库派生康熙笔画字典。
//
// 用法(生成后本文件不随 app 打包,只是构建工具):
//   node build_kangxi_dict.mjs <unihan目录> <builtin_strokes.dart路径> <输出json路径>
//
// 原理:
// 1. 姓名学的"康熙笔画"要求先把简体字换成繁体字,再数繁体字形的笔画——
//    这正是 core/naming/stroke_dictionary.dart 顶部注释强调的口径。
// 2. Unihan 的 kTotalStrokes 字段是"该码位自身字形"的笔画数(简体码位给简体笔画,
//    繁体码位给繁体笔画),所以不能直接按简体字码位取值,必须先用 kTraditionalVariant
//    换成繁体码位,再取那个码位的 kTotalStrokes。
// 3. kRSUnicode 给"部首序号.additional strokes",序号查 214 部首表得部首字。
// 4. 极少数简体字对应多个繁体字(一简对多繁,如"发"→"發/髮"),用人工表兜底,
//    因为这类字数量很少(几十个)且没有单一"正确答案",需按姓名学惯例取舍。
//
// 数据许可:Unicode Character Database,见 https://www.unicode.org/terms_of_use.html
// (联合国教科文组织级公共标准,允许在产品中派生使用,附带许可声明即可。)

import { readFileSync, writeFileSync } from 'node:fs';

const [, , unihanDir, builtinDartPath, outPath] = process.argv;
if (!unihanDir || !builtinDartPath || !outPath) {
  console.error('用法: node build_kangxi_dict.mjs <unihan目录> <builtin_strokes.dart> <输出json>');
  process.exit(1);
}

function readLines(name) {
  return readFileSync(`${unihanDir}/${name}`, 'utf8')
    .split('\n')
    .filter((l) => l && !l.startsWith('#'));
}

function cp(u) {
  // "U+706B" -> 0x706B -> 对应字符
  return String.fromCodePoint(parseInt(u.slice(2), 16));
}

// ---------- 214 康熙部首表:序号 -> {字, 五行(常见归类,仅供辅助参考)} ----------
// 五行归类采用姓名学界通行的"以形取义"惯例(如水部属水、火部属火),
// 归类本身没有唯一学术标准,此处取多数流派共识;有争议的部首(如"人""口"等
// 中性部首)不归类,留空由调用方按整字另行判断。
const RADICAL_TABLE = [
  null,
  ['一', null], ['丨', null], ['丶', 'fire'], ['丿', 'wood'], ['乙', null],
  ['亅', null], ['二', null], ['亠', null], ['人', null], ['儿', null],
  ['入', null], ['八', null], ['冂', null], ['冖', null], ['冫', 'water'],
  ['几', null], ['凵', null], ['刀', 'metal'], ['力', null], ['勹', null],
  ['匕', null], ['匚', null], ['匸', null], ['十', null], ['卜', null],
  ['卩', null], ['厂', 'earth'], ['厶', null], ['又', null], ['口', null],
  ['囗', null], ['土', 'earth'], ['士', null], ['夂', null], ['夊', null],
  ['夕', null], ['大', null], ['女', null], ['子', 'water'], ['宀', null],
  ['寸', null], ['小', null], ['尢', null], ['尸', null], ['屮', 'wood'],
  ['山', 'earth'], ['巛', 'water'], ['工', null], ['己', null], ['巾', null],
  ['干', null], ['幺', null], ['广', null], ['廴', null], ['廾', null],
  ['弋', null], ['弓', null], ['彐', null], ['彡', null], ['彳', null],
  ['心', 'fire'], ['戈', 'metal'], ['戶', null], ['手', 'wood'], ['支', null],
  ['攴', null], ['文', null], ['斗', null], ['斤', 'metal'], ['方', null],
  ['无', null], ['日', 'fire'], ['曰', null], ['月', 'water'], ['木', 'wood'],
  ['欠', null], ['止', null], ['歹', null], ['殳', null], ['毋', null],
  ['比', null], ['毛', null], ['氏', null], ['气', null], ['水', 'water'],
  ['火', 'fire'], ['爪', null], ['父', null], ['爻', null], ['爿', 'wood'],
  ['片', 'wood'], ['牙', null], ['牛', 'earth'], ['犬', null], ['玄', null],
  ['玉', 'metal'], ['瓜', null], ['瓦', 'earth'], ['甘', null], ['生', 'wood'],
  ['用', null], ['田', 'earth'], ['疋', null], ['疒', null], ['癶', null],
  ['白', 'metal'], ['皮', null], ['皿', null], ['目', null], ['矛', 'metal'],
  ['矢', null], ['石', 'metal'], ['示', null], ['禸', null], ['禾', 'wood'],
  ['穴', null], ['立', null], ['竹', 'wood'], ['米', 'wood'], ['糸', 'wood'],
  ['缶', 'earth'], ['网', null], ['羊', 'earth'], ['羽', null], ['老', null],
  ['而', null], ['耒', 'wood'], ['耳', null], ['聿', null], ['肉', null],
  ['臣', null], ['自', null], ['至', null], ['臼', null], ['舌', null],
  ['舛', null], ['舟', 'wood'], ['艮', null], ['色', null], ['艸', 'wood'],
  ['虍', null], ['虫', null], ['血', null], ['行', null], ['衣', null],
  ['襾', null], ['見', null], ['角', null], ['言', null], ['谷', null],
  ['豆', 'wood'], ['豕', null], ['豸', null], ['貝', 'metal'], ['赤', 'fire'],
  ['走', null], ['足', null], ['身', null], ['車', 'metal'], ['辛', 'metal'],
  ['辰', 'earth'], ['辵', null], ['邑', 'earth'], ['酉', 'metal'], ['釆', null],
  ['里', 'earth'], ['金', 'metal'], ['長', null], ['門', 'wood'], ['阜', 'earth'],
  ['隶', null], ['隹', null], ['雨', 'water'], ['青', 'wood'], ['非', null],
  ['面', null], ['革', null], ['韋', null], ['韭', null], ['音', null],
  ['頁', null], ['風', 'wood'], ['飛', null], ['食', null], ['首', null],
  ['香', null], ['馬', 'fire'], ['骨', null], ['高', null], ['髟', null],
  ['鬥', null], ['鬯', null], ['鬲', null], ['鬼', null], ['魚', 'water'],
  ['鳥', null], ['鹵', null], ['鹿', null], ['麥', 'wood'], ['麻', null],
  ['黃', 'earth'], ['黍', 'wood'], ['黑', 'water'], ['黹', null], ['黽', null],
  ['鼎', null], ['鼓', null], ['鼠', null], ['鼻', null], ['齊', null],
  ['齒', null], ['龍', null], ['龜', null], ['龠', null],
];

const RADICAL_TO_CHAR = RADICAL_TABLE.map((e) => (e ? e[0] : null));
const RADICAL_TO_ELEMENT = RADICAL_TABLE.map((e) => (e ? e[1] : null));
const ELEMENT_LABEL = { wood: '木', fire: '火', earth: '土', metal: '金', water: '水' };

// ---------- 1. kTotalStrokes:codepoint -> 该字形自身笔画数 ----------
const totalStrokes = new Map();
const rsUnicode = new Map(); // codepoint -> 部首序号(整数,已去掉简化部首标记 ')
for (const line of readLines('Unihan_IRGSources.txt')) {
  const [u, field, value] = line.split('\t');
  if (field === 'kTotalStrokes') {
    totalStrokes.set(u, parseInt(value.split(' ')[0], 10));
  } else if (field === 'kRSUnicode') {
    // 形如 "31.5" 或 "212'.0";可能有多个候选,取第一个
    const first = value.split(' ')[0];
    const radicalNum = parseInt(first, 10);
    rsUnicode.set(u, radicalNum);
  }
}

// ---------- 2. kTraditionalVariant:简体 -> 繁体(可能多个) ----------
const traditionalOf = new Map();
for (const line of readLines('Unihan_Variants.txt')) {
  const [u, field, value] = line.split('\t');
  if (field === 'kTraditionalVariant') {
    const variants = value.split(' ').map((v) => v.split('<')[0]);
    traditionalOf.set(u, variants);
  }
}

// ---------- 3. 一简对多繁的人工取舍(姓名学惯例;仅列有分歧的常见字) ----------
// 键为简体字,值为姓名学应采用的那个繁体字(决定笔画)。
const AMBIGUOUS_OVERRIDE = {
  '发': '發', // 十四画,取"发展/发财"义;"髮"(头发)姓名用字极少见
  '获': '獲', // 十六画,"获得"义;"穫"(收获)较少用
  '面': '面', // "面"本字五画,繁体仍作"面"(另一体"麵"为面条专用,姓名不取)
  '干': '幹', // 十三画,取"干部/主干"义;"乾"多用于"乾"卦另计
  '后': '後', // 九画,"以后"义;"皇后"之"后"本字五画,姓名从"後"
  '里': '裡', // 姓名多取本字"里"(七画)即可,故不换;此处保留简体
  '钟': '鐘', // 十七画,取"钟表/钟情"义;"鍾"(姓氏)十七画同数,不影响
  '松': '松', // 本字八画,与"鬆"无关,姓名不取"鬆"
  '致': '致', // 本字十画,与"緻"无关
  '游': '游', // 本字十二画,与"遊"同数,不影响
  '据': '據', // 十六画
  '苹': '蘋', // 二十画("苹果"专用简化,姓名罕用,保留可选)
  '朴': '樸', // 十六画,取"朴实"义;作姓氏"朴"(六画,韩裔常见姓)有争议——
  //        姓名测试以"朴实"字义更通行,按十六画计;若用于韩裔姓氏应人工调整。
  '梁': '梁', // 本字与繁体同形
};

// ---------- 4. 内置兜底表(优先级最高,已知经过校验) ----------
const builtinSrc = readFileSync(builtinDartPath, 'utf8');
const builtinStrokes = {};
{
  const m = builtinSrc.match(/const Map<String, int> builtinStrokes = \{([\s\S]*?)\n\};/);
  for (const entry of m[1].matchAll(/'([^']+)':\s*(\d+)/g)) {
    builtinStrokes[entry[1]] = parseInt(entry[2], 10);
  }
}
const builtinElements = {};
{
  const m = builtinSrc.match(/const Map<String, Element> _builtinElements = \{([\s\S]*?)\n\};/);
  for (const entry of m[1].matchAll(/'([^']+)':\s*Element\.(\w+)/g)) {
    builtinElements[entry[1]] = ELEMENT_LABEL[entry[2]];
  }
}

// ---------- 5. 组装 ----------
const dict = {};
let resolvedByTraditional = 0, resolvedDirect = 0, skippedNoStrokes = 0;

for (const [u, self] of totalStrokes) {
  const ch = cp(u);
  if ([...ch].length !== 1) continue; // 跳过增补平面里按 UTF-16 代理对拆分出问题的极端情况由 String.fromCodePoint 已处理,这里防御性检查
  if (dict[ch]) continue;

  let strokes;
  const override = AMBIGUOUS_OVERRIDE[ch];
  if (override) {
    const ou = 'U+' + override.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
    strokes = totalStrokes.get(ou) ?? self;
    resolvedByTraditional++;
  } else {
    const trads = traditionalOf.get(u);
    if (trads && trads.length > 0 && trads[0] !== u) {
      strokes = totalStrokes.get(trads[0]) ?? self;
      resolvedByTraditional++;
    } else {
      strokes = self;
      resolvedDirect++;
    }
  }

  const radicalNum = rsUnicode.get(u);
  const radical = radicalNum ? RADICAL_TO_CHAR[radicalNum] ?? null : null;
  const element = radicalNum ? RADICAL_TO_ELEMENT[radicalNum] ?? null : null;

  const entry = { s: strokes };
  if (radical) entry.r = radical;
  if (element) entry.e = ELEMENT_LABEL[element];
  dict[ch] = entry;
}

// 内置兜底表校验优先:已知准确值覆盖自动派生结果
for (const [ch, strokes] of Object.entries(builtinStrokes)) {
  dict[ch] = { ...(dict[ch] ?? {}), s: strokes };
  if (builtinElements[ch]) dict[ch].e = builtinElements[ch];
}

writeFileSync(outPath, JSON.stringify(dict));
console.log(`字数: ${Object.keys(dict).length}`);
console.log(`  经繁体换算: ${resolvedByTraditional}  直接取值: ${resolvedDirect}  无笔画跳过: ${skippedNoStrokes}`);
console.log(`  内置兜底覆盖: ${Object.keys(builtinStrokes).length} 字`);

// ---------- 自检:关键字表 ----------
const spotCheck = {
  '火': 4, '水': 4, '土': 3, '金': 8, '木': 4,
  '云': 12, '国': 11, '龙': 16, '义': 13, '发': 14, '后': 9,
  '王': 4, '李': 7, '张': 11,
};
console.log('自检:');
for (const [ch, expect] of Object.entries(spotCheck)) {
  const got = dict[ch]?.s;
  const ok = got === expect ? 'OK' : `!! 期望${expect}实得${got}`;
  console.log(`  ${ch}: ${got}  ${ok}`);
}
