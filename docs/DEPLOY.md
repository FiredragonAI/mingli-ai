# 把 AI 解读部署到云端:用户装上 app 就能用

## 先把账算清楚

AI 解读 = 你的服务器拿着**你的** Anthropic 密钥去调 Claude。这件事绕不开三点:

1. **密钥必须留在服务器上。** 塞进 app 安装包等于公开——任何人解包就能拿去刷,账单算你的。
2. **费用由你承担。** 用户不需要注册、不需要密钥;每一次解读的 API 费用记在你的 Anthropic 账户上。
   服务端已经做了三层护栏:同一盘面 7 天内重复请求零成本(缓存)、每台设备 10 分钟 30 次(限流)、
   可选共享口令(挡掉"发现地址就白用")。费用敏感时把 `CLAUDE_EFFORT` 降到 `medium`
   或把 `CLAUDE_MODEL` 换成 `claude-sonnet-5`。
3. **连不上云端时 app 不会空白。** 客户端会自动退回本机规则引擎生成解读,并标注"云端暂不可用 · 本机生成"。

部署只需做一次;之后每个用户装上 app,联网就有 AI。

## 方案 A:Render(推荐,全程网页点选,约 10 分钟)

1. 代码推到 GitHub(私有仓库即可)。
2. 打开 <https://render.com>,注册/登录,**New → Blueprint**,授权并选中本仓库。
   Render 会读到根目录的 `render.yaml`,列出一个叫 `mingli-server` 的服务。
3. 它会要求你填 `ANTHROPIC_API_KEY`——从 <https://console.anthropic.com> 的 API Keys 页取。
   `APP_TOKEN` 不用填,Render 自动生成。
4. 点 **Apply**。首次构建 3–5 分钟。完成后拿到地址,形如
   `https://mingli-server.onrender.com`。浏览器打开 `https://…/healthz` 看到 `{"ok":true,…}` 即成功。
5. 进服务的 **Environment** 页,复制 `APP_TOKEN` 的值,下一节要用。

免费档(`plan: free`)空闲 15 分钟会休眠,之后第一次请求要等几十秒唤醒;自己试用没问题,
正式给用户用把 `render.yaml` 里改成 `plan: starter`(按月付费,不休眠)。

## 方案 B:Fly.io(命令行,机房可选香港)

```bash
cd server
fly launch --copy-config --no-deploy
fly secrets set ANTHROPIC_API_KEY=sk-ant-… APP_TOKEN=$(openssl rand -hex 24)
fly deploy
fly status   # 拿地址,形如 https://mingli-server.fly.dev
```

## 方案 C:自己的服务器 / 国内云主机

任何能跑 Docker 的机器:

```bash
cd server && cp .env.example .env   # 填 ANTHROPIC_API_KEY、APP_TOKEN
docker build -t mingli-server . && docker run -d --restart=always -p 8787:8787 --env-file .env mingli-server
```

前面套一层 Nginx/Caddy 做 HTTPS。**面向中国大陆用户**要注意两点:境外机房(Render/Fly)从大陆访问
可能慢或不稳定;而国内云主机对外提供服务需要 ICP 备案,且服务器访问 Anthropic API 需要合规的出境线路。
先用方案 A 把功能跑通,再按目标市场决定机房。

## 把地址编进 app

服务器地址和口令是**编译时**注入的,不是写在代码里:

```bash
cd app && flutter build windows --release --dart-define=MINGLI_API_URL=https://mingli-server.onrender.com --dart-define=MINGLI_APP_TOKEN=<APP_TOKEN的值>
```

iOS 同理(`flutter build ipa …`)。不带这两个参数编出来的包指向 `http://localhost:8787`(开发用)。

用 GitHub Actions 云构建的话,到仓库 **Settings → Secrets and variables → Actions** 加两个 secret:
`MINGLI_API_URL`、`MINGLI_APP_TOKEN`,CI 会自动带进 Windows 和 iOS 的构建。

## 上线后看什么

- Render/Fly 面板的日志:每条解读记录 `kind`、token 用量、是否命中缓存;**不记录用户生日**。
- Anthropic 控制台的 Usage 页:实际花费。建议设一个月度预算提醒。
- `/healthz` 里的 `cache.size`:缓存条数,越高说明省得越多。

## 更新服务端

Render:推代码到 main 分支自动重新部署。Fly:`fly deploy`。
客户端不用改——协议向后兼容,旧 app 照常工作。
