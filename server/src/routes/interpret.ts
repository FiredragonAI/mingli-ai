import Anthropic from "@anthropic-ai/sdk";
import { Router, type Request, type Response } from "express";
import { z } from "zod";

import { LruCache, cacheKey } from "../cache.js";
import { interpret, RefusalError, type InterpretResult } from "../claude.js";
import type { Kind } from "../prompts/index.js";
import { inputLooksMalicious } from "../safety.js";

const cache = new LruCache<InterpretResult>();

// 客户端只传结构化对象;字段名固定,值是 JSON。大小由 body limit 控制。
const obj = z.record(z.unknown());
const schemas: Record<Kind, z.ZodTypeAny> = {
  bazi: z.object({ chart: obj, focus: z.string().max(60).optional() }).strict(),
  daily: z.object({ chart: obj, fortune: obj }).strict(),
  marriage: z.object({ marriage: obj }).strict(),
  name: z.object({ name: obj, chart: obj.nullable().optional() }).strict(),
  almanac: z.object({ almanac: obj, chart: obj.nullable().optional() }).strict(),
  palm: z.object({ features: obj, chart: obj.nullable().optional() }).strict(),
  face: z.object({ features: obj, chart: obj.nullable().optional() }).strict(),
};

export const interpretRouter = Router();

for (const kind of Object.keys(schemas) as Kind[]) {
  interpretRouter.post(`/${kind}`, (req, res) => void handle(kind, req, res));
}

async function handle(kind: Kind, req: Request, res: Response): Promise<void> {
  const parsed = schemas[kind].safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "请求体格式不正确", issues: parsed.error.issues.slice(0, 5) });
    return;
  }
  const payload = parsed.data as Record<string, unknown>;

  if (inputLooksMalicious(payload)) {
    res.status(400).json({ error: "请求包含不允许的内容" });
    return;
  }

  // 影像类:双保险,拒绝任何看起来像图像的字段
  if ((kind === "palm" || kind === "face") && JSON.stringify(payload).length > 20_000) {
    res.status(413).json({ error: "特征数据过大,请勿上传图像" });
    return;
  }

  const key = cacheKey(kind, payload);
  const hit = cache.get(key);
  if (hit) {
    res.json({ ...hit, cached: true });
    return;
  }

  try {
    const result = await interpret(kind, payload);
    cache.set(key, result);
    res.json({ ...result, cached: false });
  } catch (err) {
    if (err instanceof RefusalError) {
      res.status(422).json({ error: "本次内容无法生成解读,请调整后重试" });
    } else if (err instanceof Anthropic.RateLimitError) {
      res.status(503).json({ error: "解读服务繁忙,请稍后再试" });
    } else if (err instanceof Anthropic.AuthenticationError) {
      req.log.error("Anthropic credentials invalid");
      res.status(500).json({ error: "服务配置错误" });
    } else if (err instanceof Anthropic.BadRequestError) {
      req.log.error({ err }, "bad request to Anthropic");
      res.status(500).json({ error: "解读请求构造失败" });
    } else if (err instanceof Anthropic.APIError) {
      req.log.error({ status: err.status, err }, "Anthropic API error");
      res.status(502).json({ error: "解读服务暂时不可用" });
    } else if (err instanceof Anthropic.APIConnectionError) {
      req.log.error({ err }, "Anthropic connection error");
      res.status(502).json({ error: "无法连接解读服务" });
    } else {
      req.log.error({ err }, "unexpected error");
      res.status(500).json({ error: "服务器内部错误" });
    }
  }
}

export function cacheStats(): { size: number } {
  return { size: cache.size };
}
