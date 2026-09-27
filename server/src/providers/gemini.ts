import pino from "pino";

import { config } from "../config.js";
import { ProviderError, RefusalError, type Completion, type CompleteOptions, type LlmProvider, type Turn } from "../llm.js";

const log = pino({ level: config.logLevel, name: "gemini" });

const BASE = "https://generativelanguage.googleapis.com/v1beta";

/**
 * Gemini 实现。直接走 REST(generateContent),不引 SDK:
 * 请求体就三个字段,自己拼比多背一个依赖的升级节奏省心。
 *
 * 角色映射:Gemini 的对话只有 user / model,系统提示词单独放 systemInstruction。
 * 越界改写那轮会带上"assistant"草稿,这里转成 model。
 */
export function geminiProvider(): LlmProvider {
  const model = config.geminiModel;
  const key = config.geminiApiKey;
  if (!key) {
    // 启动时就说清楚,而不是等第一个用户请求才 500
    log.error("LLM_PROVIDER=gemini 但没有 GEMINI_API_KEY");
  }

  async function complete(system: string, turns: Turn[], _opts: CompleteOptions): Promise<Completion> {
    const body = {
      systemInstruction: { parts: [{ text: system }] },
      contents: turns.map((t) => ({ role: t.role === "assistant" ? "model" : "user", parts: [{ text: t.content }] })),
      generationConfig: { maxOutputTokens: config.maxTokens, temperature: 0.8 },
    };

    const res = await post(`${BASE}/models/${encodeURIComponent(model)}:generateContent`, body);
    const data = (await res.json()) as GenerateContentResponse;

    // 整个请求被拦(通常是提示词层面的安全分类),没有候选
    if (data.promptFeedback?.blockReason) throw new RefusalError(data.promptFeedback.blockReason);

    const cand = data.candidates?.[0];
    if (!cand) throw new ProviderError("upstream", res.status, "Gemini 未返回候选结果");
    if (cand.finishReason === "SAFETY" || cand.finishReason === "PROHIBITED_CONTENT" || cand.finishReason === "BLOCKLIST") {
      throw new RefusalError(cand.finishReason);
    }

    const text = (cand.content?.parts ?? [])
      .map((p) => p.text ?? "")
      .join("");
    if (!text.trim()) throw new ProviderError("upstream", res.status, `Gemini 返回空文本(finishReason=${cand.finishReason ?? "?"})`);

    const u = data.usageMetadata;
    return {
      text,
      model: data.modelVersion ?? model,
      usage: {
        input: u?.promptTokenCount ?? 0,
        output: u?.candidatesTokenCount ?? 0,
        cacheRead: u?.cachedContentTokenCount ?? 0,
      },
    };
  }

  async function probe(): Promise<boolean> {
    if (!key) return false;
    try {
      const res = await fetch(`${BASE}/models/${encodeURIComponent(model)}`, {
        headers: { "x-goog-api-key": key },
        signal: AbortSignal.timeout(15_000),
      });
      if (res.ok) return true;
      log.error({ status: res.status, body: (await res.text()).slice(0, 300) }, "model probe failed");
      return false;
    } catch (e) {
      log.error({ err: e }, "model probe failed");
      return false;
    }
  }

  async function post(url: string, body: unknown): Promise<Response> {
    let res: Response;
    try {
      res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": key },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(config.llmTimeoutMs),
      });
    } catch (e) {
      const name = (e as { name?: string }).name;
      if (name === "TimeoutError" || name === "AbortError") throw new ProviderError("timeout", null, "Gemini 请求超时");
      throw new ProviderError("network", null, (e as Error).message);
    }
    if (res.ok) return res;

    const detail = (await res.text()).slice(0, 500);
    log.error({ status: res.status, detail }, "Gemini API error");
    if (res.status === 401 || res.status === 403) throw new ProviderError("auth", res.status, detail);
    // Gemini 对无效 key 回的是 400 "API key not valid",不是 401;按配置错误处理,别让人以为是请求体的问题
    if (res.status === 400 && /API key not valid|API_KEY_INVALID/i.test(detail)) throw new ProviderError("auth", res.status, detail);
    if (res.status === 429) throw new ProviderError("rate", res.status, detail);
    if (res.status === 400 || res.status === 404) throw new ProviderError("bad_request", res.status, detail);
    throw new ProviderError("upstream", res.status, detail);
  }

  return { name: "gemini", model, complete, probe };
}

// 只声明用到的字段
interface GenerateContentResponse {
  candidates?: Array<{
    content?: { parts?: Array<{ text?: string }> };
    finishReason?: string;
  }>;
  promptFeedback?: { blockReason?: string };
  usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number; cachedContentTokenCount?: number };
  modelVersion?: string;
}
