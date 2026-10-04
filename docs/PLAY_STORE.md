# 上架 Google Play —— 逐步操作手册

应用:**知命 · FateCode**(包名 `io.cspeed.mingli_ai`)

产物和素材都已经备好,这份文档是你在 Play Console 里逐屏要填的东西。
**上传和发布必须由你本人操作**——注册开发者账号、付费、用你的 Google 账号登录、点"发布",这些我不会代做。

> 政策细节 Google 会调整。文档里的数字(测试人数、天数、审核时长)以**你自己 Play Console 页面上显示的要求为准**,这里写的是写作时的情况。

---

## 素材清单(现在就能用)

| 东西 | 位置 | 状态 |
|---|---|---|
| 应用包(AAB) | `app/build/app/outputs/bundle/release/app-release.aab` | ✅ 104.9 MB,versionCode 1 |
| 应用图标 512×512 | `app/store/icon-512.png` | ✅ 星轨罗盘,32 位 PNG,无透明像素 |
| 功能图片 1024×500 | `app/store/feature-1024x500.png` | ✅ 24 位 PNG,无 alpha 通道 |
| 手机截图 ×8 | `app/store/play-zh/01…08-*.png` | ✅ 1080×2400,**2026-10-03 新拍**,新名字新图标,含 SBTI |
| 备用截图 | `app/store/play-zh/extra/` | 四柱命盘页、SBTI 介绍页,想换时用 |
| 隐私政策网址 | https://firedragonai.github.io/mingli-ai/privacy-policy.html | ✅ 已在线 |
| 商店文案 | 本文第 5 节 | ✅ 中英各一份 |
| 上传密钥 | `C:\Users\boadb\mingli-upload-keystore.jks` + `app/android/key.properties` | ⚠️ **立刻备份,见第 1 节** |

截图顺序(商店页从左到右就是这个顺序):

1. `01-today.png` 今日运势 + 七个功能入口
2. `02-input.png` 出生信息录入(真太阳时、时辰三选)
3. `03-chart-radar.png` 五行雷达 + 喜忌
4. `04-annual.png` 流年运势 + 十二流月
5. `05-marriage.png` 我的婚缘
6. `06-name.png` 姓名测试五格
7. `07-almanac.png` 黄历
8. `08-sbti.png` SBTI 性格测试结果

> 建议:`08-sbti.png` 是最容易让人点进来的一张(卡通形象 + 稀有度 4%),
> 而商店页首屏只露前三张。想要转化率,把它改名成 `02`、其余顺延即可——换个文件名的事。

---

## 0. 先决条件(你来做)

| 事项 | 说明 |
|---|---|
| Google 账号 | 用你要长期持有的那个,账号丢了 app 就转不走 |
| 开发者注册费 | **$25 一次性**,终身有效 |
| 身份验证 | 个人开发者需上传身份证件,Google 人工审核(1–3 天,偶尔更久) |
| 设备验证 | 见 0.1,**需要一台真 Android 手机** |
| 隐私政策 URL | 已就绪,见上表 |
| D-U-N-S 号码 | 仅**企业**账号需要;个人账号不需要 |

注册入口:<https://play.google.com/console/signup>

### 0.1 设备验证(注册后会立刻卡住的一屏)

Play Console 要求你证明"拥有一台 Android 设备":装 **Google Play Console 手机版** → 用注册时的同一个 Google 账号登录 → 选中你的开发者账号 → 按提示完成。

**模拟器这条路已经试过,Google 拒绝了**——它读 `ro.build.characteristics=emulator` 就判定不是真机。伪造这个属性是绕过 Google 的身份校验,我不会做,你也不该做(被发现是封号级别的事)。

可行的办法,按可靠性排序:

1. **借一台 Android 手机,五分钟**——最稳。装 Play Console app,用**自己的**账号登录,验证完退出登录。
   验证只证明"这个账号能碰到一台真设备",**不会把开发者账号绑定到那台手机**,也不在别人机器上留东西。
2. **买台二手 Android 机(几百块)**——正式发布前本来就该在真机上过一遍手相/面相和分享功能,这钱不算白花。

### 0.2 个人账号的封闭测试门槛

个人开发者账号在能发布**正式版**之前,需要先跑一轮**封闭测试**:招满一定数量的测试者(写作时是 **12 人**),并且他们要**连续 14 天**保持加入状态。企业账号没有这一条。

这意味着真实时间线大概是:

