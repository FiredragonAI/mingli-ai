# mingli-server

Claude 代理。客户端把**算好的盘面 JSON**发来,这里加提示词调用 Claude,把解读文本返回。

## 端点

| 方法 | 路径 | 请求体 |
|---|---|---|
| GET | `/healthz` | — |
| POST | `/v1/interpret/bazi` | `{ chart, focus? }` |
| POST | `/v1/interpret/daily` | `{ chart, fortune }` |
| POST | `/v1/interpret/marriage` | `{ marriage }` |
| POST | `/v1/interpret/name` | `{ name, chart? }` |
| POST | `/v1/interpret/almanac` | `{ almanac, chart? }` |
| POST | `/v1/interpret/palm` | `{ features, chart? }` |
| POST | `/v1/interpret/face` | `{ features, chart? }` |
| POST | `/v1/interpret/zodiac` | `{ zodiac, match?, chart? }` |

响应:`{ text, sections, model, usage, cached }`。

设置了 `APP_TOKEN` 时,`/v1/interpret/*` 要求请求头 `X-App-Token` 与之一致,否则 401。

部署到云端见 [docs/DEPLOY.md](../docs/DEPLOY.md)(Render 蓝图 `render.yaml` 在仓库根目录,Fly 配置 `fly.toml` 在本目录)。

## 设计要点

- **模型只解读不推算**:提示词禁止模型自行排盘或编造数据里没有的星曜。
- **Claude Opus 5 + 自适应思考 + effort=high**:命理解读要综合十几条依据,给足思考空间;成本敏感把 `CLAUDE_EFFORT` 降到 `medium`,或把 `CLAUDE_MODEL` 换成 `claude-sonnet-5`。
- **流式 + `finalMessage()`**:长输出不撞超时。
- **提示词缓存**:系统提示词是稳定前缀,打 `cache_control`,同类请求共享。
- **server-side fallbacks**(`fallbacks: "default"`):模型因安全分类器拒答时自动由备选模型续写,用户不会拿到空白。不需要可去掉 `betas` 与 `fallbacks` 两行。
- **结果缓存**:同一盘面 7 天内重复请求零成本。
- **限流**:按 `X-Device-Id` 每 10 分钟 30 次。
- **内容兜底**:`safety.ts` 对输出做越界检测,命中则要求模型改写一次。
- **不记日志**:请求体含用户生日,pino 只记方法、路径、设备 ID。

## 运行

```bash
cp .env.example .env
npm install
npm run dev
```

生产:`npm run build && npm start`,或用 Dockerfile。
