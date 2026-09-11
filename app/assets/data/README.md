# 数据文件

## kangxi_strokes.json

康熙字典笔画字典,约 10.3 万字,格式:

```json
{ "王": {"s": 4, "r": "玉", "e": "土"}, "李": {"s": 7, "r": "木", "e": "木"} }
```

- `s` 康熙笔画(必填)
- `r` 部首(用于生肖用字宜忌,选填)
- `e` 字义五行(木火土金水,由部首粗略归类,仅供参考,选填)

程序启动时自动加载(见 `lib/main.dart`)。未放置时回退到 `stroke_dictionary.dart`
内置的 ~350 字常用兜底表。

### 生成方式

由 `tools/build_kangxi_dict.mjs` 从 [Unicode Unihan 数据库](https://www.unicode.org/reports/tr38/)
派生生成,而非直接照抄某家简体笔画表——姓名学的"康熙笔画"要求先把简体字换算成
繁体字形再数笔画(如"云"按"雲"计 12 画,而非"云"本身的 4 画),脚本对每个简体字
查 `kTraditionalVariant` 换算后取 `kTotalStrokes`。极少数"一简对多繁"的字
(发/干/后等)由脚本内的人工对照表裁定,已知校验过的常用姓氏/用字(见
`stroke_dictionary.dart` 的 `builtinStrokes`)优先于自动派生结果。

重新生成(需要 Node.js 与联网下载 Unihan.zip):

```bash
curl -o /tmp/unihan.zip https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
unzip -o /tmp/unihan.zip -d /tmp/unihan Unihan_IRGSources.txt Unihan_Variants.txt
node tools/build_kangxi_dict.mjs /tmp/unihan lib/core/naming/stroke_dictionary.dart assets/data/kangxi_strokes.json
```

数据许可:Unicode Character Database,遵循
[Unicode 数据文件许可](https://www.unicode.org/license.txt)。