```
注册 + 身份验证(1–3 天)
  → 设备验证(借到手机就是五分钟)
  → 建应用、填完所有表单、上传 AAB(半天)
  → 内部测试:自己装上真机验一遍(当天)
  → 封闭测试:拉满 12 人 × 连续 14 天
  → 申请正式版权限 → 审核(1–7 天)
  → 上线
```

**从今天算,最快也要三周左右**,其中 14 天是硬等待。所以:**先把封闭测试跑起来**,别等素材完美了再开始。

---

## 1. 上传密钥——现在就备份

```
C:\Users\boadb\mingli-upload-keystore.jks      ← 密钥库
app/android/key.properties                     ← 密码
```

> ⚠️ **立刻把这两个文件复制到别处(网盘、U 盘、密码管理器)。**
> 弄丢上传密钥,你就无法给这个应用发布任何更新——只能换包名重新上架,已有用户全部丢失。
> 这两个文件都在 `.gitignore` 里,**git 不是你的备份**。
>
> 在 Play Console 里保持 **Play App Signing 默认开启**(推荐)。这样应用签名密钥由 Google 托管,
> 万一上传密钥丢了还能向 Google 申请重置,不至于彻底没救。

---

## 2. 一个要先定的事:这版要不要带云端 AI

现在的 AAB 是**纯离线版**:编译时没有注入服务器地址,所有解读由本机规则引擎生成。
「更多 AI 解读」那张卡会自动灰掉并给出提示,**不会报错、不会崩**——这是设计好的降级行为。

| | 纯离线版(当前 AAB) | 带云端 AI 版 |
|---|---|---|
| 八字/运势/黄历等全部功能 | ✅ 正常 | ✅ 正常 |
| AI 解读文字 | 本机规则引擎 | Gemini 生成 |
| 「更多 AI 解读」卡 | 灰掉 | ✅ 可用 |
| 数据安全表单 | **"不收集任何数据"**,几分钟填完 | 要如实申报,见第 3 节 |
| 服务器成本 | 0 | Render free 档会休眠,首个请求慢几十秒 |

**建议首次上架用纯离线版**:表单最简单、审核风险最低、没有服务器拖后腿。
等上线稳定了,再发一版带云端的更新。

想做带云端 AI 的版本,自己在终端跑(**口令从 Render 面板 → mingli-server → Environment → `APP_TOKEN` 复制,不要贴进聊天或仓库**):

```bash
cd app && flutter build appbundle --release --dart-define=MINGLI_API_URL=https://mingli-server.onrender.com --dart-define=MINGLI_APP_TOKEN=粘贴APP_TOKEN的值
```

服务器状态可随时查:<https://mingli-server.onrender.com/healthz>

---

## 3. 数据安全表单

Play Console → **政策 → 应用内容 → 数据安全**。

### 3.1 纯离线版(推荐,当前 AAB)

| 问题 | 答案 |
|---|---|
| 您的应用是否收集或分享任何必需的用户数据类型? | **否** |

答"否"之后整张表就结束了。这与应用实际行为一致:出生信息只写在手机本地的
shared_preferences 里,照片只在设备上分析完即丢弃,没有账号、不联网。

### 3.2 带云端 AI 版

| 问题 | 答案 |
|---|---|
| 是否收集或分享用户数据? | **是** |
| 传输过程是否加密? | **是**(HTTPS) |
| 是否提供删除数据的方式? | **是**——卸载或在设置里删除档案即清空本机数据;服务端不保存可识别到个人的数据 |

逐项:

| 数据类型 | 收集? | 说明 |
|---|---|---|
| 姓名 | **否** | 只存本机,从不上传 |
| 电子邮件地址 | 否 | 无账号系统 |
| 用户 ID | **是**,不分享,用途**应用功能**(限流防滥用);"临时处理"❌;"可请求删除"✅ | 随机生成的设备编号,非广告 ID,卸载重装即更换 |
| 位置 | **否** | 出生地是用户手选的省份,只存本机 |
| 照片 | **否** | 仅在设备上处理、不传输、不保存。Google 的规则是"仅在设备本地处理且不离开设备的数据不算收集" |
| 应用活动 → 其他用户生成的内容 | **是**,不分享,用途**应用功能**,可请求删除 ✅ | 指发给 AI 的结构化盘面数据(干支、五行占比、评分),不含姓名生日,保守起见如实申报 |
| 崩溃日志/诊断 | 否 | 未集成任何崩溃统计 SDK |
| 设备或其他 ID | 否 | 用的是自己生成的随机编号,已在"用户 ID"里申报;不读 IMEI/Android ID/广告 ID |

