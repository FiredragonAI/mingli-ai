# 英文商店页(未就绪,**先别上传**)

文案已写好(title / short_description / full_description / changelogs),字数都在上限内。
截图素材在 `../play-en/`,是英文界面下的真机截图。

## 为什么还不能上传

英文界面里有一批内容仍然显示中文,截图上看得很清楚(见 `../play-en/07-almanac.png`):

- 黄历「宜 / 忌」的活动词条:造屋、嫁娶、祭祀、移徙、出行、开市、入宅……
- 二十八宿:柳土獐、角木蛟、亢金龙……(28 个全缺)
- 吉神凶煞:司命、天牢、玄武……
- 彭祖百忌整句:「壬不汲水,更难提防;辰不哭泣,必主重丧」
- 今日运势卡的话题标签:#责任 #规矩

来源是 `app/lib/core/almanac/almanac_rules.dart` 里硬编码的中文常量,
`app/lib/l10n/glossary.dart` 没有覆盖。**共 114 个中文词条,其中 95 个没有英文。**
UI 走的是 `s.text()`,它只做简繁转换,英文模式下原样透出中文。

另外 `01-today.png` 上「Avoid」徽标被截断成「Avo…」,英文比中文长,那个小方块装不下。

## 要做什么

1. 给这 95 个词条补英文(二十八宿、宜忌活动、神煞、彭祖百忌),加进 glossary.dart 或新建一张表;
2. 修「Avoid」徽标的溢出;
3. 重新打包、重拍英文截图;
4. 把本目录的 txt 和新截图移回 `app/android/fastlane/metadata/android/en-US/`,再跑 `play-release.cmd metadata`。

这些是面向用户的内容翻译,术语译法需要你拍板,所以没有代写。
