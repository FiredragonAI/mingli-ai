import Anthropic from "@anthropic-ai/sdk";
import pino from "pino";

import { config } from "../config.js";
import { ProviderError, RefusalError, type Completion, type CompleteOptions, type LlmProvider, type Turn } from "../llm.js";

const log = pino({ level: config.logLevel, name: "claude" });

/**
 * Claude 实现。
 *
 * - 流式请求 + finalMessage():输出较长时不会撞 HTTP 超时;
 * - 自适应思考 + effort:命理解读需要综合多条依据,给它思考空间;
 * - 系统提示词打 cache_control:同类请求共享前缀,省 90% 输入费;
 * - server-side fallbacks:极少数情况(比如用户盘面触发安全分类器)自动换模型续写,
 *   而不是给用户一个空白。
 *
 * 客户端在这里才构造:凭据从环境解析(ANTHROPIC_API_KEY,或 `ant auth login` 的本地档案),
 * 选了 Gemini 的部署里根本不会走到这一步,也就不会因为缺 Anthropic 凭据而启动失败。
 */
export function claudeProvider(): LlmProvider {
  const client = new Anthropic({ timeout: config.llmTimeoutMs });
  const model = config.claudeModel;

  async function complete(system: string, turns: Turn[], opts: CompleteOptions): Promise<Completion> {
    let message: Anthropic.Beta.BetaMessage;
    try {
      const stream = client.beta.messages.stream({
        model,
        max_tokens: config.maxTokens,
        betas: ["server-side-fallback-2026-07-01"],
        fallbacks: "default",
        thinking: { type: "adaptive" },
        output_config: { effort: opts.effort === "high" ? config.effort : "medium" },
        system: [{ type: "text", text: system, cache_control: { type: "ephemeral" } }],
        messages: turns.map((t) => ({ role: t.role, content: t.content })),
      });
      message = await stream.finalMessage();
    } catch (err) {
      throw normalize(err);
    }

    if (message.stop_reason === "refusal") {
      // stop_details 在当前 SDK 类型里尚未声明,运行时存在
      const details = (message as { stop_details?: { category?: string | null } }).stop_details;
      throw new RefusalError(details?.category ?? null);
    }

    const text = message.content
      .filter((b): b is Anthropic.Beta.BetaTextBlock => b.type === "text")
      .map((b) => b.text)
      .join("");

    return {
      text,
      model: message.model,
      usage: {
        input: message.usage.input_tokens,
        output: message.usage.output_tokens,
        cacheRead: message.usage.cache_read_input_tokens ?? 0,
      },
    };
  }

  /** 供健康检查快速验证凭据是否可用。 */
  async function probe(): Promise<boolean> {
    try {
      await client.models.retrieve(model);
      return true;
    } catch (e) {
      log.error({ err: e }, "model probe failed");
      return false;
    }
  }

  return { name: "claude", model, complete, probe };
}

function normalize(err: unknown): unknown {
  if (err instanceof Anthropic.RateLimitError) return new ProviderError("rate", err.status, err.message);
  if (err instanceof Anthropic.AuthenticationError) return new ProviderError("auth", err.status, err.message);
  if (err instanceof Anthropic.BadRequestError) return new ProviderError("bad_request", err.status, err.message);
  if (err instanceof Anthropic.APIConnectionTimeoutError) return new ProviderError("timeout", null, err.message);
  if (err instanceof Anthropic.APIConnectionError) return new ProviderError("network", null, err.message);
  if (err instanceof Anthropic.APIError) return new ProviderError("upstream", err.status ?? null, err.message);
  return err;
}
