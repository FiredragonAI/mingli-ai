import "dotenv/config";

// 当前 SDK 类型定义尚未包含 "xhigh";升级 SDK 后可加回
const effortLevels = ["low", "medium", "high", "max"] as const;
export type Effort = (typeof effortLevels)[number];

function effort(v: string | undefined): Effort {
  return (effortLevels as readonly string[]).includes(v ?? "") ? (v as Effort) : "high";
}

export const config = {
  port: Number(process.env.PORT ?? 8787),
  model: process.env.CLAUDE_MODEL ?? "claude-opus-5",
  effort: effort(process.env.CLAUDE_EFFORT),
  maxTokens: Number(process.env.CLAUDE_MAX_TOKENS ?? 6000),
  corsOrigins: (process.env.CORS_ORIGINS ?? "*").split(",").map((s) => s.trim()),
  rateLimitPer10Min: Number(process.env.RATE_LIMIT_PER_10MIN ?? 30),
  cacheMaxEntries: Number(process.env.CACHE_MAX_ENTRIES ?? 5000),
  cacheTtlMs: Number(process.env.CACHE_TTL_DAYS ?? 7) * 86_400_000,
  logLevel: process.env.LOG_LEVEL ?? "info",
};
