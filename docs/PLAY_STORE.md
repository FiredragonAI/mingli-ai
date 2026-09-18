# 上架 Google Play

产物已经构建好,这份文档是你在 Play Console 里逐屏要填的东西。**上传和发布必须由你本人操作**——注册开发者账号、付费、用你的 Google 账号登录、点"发布",这些我不会代做。

---

## 0. 先决条件(你来做,约 30 分钟 + 审核等待)

| 事项 | 说明 |
|---|---|
| Google 账号 | 用你要长期持有的那个,账号丢了 app 就转不走 |
| 开发者注册费 | **$25 一次性**,终身有效 |
| 身份验证 | 个人开发者需上传身份证件,Google 会人工审核(1–3 天,偶尔更久) |
| 隐私政策 URL | 见下面第 2 节,**必填**,没有它无法提交 |
| D-U-N-S 号码 | 仅**企业**账号需要;个人账号不需要 |

注册入口:<https://play.google.com/console/signup>

> **个人 vs 企业账号**:2023 年起个人开发者账号在正式发布前需要通过"封闭测试"阶段(至少 12 名测试者持续 14 天)。企业账号没有这个要求。如果你打算认真运营,注册企业账号(需要 D-U-N-S)能省掉这一步。


### 0.1 设备验证(注册后会立刻卡住的一屏)

Play Console 会要求你"验证拥有一台 Android 设备":装 **Google Play Console 手机版** → 用注册时的同一个 Google 账号登录 → 选中你的开发者账号 → 按提示完成。

用户没有 Android 手机,按可靠性排序:

1. **借一台 Android 手机,五分钟**——最稳。装 Play Console app,用**自己的**账号登录,验证完退出登录。验证只证明"这个账号能碰到一台真设备",**不会把开发者账号绑到那台手机上**,也不在别人机器上留东西。
2. **带 Google Play 商店的模拟器**——AVD `play_verify`(`system-images;android-36;google_apis_playstore;x86_64`,Pixel 7,config.ini 里手动改 `PlayStore.enabled=yes`,avdmanager 命令行不会自动设)。**Google 不保证认模拟器**,有人成功有人被拒,值得先试。注意:普通 `google_apis` 镜像没有 Play 商店,装不了 Play Console app。
3. **买台二手 Android 机**——正式发布前本来就该在真机上过一遍,这钱不算白花。

---

## 1. 产物在哪

```
app/build/app/outputs/bundle/release/app-release.aab
```

这就是上传到 Play Console 的文件(AAB,不是 APK)。

**签名密钥在 `C:\Users\boadb\mingli-upload-keystore.jks`,密码在 `app/android/key.properties` 里。**

> ⚠️ **立刻备份这两个文件到别的地方(网盘、U 盘、密码管理器)。**
> 弄丢上传密钥,你就无法给这个应用发布任何更新——只能用新的包名重新上架,已有用户全部丢失。
> 这两个文件都已加入 `.gitignore`,不会进 git,所以 git 不是你的备份。
>
> 好消息:如果你在 Play Console 开启了 **Play App Signing**(默认开启、推荐),上传密钥万一丢失还可以向 Google 申请重置,不至于彻底没救。但应用签名密钥由 Google 托管,那个是绝对不能丢的——所以务必让 Google 托管,别自己管。

---

## 2. 隐私政策(必填,先做这一步)

**已经在线,不用再手动托管**:`.github/workflows/pages.yml` 每次推 main 都会把 `docs/privacy-policy.html` 和网页版一起发到 GitHub Pages。

Play Console 里填这个 URL:

```
https://wanghuolei-dotcom.github.io/mingli-ai/privacy-policy.html
```

网页版本体在同一站点根:<https://wanghuolei-dotcom.github.io/mingli-ai/>。改隐私政策只需改 `docs/privacy-policy.html` 推上去,几分钟后生效。

> 站点是从仓库 `wanghuolei-dotcom/mingli-ai`(公开)自动构建的。密钥(`key.properties`、`.jks`、`server/.env`)都在 `.gitignore` 里,历史中也从未出现过——推送前核查过。