"照片"那项如果审核追问,在说明框里填:

> 手相/面相功能使用设备端的 MediaPipe 模型分析用户主动选择的照片。照片在应用进程内存中处理后即被丢弃,不写入应用存储、不上传至任何服务器。仅提取无法逆向还原的几何比例数值(如三停比例、掌宽比)。本应用不进行人脸识别、不建立生物特征模板、不做身份比对。

---

## 4. 内容分级、目标受众、广告、应用访问权限

**内容分级**(政策 → 应用内容 → 内容分级):类别选 **"参考、新闻或教育"** 或 **"娱乐"**。

| 问题 | 答案 |
|---|---|
| 暴力、血腥 | 否 |
| 性内容、裸露 | 否 |
| 粗俗语言 | 否 |
| 受管制物质 | 否 |
| **模拟赌博 / 现实赌博** | **否**(无任何投注、抽奖、付费抽取) |
| 用户可以互相交流 | 否 |
| 分享用户位置 | 否 |
| 允许购买数字商品 | 否(当前版本无内购) |

分级结果预计 **12+ / Teen** 左右。

**目标受众和内容**:勾选 **18 岁及以上**(应用含婚恋、感情主题)。
**不要**勾任何 13 岁以下年龄段,否则触发"面向儿童的应用"政策,要求严得多。
"您的应用是否会吸引儿童?" → **否**。

**广告**:选 **"不含广告"**。
**应用访问权限**:选 **"所有功能均可使用,无需特殊访问权限"**(没有登录墙)。
**政府应用**:否。**金融功能**:否。**健康应用**:否(重要,别选)。

---

## 5. 商店详情文案

### 应用名称(30 字符内)
- 中文:`知命 - 八字命盘与性格测试`
- English:`FateCode — BaZi Chart & Fortune`

> 上架前先在 Play 商店搜一下"知命",确认没有同名应用抢占心智或引起混淆。

### 简短说明(80 字符内)
- 中文:`专业八字排盘,天文级精度。每日运势、流年、合婚、姓名、黄历、SBTI 性格测试。`
- English:`Astronomy-grade BaZi charts, daily fortune, compatibility, and the SBTI quiz.`

### 完整说明(4000 字符内,中文)

```
知命 是一款把传统命理算得准、讲得明白的工具。

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
· SBTI 性格测试 — 15 道三选一,21 种人设,配原创卡通形象,结果可生成海报分享
· 手相 / 面相 — 照片只在手机上分析,不上传、不保存

【解读风格】
专业术语第一次出现就配大白话解释,每段配一个生活化的比喻。既说得出"为什么"(每条结论都能追溯到命盘依据),又不端着架子。部分解读文字由 AI 生成。

【隐私】
· 没有账号,不要手机号,不要邮箱
· 出生信息只存在你的手机里
· 手相面相的照片在设备端分析后立即丢弃,不上传、不做人脸识别
· 可在设置中开启"始终离线",应用将完全不联网

【声明】
本应用内容基于中国传统文化整理,仅供娱乐与文化参考,不构成任何医疗、法律、投资或婚恋建议,亦不具备科学预测能力。SBTI 性格测试纯属玩梗,不构成任何人格评价或心理测评。请勿据此作出重大人生决策。
```

### 完整说明(English)

```
FateCode computes Chinese BaZi (Four Pillars) astrology with real astronomical precision — and explains it in plain language.

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
· SBTI — a 15-question personality quiz with 21 original illustrated types and a shareable poster
· Palm & Face — photos analysed entirely on device, never uploaded

PRIVACY
No accounts. No phone number. No email. Birth details stay on your device. Palm and face photos are analysed on-device and discarded immediately — never uploaded, and no facial recognition is performed. A settings switch makes the app fully offline.

DISCLAIMER
Content is compiled from Chinese traditional culture for entertainment and cultural reference only. It is not medical, legal, financial or relationship advice and has no scientific predictive validity. Some interpretation text is AI-generated. The SBTI quiz is a joke format, not a psychological assessment.
```

### 分类与标签
- 应用类别:**生活时尚(Lifestyle)**
- 标签:命理、八字、运势、黄历、星座、性格测试 / astrology, fortune, lifestyle, personality

