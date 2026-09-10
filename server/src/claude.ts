import Anthropic from "@anthropic-ai/sdk";
import pino from "pino";

import { config } from "./config.js";
import { systemPrompt, userMessage, type Kind } from "./prompts/index.js";
import { aiFooter, checkOutput } from "./safety.js";

const log = pino({ level: config.logLevel, name: "claude" });

// 凭据从环境解析:ANTHROPIC_API_KEY,或 `ant auth login` 的本地档案
const client = new Anthropic();

export interface InterpretResult {
  text: string;
  sections: Record<string, string>;
  model: string;
  usage: { input: number; output: number; cacheRead: number };
}

export class RefusalError extends Error {
  constructor(public readonly category: string | null) {
    super("模型拒绝了本次请求");
  }
}

/**
 * 调 Claude 生成解读。
 *
 * - 流式请求 + finalMessage():输出较长时不会撞 HTTP 超时;
 * - 自适应思考 + effort:命理解读需要综合多条依据,给它思考空间;
 * - 系统提示词打 cache_control:同类请求共享前缀,省 90% 输入费;
 * - server-side fallbacks:极少数情况(比如用户盘面触发安全分类器)自动换模型续写,
 *   而不是给用户一个空白。
 */
export async function interpret(kind: Kind, payload: Record<string, unknown>): Promise<InterpretResult> {
  const system = systemPrompt(kind);
  const user = userMessage(kind, payload);

  const stream = client.beta.messages.stream({
    model: config.model,
    max_tokens: config.maxTokens,
    betas: ["server-side-fallback-2026-07-01"],
    fallbacks: "default",
    thinking: { type: "adaptive" },
    output_config: { effort: config.effort },
    system: [{ type: "text", text: system, cache_control: { type: "ephemeral" } }],
    messages: [{ role: "user", content: user }],
  });

  const message = await stream.finalMessage();

  if (message.stop_reason === "refusal") {
    // stop_details 在当前 SDK 类型里尚未声明,运行时存在
    const details = (message as { stop_details?: { category?: string | null } }).stop_details;
    throw new RefusalError(details?.category ?? null);
  }

  let text = message.content
    .filter((b): b is Anthropic.Beta.BetaTextBlock => b.type === "text")
    .map((b) => b.text)
    .join("")
    .trim();

  // 输出兜底:命中越界表述就要求改写一次
  const verdict = checkOutput(text);
  if (!verdict.ok) {
    log.warn({ kind, hits: verdict.hits }, "output hit safety filter, rewriting");
    text = await rewrite(system, user, text);
  }

  const usage = {
    input: message.usage.input_tokens,
    output: message.usage.output_tokens,
    cacheRead: message.usage.cache_read_input_tokens ?? 0,
  };
  log.info({ kind, model: message.model, ...usage, stop: message.stop_reason }, "interpreted");

  return {
    text: text + aiFooter,
    sections: splitSections(text),
    model: message.model,
    usage,
  };
}

async function rewrite(system: string, user: string, draft: string): Promise<string> {
  const stream = client.beta.messages.stream({
    model: config.model,
    max_tokens: config.maxTokens,
    betas: ["server-side-fallback-2026-07-01"],
    fallbacks: "default",
    thinking: { type: "adaptive" },
    output_config: { effort: "medium" },
    system: [{ type: "text", text: system, cache_control: { type: "ephemeral" } }],
    messages: [
      { role: "user", content: user },
      { role: "assistant", content: draft },
      {
        role: "user",
        content:
          "上面的解读里有触碰「硬性禁止」的表述(疾病死亡预言、绝对化措辞、消费诱导或医疗投资建议)。" +
          "请保留结构与全部依据,只改写越界句子,输出完整修订版。",
      },
    ],
  });
  const message = await stream.finalMessage();
  const text = message.content
    .filter((b): b is Anthropic.Beta.BetaTextBlock => b.type === "text")
    .map((b) => b.text)
    .join("")
    .trim();
  // 改写后仍越界则直接剔除命中句,宁可少说
  const verdict = checkOutput(text);
  if (verdict.ok) return text;
  return text
    .split(/(?<=[。!?\n])/)
    .filter((s) => checkOutput(s).ok)
    .join("");
}

/** 按 "## 标题" 拆段,给客户端分卡片展示用。 */
function splitSections(md: string): Record<string, string> {
  const out: Record<string, string> = {};
  const parts = md.split(/^##\s+/m).filter((p) => p.trim());
  for (const p of parts) {
    const nl = p.indexOf("\n");
    if (nl < 0) continue;
    out[p.slice(0, nl).trim()] = p.slice(nl + 1).trim();
  }
  return out;
}

/** 供健康检查快速验证凭据是否可用。 */
export async function probe(): Promise<boolean> {
  try {
    await client.models.retrieve(config.model);
    return true;
  } catch (e) {
    log.error({ err: e }, "model probe failed");
    return false;
  }
}