---

## 3. 数据安全表单(最容易填错的一屏)

Play Console → 政策 → **应用内容 → 数据安全**。逐项答案如下,这些答案与应用实际行为一致:

### 3.1 总述

| 问题 | 答案 |
|---|---|
| 您的应用是否收集或分享任何必需的用户数据类型? | **是**(仅当启用云端解读;见下) |
| 您应用收集的所有用户数据在传输过程中是否都会加密? | **是**(HTTPS) |
| 您是否提供让用户请求删除其数据的方式? | **是**——卸载应用或在设置中删除档案即可删除设备上全部数据;服务端不保存可识别到个人的数据 |

### 3.2 数据类型逐项

| 数据类型 | 是否收集 | 说明 |
|---|---|---|
| 姓名 | **否** | 仅存本机,从不上传 |
| 电子邮件地址 | 否 | 无账号系统 |
| 用户 ID | **是** → 收集,不分享;用途:**应用功能**(限流防滥用)。勾选"数据是临时处理的"❌ 否;"用户可以请求删除"✅ | 随机生成的设备编号,非广告 ID,卸载重装即更换 |
| 位置(大致/精确) | **否** | 出生地是用户手动选的省份,只存本机、不上传 |
| 照片 | **否** | ⬅ 关键:照片仅在设备上处理、不传输、不保存。Google 的规则是"仅在设备本地处理且不离开设备的数据,不算收集" |
| 相机(作为权限) | 权限声明即可,数据类型里**不勾** | |
| 应用活动 → 其他用户生成的内容 | **是** → 收集,不分享;用途:**应用功能**;可请求删除 ✅ | 指发送给 AI 的结构化盘面数据(干支、五行占比、评分)。这不含姓名生日,但保守起见如实申报 |
| 应用信息和性能 → 崩溃日志/诊断 | 否 | 未集成任何崩溃统计 SDK |
| 设备或其他 ID | 否 | 我们用的是自己生成的随机编号,已在"用户 ID"里申报;不读取 IMEI/Android ID/广告 ID |

> **如果你选择只发布纯离线版**(编译时不带 `MINGLI_API_URL`),那么第一题可以直接答"**否,不收集**",整个表单几分钟填完。这是最省事的上架路径,也最不容易出问题——建议首次上架就这么做,等你把后端部署稳定了,再发一版带云端功能的更新。

### 3.3 照片那一项的补充说明(如果审核问起)

在"数据安全"里有可选的说明框,建议填:

> 手相/面相功能使用设备端的 MediaPipe 模型分析用户主动选择的照片。照片在应用进程内存中处理后即被丢弃,不写入应用存储、不上传至任何服务器。仅提取无法逆向还原的几何比例数值(如三停比例、掌宽比)。本应用不进行人脸识别、不建立生物特征模板、不做身份比对。

---

## 4. 内容分级问卷

Play Console → 政策 → **应用内容 → 内容分级**。类别选 **"参考、新闻或教育"** 或 **"娱乐"**。

关键问答:

| 问题 | 答案 |
|---|---|
| 暴力、血腥 | 否 |
| 性内容、裸露 | 否 |
| 粗俗语言 | 否 |
| 受管制物质(毒品/烟酒) | 否 |
| **模拟赌博 / 现实赌博** | **否**(本应用无任何投注、抽奖、付费抽取机制) |
| 用户可以互相交流 | 否 |
| 分享用户位置 | 否 |
| 允许购买数字商品 | 否(当前版本无内购) |

分级结果预计为 **12+ / Teen** 左右。

### 目标受众和内容
- 目标年龄段:勾选 **18 岁及以上**(应用含婚恋、感情主题)。
- **不要**勾选任何 13 岁以下年龄段,否则会触发"面向儿童的应用"政策,要求更严(禁止收集任何标识符等)。
- "您的应用是否会吸引儿童?" → 否。

---

## 5. 商店详情文案

