# 没有 Mac 怎么出 iOS 版

用 GitHub Actions 的 macOS 机器编译。流程文件在 `.github/workflows/ci.yml`,已写好两个阶段:

| 阶段 | 需要什么 | 得到什么 |
|---|---|---|
| **未签名构建** | 只需 GitHub 账号 | 证明 iOS 能编过;产出 `Runner.app`(不能装到手机) |
| **签名构建 + TestFlight** | Apple Developer 账号($99/年)+ 5 个 secrets | 装到自己 iPhone 测试、后续上架 |

## 第一步:推到 GitHub(今天就能做)

1. 在 github.com 新建**私有**仓库,名字随意,例如 `mingli-ai`,**不要**勾选初始化 README。
2. 在本机终端执行(把 URL 换成你的):

```bash
cd C:\claude\mingli-ai && git remote add origin https://github.com/<你的用户名>/mingli-ai.git && git push -u origin main
```

首次推送会弹 GitHub 登录窗口。推完到仓库页 → Actions 标签,会看到 CI 自动跑起来:
`test` 与 `server` 几分钟结束;`windows` 约 8 分钟;`ios`(未签名)约 12 分钟。
全绿就说明 iOS 也能编过——这一步不花钱(私有仓库每月 2000 分钟免费,macOS 按 10 倍计,够跑十几次)。

## 第二步:Apple Developer(要装到手机时再做)

1. 到 developer.apple.com 用你的 Apple ID 注册 Apple Developer Program,$99/年,审核 1–2 天。
2. 通过后在 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → 新建 App:
   - Bundle ID 用 `io.cspeed.mingliAi`(与工程一致;要改的话同时改 `ios/Runner.xcodeproj` 里的 `PRODUCT_BUNDLE_IDENTIFIER`)
   - 名称、主要语言(简体中文)
3. 生成签名材料——**这一步通常需要 Mac 上的 Keychain 导出 .p12**。没有 Mac 的两个替代办法:
   - **用 OpenSSL 在 Windows 生成**:`openssl req -newkey rsa:2048 -keyout key.pem -out csr.pem`,把 `csr.pem` 上传到 Apple 开发者后台 → Certificates → 创建 *Apple Distribution* 证书 → 下载 `.cer`;再 `openssl pkcs12 -export -inkey key.pem -in cert.cer -out dist.p12`。我可以带你逐条敲。
   - **让 CI 自己签**(推荐):改用 fastlane match 或 Codemagic 的自动签名,证书由云端托管。想走这条路告诉我,我把 workflow 换成 Codemagic 的 `codemagic.yaml`。
4. Profiles → 新建 *App Store* 类型的描述文件,绑定上面的 Bundle ID 与证书,下载 `.mobileprovision`。
5. Users and Access → Integrations → App Store Connect API → 新建密钥(权限 App Manager),下载 `.p8`,记下 Key ID 与 Issuer ID。

## 第三步:把材料填进 GitHub Secrets

仓库 → Settings → Secrets and variables → Actions → New repository secret:

| Secret | 内容 |
|---|---|
| `IOS_P12_BASE64` | `dist.p12` 的 base64(PowerShell:`[Convert]::ToBase64String([IO.File]::ReadAllBytes("dist.p12"))`) |
| `IOS_P12_PASSWORD` | 导出 p12 时设的密码 |
| `IOS_PROFILE_BASE64` | `.mobileprovision` 的 base64 |
| `APPLE_TEAM_ID` | 开发者后台 Membership 页的 Team ID(10 位) |
| `IOS_BUNDLE_ID` | `io.cspeed.mingliAi` |
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | Issuer ID |
| `ASC_KEY_BASE64` | `.p8` 文件的 base64 |

填好后再推一次代码(或 Actions → CI → Run workflow),`ios` 任务会自动切到签名分支,产出 `.ipa` 并上传 TestFlight。
手机装 TestFlight App,接受邀请即可安装。

## 上架前

- 隐私政策 URL(必填;手相面相涉及生物特征,须单独说明"仅本机处理")
- App 隐私"营养标签":出生日期(用户内容)、匿名设备 ID(诊断)
- 截图:6.7" 与 6.1" 各一组
- 分类:生活 / 娱乐;年龄分级 12+ 或以上
- 描述避免"算命、改运"字眼——见 `COMPLIANCE.md`
