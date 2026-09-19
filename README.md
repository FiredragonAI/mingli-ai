# 命理师 AI

八字 · 五行 · AI 解读 · 每日运势 · 合婚 · 姓名测试 · 黄历 · 星座 · 手相/面相

**平台**:Android + iOS + Windows + Web(Flutter 单一代码库)
**网页版**:<https://firedragonai.github.io/mingli-ai/> —— 手机/电脑浏览器直接打开,宽屏自动切桌面布局。手相/面相依赖端侧模型,为原生 app 专属,网页版不显示该入口。

**AI**:自建 Node 后端代理 Claude API,客户端不持有密钥
**影像**:手相/面相在**设备端**提取几何特征,原始照片不出设备

---

## 目录结构

```
mingli-ai/
├── app/                      Flutter 客户端(Android / iOS / Windows / Web)
│   ├── lib/
│   │   ├── core/             命理引擎(纯 Dart,零 Flutter 依赖,可独立单测)
│   │   │   ├── astro/        天文历法:儒略日、ΔT、VSOP87、节气、朔望
│   │   │   ├── calendar/     农历、干支、真太阳时
│   │   │   ├── bazi/         四柱、五行、十神、神煞、大运流年
│   │   │   ├── almanac/      黄历:建除、二十八宿、宜忌、彭祖百忌
│   │   │   ├── marriage/     合婚
│   │   │   ├── naming/       姓名五格剖象
│   │   │   ├── fortune/      每日运势
│   │   │   ├── zodiac/       太阳星座、上升星座、配对(回归黄道)
│   │   │   └── interpret/    离线本地解读(规则引擎,不联网)
│   │   ├── data/             常量表
│   │   ├── models/           数据模型
│   │   ├── services/         API 客户端、端侧影像特征提取
│   │   └── ui/               界面
│   └── test/                 单元测试(含权威参照值)
├── server/                   Node + TypeScript 后端(Claude 代理)
└── docs/                     算法说明与合规备忘
```

## 分层原则

`lib/core/` 是**纯计算**层:不 import 任何 `package:flutter`,不做网络请求,输入输出全是值对象。
所有排盘在本地完成,AI 只负责把**结构化盘面**翻译成人话——模型永远不参与推算,避免它编造星曜和术语。

## 精度说明

| 项目 | 算法 | 精度 |
|---|---|---|
| 太阳视黄经 | VSOP87D 截断序列 + FK5 修正 + 章动 + 光行差 | ~1″(约 25 秒时间) |
| 二十四节气 | 牛顿迭代解 λ = 15k° | 优于 1 分钟 |
| 朔望(定朔) | Meeus Ch.49 完整周期项 | 优于 20 秒 |
| 农历置闰 | 定朔 + 定气,无中气置闰法 | 与紫金山天文台历书一致 |
| ΔT | Espenak & Meeus 多项式 | 1900–2100 内足够 |

## 开发

```bash
cd app && flutter pub get && flutter test
```

```bash
cd server && npm install && npm run dev
```

详见 [docs/SETUP.md](docs/SETUP.md)、[docs/DEPLOY.md](docs/DEPLOY.md)(云端部署,让用户联网即可用 AI)、[docs/PLAY_STORE.md](docs/PLAY_STORE.md)(上架 Google Play)、[docs/IOS_CLOUD_BUILD.md](docs/IOS_CLOUD_BUILD.md)(没有 Mac 也能出 iOS 版)、[docs/ALGORITHM.md](docs/ALGORITHM.md)、[docs/COMPLIANCE.md](docs/COMPLIANCE.md)。