### 应用名称(50 字符内)
- 中文:`命理师 AI - 八字命盘与每日运势`
- English:`Mingli AI — BaZi Chart & Daily Fortune`

### 简短说明(80 字符内)
- 中文:`专业八字排盘,天文级精度。每日运势、流年、合婚、姓名、黄历,离线可用。`
- English:`Astronomy-grade BaZi charts, daily fortune, annual luck, compatibility — works offline.`

### 完整说明(4000 字符内,中文版)

```
命理师 AI 是一款把传统命理算得准、讲得明白的工具。

【排盘精度】
· 二十四节气用 VSOP87 天文算法实时推算,精确到分钟,与《中国天文年历》一致
· 农历采用定朔定气,正确处理 2033 年等历法难题
· 真太阳时校正:按出生地经度与均时差还原当地时辰,乌鲁木齐与北京相差两小时以上
· 所有推算在你的手机上完成,不依赖网络

【功能】
· 今日运势 — 每天的分数、主题、宜忌、吉时,以及"今天别做的一件事"
· 八字命盘 — 四柱、藏干、十神、神煞、五行雷达图、大运时间轴
· 流年运势 — 今年运程、犯太岁提醒、十二流月走势
· 我的婚缘 — 不用填对方信息,看配偶星、夫妻宫、婚期窗口
· 合婚 — 两人八字六维匹配 + 星座配对
· 星座 — 太阳星座与上升星座(按回归黄道严格推算,换宫日也准)
· 姓名测试 — 五格剖象,内置 10 万字康熙笔画字典
· 黄历 — 建除、值神、二十八宿、宜忌、彭祖百忌
· 手相 / 面相 — 照片只在手机上分析,不上传、不保存

【解读风格】
专业术语第一次出现就配大白话解释,每段配一个生活化的比喻。既说得出"为什么"(每条结论都能追溯到命盘依据),又不端着架子。

【隐私】
· 没有账号,不要手机号,不要邮箱
· 出生信息只存在你的手机里
· 手相面相的照片在设备端分析后立即丢弃,不上传、不做人脸识别
· 可在设置中开启"始终离线",应用将完全不联网

【声明】
本应用内容基于中国传统文化整理,仅供娱乐与文化参考,不构成任何医疗、法律、投资或婚恋建议,亦不具备科学预测能力。请勿据此作出重大人生决策。
```

### 完整说明(English)

```
Mingli AI computes Chinese BaZi (Four Pillars) astrology with real astronomical precision — and explains it in plain language.

ACCURACY
· The 24 solar terms are computed live with the VSOP87 planetary theory, accurate to the minute
· True lunar calendar using actual new moons and solar terms, handling edge cases like the 2033 leap month
· True solar time correction by birth longitude and the equation of time
· Everything is computed on your device — no network required

FEATURES
· Today — daily score, theme, do & avoid, auspicious hours, and one thing not to do today
· BaZi chart — four pillars, hidden stems, Ten Gods, symbolic stars, element radar, luck-cycle timeline
· Year ahead — annual fortune, Tai Sui alerts, month-by-month trend
· My romance — spouse star, marriage palace and timing windows, no partner data needed
· Compatibility — six-dimension match plus zodiac pairing
· Zodiac — sun and rising signs computed from the tropical ecliptic, accurate even on cusp days
· Name analysis — five-grid method with a 100k-character Kangxi stroke dictionary
· Almanac — officers of the day, 28 mansions, do & avoid
· Palm & Face — photos analysed entirely on device, never uploaded

PRIVACY
No accounts. No phone number. No email. Birth details stay on your device. Palm and face photos are analysed on-device and discarded immediately — never uploaded, and no facial recognition is performed. A settings switch makes the app fully offline.

DISCLAIMER
Content is compiled from Chinese traditional culture for entertainment and cultural reference only. It is not medical, legal, financial or relationship advice and has no scientific predictive validity.
```

### 分类与标签
- 应用类别:**生活时尚(Lifestyle)**
- 标签:命理、八字、运势、黄历、星座 / astrology, fortune, lifestyle

