import "dotenv/config";

// 当前 SDK 类型定义尚未包含 "xhigh";升级 SDK 后可加回
const effortLevels = ["low", "medium", "high", "max"] as const;
export type Effort = (typeof effortLevels)[number];

function effort(v: string | undefined): Effort {
  return (effortLevels as readonly string[]).includes(v ?? "") ? (v as Effort) : "high";
}

export type ProviderName = "claude" | "gemini";

/**
 * 选哪家模型:显式 LLM_PROVIDER 优先;没设的话,只给了 GEMINI_API_KEY 就用 Gemini,
 * 否则维持原来的 Claude 路径(含 `ant auth login` 的本地凭据)。
 */
function provider(): ProviderName {
  const v = process.env.LLM_PROVIDER?.trim().toLowerCase();
  if (v === "claude" || v === "gemini") return v;
  if (process.env.GEMINI_API_KEY && !process.env.ANTHROPIC_API_KEY) return "gemini";
  return "claude";
}

export const config = {
  port: Number(process.env.PORT ?? 8787),
  provider: provider(),

  // Claude
  claudeModel: process.env.CLAUDE_MODEL ?? "claude-opus-5",
  effort: effort(process.env.CLAUDE_EFFORT),

  // Gemini(REST,不引 SDK)。模型名以 ai.google.dev/gemini-api/docs/models 为准
  geminiApiKey: process.env.GEMINI_API_KEY?.trim() ?? "",
  geminiModel: process.env.GEMINI_MODEL ?? "gemini-3.8-flash",

  // 两家共用
  maxTokens: Number(process.env.LLM_MAX_TOKENS ?? process.env.CLAUDE_MAX_TOKENS ?? 6000),
  llmTimeoutMs: Number(process.env.LLM_TIMEOUT_MS ?? 120_000),

  corsOrigins: (process.env.CORS_ORIGINS ?? "*").split(",").map((s) => s.trim()),
  rateLimitPer10Min: Number(process.env.RATE_LIMIT_PER_10MIN ?? 30),
  cacheMaxEntries: Number(process.env.CACHE_MAX_ENTRIES ?? 5000),
  cacheTtlMs: Number(process.env.CACHE_TTL_DAYS ?? 7) * 86_400_000,
  logLevel: process.env.LOG_LEVEL ?? "info",
  // 可选的客户端共享口令。设了以后 /v1/interpret 只接受带 X-App-Token 的请求,
  // 把"随便谁发现了地址就能白用"挡掉。它编在 app 里,所以防误用不防有心人;
  // 真正的成本护栏是上面的限流与缓存。
  appToken: process.env.APP_TOKEN?.trim() || null,
};
