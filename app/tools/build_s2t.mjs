// 生成 assets/data/s2t.json —— 简体 → 繁体 单字映射,从 Unicode Unihan 派生。
//
// 用法:node build_s2t.mjs <unihan目录> <输出json>
//
// 规则:取 kTraditionalVariant 里第一个"不是自身"的候选;只有自身的不收录。
// 一简对多繁的歧义字(干/后/里/面/发/系……)在 lib/l10n/s2t.dart 的 charOverrides
// 与 phraseOverrides 里人工裁定,这里不做判断,保持数据与决策分离。

import { readFileSync, writeFileSync } from 'node:fs';

const [, , unihanDir, outPath] = process.argv;
if (!unihanDir || !outPath) {
  console.error('用法: node build_s2t.mjs <unihan目录> <输出json>');
  process.exit(1);
}

const cp = (u) => String.fromCodePoint(parseInt(u.slice(2), 16));
const lines = readFileSync(`${unihanDir}/Unihan_Variants.txt`, 'utf8')
  .split('\n')
  .filter((l) => l && !l.startsWith('#'));

const map = {};
let ambiguous = 0;
for (const line of lines) {
  const [u, field, value] = line.split('\t');
  if (field !== 'kTraditionalVariant') continue;
  const variants = value.split(' ').map((v) => v.split('<')[0]).filter((v) => v !== u);
  if (variants.length === 0) continue;
  const simp = cp(u);
  // 只收基本平面常用字,增补平面的罕见字用不上还会撑大文件
  if (simp.codePointAt(0) > 0xffff) continue;
  const trad = cp(variants[0]);
  if (trad.codePointAt(0) > 0xffff) continue;
  map[simp] = trad;
  if (variants.length > 1) ambiguous++;
}

writeFileSync(outPath, JSON.stringify(map));
console.log(`收录 ${Object.keys(map).length} 字,其中一简多繁 ${ambiguous} 字(由 s2t.dart 人工裁定)`);

const spot = { 云: '雲', 国: '國', 龙: '龍', 双: '雙', 历: null, 干: null, 后: null, 发: null, 黄: '黃', 历: null };
for (const [s, t] of Object.entries(spot)) {
  console.log(`  ${s} → ${map[s] ?? '(无)'}${t && map[s] !== t ? '  !! 期望 ' + t : ''}`);
}