---

## 6. 素材规格

| 素材 | 规格 | 状态 |
|---|---|---|
| 应用图标 | 512×512 PNG,32 位,无 alpha | ⚠️ **待做**——现在是 Flutter 默认图标 |
| 功能图片(Feature graphic) | 1024×500 PNG/JPG,无 alpha | ⚠️ **待做**,必填 |
| 手机截图 | 至少 2 张,最多 8 张;16:9 或 9:16,每边 320–3840 px | ⚠️ **待做** |
| 平板截图 | 可选 | — |

**截图怎么取**:接上 Android 手机(开发者模式 + USB 调试)后

```bash
cd app && flutter run --release
```

在手机上逐屏截图(电源键+音量下),或用 `adb exec-out screencap -p > shot1.png`。建议这五张:今日页、八字命盘、流年(带犯太岁提醒)、我的婚缘、黄历。

**没有 Android 手机的话**:用模拟器。需要额外装系统镜像:

```bash
sdkmanager "system-images;android-36;google_apis;x86_64" "emulator"
avdmanager create avd -n pixel -k "system-images;android-36;google_apis;x86_64" -d pixel_7
emulator -avd pixel
```

图标和功能图片建议找设计做,或用 Canva 套模板——这两张是商店页的第一印象,值得花时间。

---

## 7. 上传步骤

1. 登录 <https://play.google.com/console> → **创建应用**
   - 应用名称:`命理师 AI`
   - 默认语言:简体中文(之后可添加英文、繁体中文本地化)
   - 应用或游戏:**应用**;免费或付费:**免费**
2. 左侧 **政策 → 应用内容**,依次完成:隐私政策 URL、广告(选"否")、应用访问权限(选"所有功能均可使用,无需特殊访问权限")、内容分级、目标受众、数据安全(照第 3、4 节填)
3. 左侧 **发布 → 正式版**(或先走 **内部测试**,强烈建议)→ 创建新版本
   - 上传 `app-release.aab`
   - Play App Signing:**保持默认开启**
   - 版本说明:`首个版本`
4. 填 **商店详情**:名称、简短说明、完整说明、图标、功能图片、截图(第 5、6 节)
5. 提交审核。首次审核通常 1–7 天。

> **强烈建议先发内部测试版**:内部测试不需要审核(或极快),最多 100 人,你可以自己先装上真机验证手相面相、AI 解读是否正常,再转正式版。直接发正式版一旦有问题,修复要重新排队审核。

---

## 8. 这个应用特有的审核风险

| 风险点 | 状态 | 建议 |
|---|---|---|
| **占卜/算命类内容** | Google Play 允许,不像国内商店那样禁止 | 商店文案里已有免责声明,保留它;不要写"预测未来""改运""化解"这类措辞 |
| **相机权限** | 已声明为非必需(`required="false"`) | 审核若问用途,答:用户主动使用手相/面相功能时拍照,照片仅在设备端分析 |
| **照片/生物特征** | 端侧处理、不上传 | 数据安全表单按第 3.3 节填写说明。**不要**在任何文案里用"人脸识别"字样,我们做的是几何比例测量 |
| **健康声明** | 解读文字已过滤疾病/死亡类表述 | 不要在商店文案里提健康、治疗、疾病 |
| **AI 生成内容** | 需在文案中说明 | 完整说明里已写"解读文字由 AI 生成" |
| **targetSdk** | 36,满足 2026 年要求 | — |

---

## 9. 后续更新怎么发

改完代码后:

```bash
cd app && flutter build appbundle --release
```

每次发版要在 `app/pubspec.yaml` 里把 `version: 0.1.0+1` 的 **build number(加号后面那位)递增**,否则 Play Console 会拒绝("版本代码已存在")。然后在 Play Console 创建新版本、上传新的 aab 即可。

带云端 AI 的版本:

```bash
flutter build appbundle --release --dart-define=MINGLI_API_URL=https://你的地址 --dart-define=MINGLI_APP_TOKEN=你的口令
```
