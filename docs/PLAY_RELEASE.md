# 知命 · FateCode —— Google Play 自动发布

仓库根目录一个命令搞定构建、校验、上传。商店资料(文案/图标/截图)也在仓库里,改完一条命令同步到 Play。

```
play-release.cmd check        只检查:工具、签名密钥、Play 连接、商店文字长度。不构建、不上传
play-release.cmd internal     测试 → 自动加 versionCode → 构建 AAB → 校验 → 上传「内部测试」
play-release.cmd internal closed:true   同一个版本也放进封闭测试(alpha)
play-release.cmd production   把内部测试里的版本提升到正式版(只建草稿,两次确认)
play-release.cmd metadata     上传商店文案、图标、截图(不碰安装包)
play-release.cmd details      设置商店默认语言和联系邮箱
```

实现在 `app/android/fastlane/Fastfile`(全部逻辑都在这一个文件里)。
每次运行的日志在 `app/build/release-logs/<时间戳>/`:每一步一个 `.log`,结果 `summary.json`,出错时还有 `error.txt`(含中文的「可能原因」)。

---

## 这套东西不会替你做的事

写死在代码里,不是靠参数控制:

- `internal` **只**传内部测试轨道,不会碰正式版。
- `production` **只做「提升 + 建草稿」**:不上传新包、不自动发布、不送审;非交互终端直接拒绝;要先答 y,再手输 `PRODUCTION-<版本号>` 二次确认;`deactivate_on_promote: false`,不会停用任何已有发布。
- 上传前核对 AAB 的签名证书 SHA-1,不是上传密钥就拒绝(防止 `key.properties` 丢了之后 Gradle 悄悄退回 debug 签名)。
- 校验包名、versionCode、versionName、targetSdk、是否 debuggable、原生库是否 16 KB 对齐,任何一项不对就停。

**最后点「发布」「送审」的永远是你本人,在 Play Console 里。**

---

## 首次配置(只做一次,前两步必须你本人做)

### 第 1 步 · 在 Play Console 建应用

<https://play.google.com/console> → 创建应用:

| 项 | 填 |
|---|---|
| 应用名称 | 知命 - 八字命盘与性格测试 |
| 默认语言 | 简体中文(zh-CN) |
| 应用或游戏 | 应用 |
| 免费或付费 | **免费**(发布后不能再改成付费,只能靠内购收费) |
| 包名 | **`io.github.firedragonai.mingli_ai`** |

包名登记后就永久固定,**和这里写的一个字都不能差**,否则后面所有命令都会报 `Package not found`。

### 第 2 步 · 授权服务账号

Play Console → **用户和权限** → 邀请用户:

```
play-publisher@schoolsift-family.iam.gserviceaccount.com
```

这个服务账号「学校通」已经在用了,一个服务账号可以管同一个开发者账号下的多个应用,**不用再建新的**,只要把本应用加进它的权限里。

应用权限按需要给:

| 要跑的命令 | 需要的权限 |
|---|---|
| `check` / `internal` | 发布到测试轨道 |
| `metadata` / `details` | 管理商店展示(**实测只勾这个 API 仍会 403,要临时给本应用「管理员」,跑完撤回**) |
| `production` | 发布到正式版 |

改完权限等几分钟再跑命令。

### 第 3 步 · 验证

```
play-release.cmd check
```

看到「服务账号密钥有效」且不再报 `Package not found` 就成了。

---

## 标准发版流程

```
1. 改代码,提交
2. play-release.cmd internal        → 自动测试、构建、校验、传内部测试
3. 手机上装内部测试版,自己点一遍
4. (个人账号)封闭测试满 12 人 × 14 天,在 Console 申请正式版权限
5. play-release.cmd production      → 在正式版轨道建草稿
6. 你本人去 Play Console 检查后点「发布」
```

版本号不用手动改:`internal` 会取 `max(Play 上各轨道最大 versionCode + 1, pubspec 里的 build 号)`,并写回 `app/pubspec.yaml`,记得连着这个改动一起提交。
要指定就加 `version_code:12`、`version_name:0.2.0`。

**版本名有个一致性检查**:`app/pubspec.yaml` 的版本名必须等于 `app/lib/services/api_client.dart` 里的 `appVersion`(应用发给后端的 `X-App-Version` 取的是后者)。不一致 `check` 会拦下来。

---

## 云端 AI 解读的开关

这个应用有两种包:

| | 纯离线版(默认) | 带云端 AI 版 |
|---|---|---|
| 八字/运势/黄历等全部功能 | 正常 | 正常 |
| AI 解读文字 | 本机规则引擎 | Gemini 生成 |
| 「更多 AI 解读」卡 | 自动灰掉,不报错 | 可用 |
| 数据安全表单 | 可答「不收集任何数据」 | 要如实申报 |

