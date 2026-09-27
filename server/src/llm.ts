/**
 * 模型层的统一入口:路由只认这里的 interpret() / probe(),不知道背后是 Claude 还是 Gemini。
 *
 * 每家实现只负责"给系统提示词和对话,返回文本"(LlmProvider.complete);
 * 安全检查、越界改写、按标题拆段、加免责脚注这些与厂商无关的步骤都在这里,
 * 换模型不会漏掉任何一道护栏。
 */
import pino from "pino";

import { config, type ProviderName } from "./config.js";
import { systemPrompt, userMessage, type Kind } from "./prompts/index.js";
import { claudeProvider } from "./providers/claude.js";
import { geminiProvider } from "./providers/gemini.js";
import { aiFooter, checkOutput } from "./safety.js";

const log = pino({ level: config.logLevel, name: "llm" });

export interface Turn {
  role: "user" | "assistant";
  content: string;
}

export interface Completion {
  text: string;
  model: string;
  usage: { input: number; output: number; cacheRead: number };
}

export interface CompleteOptions {
  /** 改写一次越界句子时用 medium 就够,省钱 */
  effort: "high" | "medium";
}

export interface LlmProvider {
  readonly name: ProviderName;
  readonly model: string;
  complete(system: string, turns: Turn[], opts: CompleteOptions): Promise<Completion>;
  /** 健康检查:凭据与模型名是否可用 */
  probe(): Promise<boolean>;
}

export interface InterpretResult {
  text: string;
  sections: Record<string, string>;
  model: string;
  usage: { input: number; output: number; cacheRead: number };
}

/** 模型主动拒绝(安全分类器命中等),不是我们的错,也不重试 */
export class RefusalError extends Error {
  constructor(public readonly category: string | null) {
    super("模型拒绝了本次请求");
  }
}

/** 厂商 API 出错,已归一化;路由据 reason 决定回什么状态码 */
export class ProviderError extends Error {
  constructor(
    public readonly reason: "auth" | "rate" | "bad_request" | "upstream" | "network" | "timeout",
    public readonly status: number | null,
    message: string,
  ) {
    super(message);
  }
}

export const provider: LlmProvider = config.provider === "gemini" ? geminiProvider() : claudeProvider();

export async function interpret(kind: Kind, payload: Record<string, unknown>): Promise<InterpretResult> {
  const system = systemPrompt(kind);
  const user = userMessage(kind, payload);

  const first = await provider.complete(system, [{ role: "user", content: user }], { effort: "high" });
  let text = first.text.trim();

  // 输出兜底:命中越界表述就要求改写一次
  const verdict = checkOutput(text);
  if (!verdict.ok) {
    log.warn({ kind, hits: verdict.hits }, "output hit safety filter, rewriting");
    text = await rewrite(system, user, text);
  }

  log.info({ kind, provider: provider.name, model: first.model, ...first.usage }, "interpreted");

  return {
    text: text + aiFooter,
    sections: splitSections(text),
    model: first.model,
    usage: first.usage,
  };
}

async function rewrite(system: string, user: string, draft: string): Promise<string> {
  const turns: Turn[] = [
    { role: "user", content: user },
    { role: "assistant", content: draft },
    {
      role: "user",
      content:
        "上面的解读里有触碰「硬性禁止」的表述(疾病死亡预言、绝对化措辞、消费诱导或医疗投资建议)。" +
        "请保留结构与全部依据,只改写越界句子,输出完整修订版。",
    },
  ];
  const { text } = await provider.complete(system, turns, { effort: "medium" });
  // 改写后仍越界则直接剔除命中句,宁可少说
  const verdict = checkOutput(text.trim());
  if (verdict.ok) return text.trim();
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

export function probe(): Promise<boolean> {
  return provider.probe();
}