---

## 6. 上传步骤(按顺序做)

### 第 1 步 · 创建应用
Play Console → **所有应用 → 创建应用**
- 应用名称:`知命 - 八字命盘与性格测试`
- 默认语言:**简体中文(zh-CN)**(上线后可再加 English、繁體中文)
- 应用或游戏:**应用**
- 免费或付费:**免费**(⚠️ 免费改付费不可逆,付费可以改免费)
- 勾选开发者计划政策与美国出口法规两个声明

### 第 2 步 · 填完"应用内容"里的每一项
左侧 **政策 → 应用内容**。每一项都是必填,没填完不能提交审核:
- 隐私政策 → 填 `https://firedragonai.github.io/mingli-ai/privacy-policy.html`
- 广告 → 不含广告
- 应用访问权限 → 所有功能均可使用
- 内容分级 → 按第 4 节答问卷
- 目标受众和内容 → 18 岁及以上
- 新闻应用 → 否
- 新冠接触者追踪 → 否
- 数据安全 → 按第 3 节
- 政府应用 / 金融功能 / 健康 → 都是否

### 第 3 步 · 先发内部测试
左侧 **测试 → 内部测试 → 创建新版本**
- **Play App Signing:保持默认开启**
- 上传 `app/build/app/outputs/bundle/release/app-release.aab`
- 版本名称:`0.1.0 (1)`;版本说明:`首个版本`
- 建一个测试者名单,把自己的 Gmail 加进去 → 保存 → 发布

内部测试几乎不用审核,链接发给自己,在**真机**上装一遍,重点验:
启动、建档案排盘、今日运势、SBTI 测完能生成海报并分享、手相/面相选图、黄历翻页。

### 第 4 步 · 商店详情
左侧 **增长 → 商店发布 → 主要商店详情**,按第 5 节填文案,上传:
- 应用图标 ← `app/store/icon-512.png`
- 功能图片 ← `app/store/feature-1024x500.png`
- 手机截图 ← `app/store/play-zh/01…08-*.png`(按编号顺序拖进去)

### 第 5 步 · 封闭测试(个人账号必经)
左侧 **测试 → 封闭测试 → 创建新版本**,用同一个 AAB。
招满要求人数的测试者(微信群、朋友、同事都算,要他们**用 Gmail 加入并保持 14 天**),
然后**老老实实等满 14 天**。中途有人退出会重新计时,所以多拉几个人留余量。

### 第 6 步 · 申请正式版权限 → 发布
满足条件后 Play Console 会出现"申请正式版访问权限"的入口,填一份关于测试情况的问卷。
通过后:左侧 **正式版 → 创建新版本** → 上传 AAB → **提交审核**。
首次审核通常 1–7 天。

---

## 7. 这个应用特有的审核风险

| 风险点 | 状态 | 建议 |
|---|---|---|
| **占卜/算命类内容** | Google Play 允许,不像国内商店那样禁止 | 商店文案里已有免责声明,保留它;不要写"预测未来""改运""化解"这类措辞 |
| **相机权限** | 已声明为非必需(`required="false"`) | 审核若问用途,答:用户主动使用手相/面相功能时拍照,照片仅在设备端分析 |
| **照片/生物特征** | 端侧处理、不上传 | 按 3.2 的说明填。**不要**在任何文案里用"人脸识别"字样,我们做的是几何比例测量 |
| **健康声明** | 解读文字已过滤疾病/死亡类表述 | 不要在商店文案里提健康、治疗、疾病 |
| **AI 生成内容** | 需在文案中说明 | 完整说明里已写"部分解读文字由 AI 生成" |
| **SBTI 像心理测评** | 文案和应用内都写了"纯属玩梗,不构成人格评价或心理测评" | 保留这句话,别改成"科学测评" |
| **targetSdk** | 36,满足 2026 年要求 | — |

---

## 8. 后续更新怎么发

改完代码:

```bash
cd app && flutter build appbundle --release
```

每次发版要在 `app/pubspec.yaml` 把 `version: 0.1.0+1` 的 **build number(加号后面那位)递增**,
否则 Play Console 会拒绝("版本代码已存在")。然后在 Play Console 创建新版本、上传新 aab。

重拍商店截图:模拟器装上 release APK,用 `adb exec-out screencap -p > xx.png`。
状态栏要干净就先开演示模式:

```bash
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0900
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
```