要打带云端的包,在 `app/android/fastlane/.env`(**不进 git**)里加一行:

```
MINGLI_APP_TOKEN="从 Render 面板 mingli-server → Environment → APP_TOKEN 复制"
```

地址 `MINGLI_API_URL` 已经在 `.env.default` 里(`https://mingli-server.onrender.com`,公开信息)。
两个都齐了 `internal` 才会把 `--dart-define` 编进去,构建开始前会打印「云端 AI:已配置」还是「未配置」。

服务器状态:<https://mingli-server.onrender.com/healthz>(free 档闲置 15 分钟休眠,首个请求慢几十秒)

---

## 商店资料

都在 `app/android/fastlane/metadata/android/<语言>/`:

```
title.txt               标题,30 字以内
short_description.txt   简短说明,80 字以内
full_description.txt    完整说明,4000 字以内
changelogs/<versionCode>.txt   这个版本的更新说明,500 字以内
images/icon.png                512×512
images/featureGraphic.png      1024×500,不能带 alpha 通道
images/phoneScreenshots/*.png  至少 2 张,按文件名排序
```

改完先 `check`(只验字数),再 `metadata`(真上传,要确认)。
目前只有 `zh-CN`。要加英文商店页,新建 `en-US/` 目录放英文文案和英文界面的截图即可。

类别(生活时尚)和上架国家/地区 **API 改不了**,在 Play Console 里设。

---

## 密钥与备份

| 东西 | 位置 | 说明 |
|---|---|---|
| 上传密钥 | `~/fatecode-upload-firedragonai.jks` | DN `CN=FateCode, O=FiredragonAI`,有效期到 2054 |
| 密钥密码 | `app/android/key.properties` | 已 gitignore |
| Play 服务账号 | `~/.secrets/mingli-ai/play-service-account.json` | 已限本用户可读;可用环境变量 `SUPPLY_JSON_KEY` 指到别处 |

> ⚠️ **立刻把上传密钥和 key.properties 备份到别处**(网盘、U 盘、密码管理器)。
> 弄丢它就无法再给这个应用发任何更新。两个文件都不在 git 里,**git 不是你的备份**。
> 在 Play Console 保持 **Play App Signing** 默认开启:这样万一上传密钥丢了还能向 Google 申请重置。

上传密钥的证书 SHA-1 写死在 `Fastfile` 的 `UPLOAD_CERT_SHA1` 里。换密钥时这里要跟着改,否则所有构建都会被拒。

---

## 常见错误

| 报错 | 原因与处理 |
|---|---|
| `Package not found` | Play Console 里还没建这个应用,或服务账号没被授权。按首次配置第 1、2 步做 |
| `403` / `caller does not have permission` | 服务账号权限不够。`metadata`/`details` 实测要临时开本应用「管理员」,跑完撤回 |
| `Only releases with status draft may be created on draft app` | 应用从未发布过,API 只能建草稿。脚本会自动改成传草稿,你去 Console 内部测试页手动点发布 |
| `versionCode ... already been used` | 这个号用过了(哪怕那次失败或草稿已删)。重跑会自动取最大值 +1 |
| AAB 签名证书不对 | `key.properties` 没读到,Gradle 退回了 debug 签名。检查文件和里面的 storeFile 路径 |
| 原生库不是 16 KB 对齐 | 升级 Flutter 或相关插件 |
| `invalid_grant` / `Invalid JWT` | 服务账号密钥失效,或本机时间不准 |

`play-release.cmd` **必须保持纯 ASCII**:cmd.exe 在 `chcp 65001` 生效之前就按系统码页解析整个文件,里面有中文注释会直接把命令解析坏。

---

## 英文商店页为什么还没上

`metadata/android/` 下**只有 `zh-CN`**,这是故意的。

英文文案已经写好,和英文界面截图一起放在仓库外的暂存区:

```
app/store/en-US-draft/     标题、简介、完整说明、更新说明 + 说明文件
app/store/play-en/         英文界面的真机截图
```

没放进 `metadata/android/en-US/` 是为了**防止 `metadata` lane 把半成品传上去**。
卡点是英文界面里还有 95 个词条显示中文(二十八宿、黄历宜忌活动、神煞、彭祖百忌),
截图上一眼可见。详情和待办见 `app/store/en-US-draft/README.md`。

补完翻译、修掉「Avoid」徽标溢出、重拍截图之后,把那两个目录的内容移进
`metadata/android/en-US/`,再跑 `play-release.cmd metadata` 即可。
