import cors from "cors";
import express from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import pino from "pino";
import { pinoHttp } from "pino-http";

import { probe } from "./claude.js";
import { config } from "./config.js";
import { cacheStats, interpretRouter } from "./routes/interpret.js";

const log = pino({ level: config.logLevel, name: "server" });
const app = express();

app.disable("x-powered-by");
app.set("trust proxy", 1);
app.use(helmet());
app.use(
  cors({
    origin: config.corsOrigins.includes("*") ? true : config.corsOrigins,
    methods: ["POST", "GET"],
    allowedHeaders: ["Content-Type", "X-Device-Id", "X-App-Version", "X-Platform", "X-App-Token"],
  }),
);
// 盘面 JSON 通常 10–30 KB;256 KB 上限足够,同时挡掉 base64 图片
app.use(express.json({ limit: "256kb" }));
app.use(
  pinoHttp({
    logger: log,
    // 不记请求体:里面是用户生日
    serializers: {
      req: (r: { method?: string; url?: string; headers: Record<string, unknown> }) => ({
        method: r.method,
        url: r.url,
        device: r.headers["x-device-id"],
      }),
    },
  }),
);

app.get("/healthz", (_req, res) => {
  res.json({ ok: true, model: config.model, cache: cacheStats() });
});

app.use("/v1/interpret", (req, res, next) => {
  if (config.appToken && req.header("x-app-token") !== config.appToken) {
    res.status(401).json({ error: "未授权的客户端" });
    return;
  }
  next();
});

app.use(
  "/v1/interpret",
  rateLimit({
    windowMs: 10 * 60 * 1000,
    limit: config.rateLimitPer10Min,
    standardHeaders: "draft-7",
    legacyHeaders: false,
    keyGenerator: (req) => (req.headers["x-device-id"] as string | undefined) ?? req.ip ?? "anon",
    message: { error: "请求过于频繁,请稍后再试" },
  }),
  interpretRouter,
);

app.use((_req, res) => res.status(404).json({ error: "not found" }));

app.listen(config.port, async () => {
  log.info({ port: config.port, model: config.model, effort: config.effort }, "mingli-server listening");
  const ok = await probe();
  if (!ok) log.warn("无法访问模型:检查 ANTHROPIC_API_KEY 或运行 `ant auth login`");
});
