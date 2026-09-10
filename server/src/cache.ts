import { createHash } from "node:crypto";

import { config } from "./config.js";

/**
 * 解读结果缓存。同一份盘面 JSON 反复请求(用户来回切页、多设备)直接命中,
 * 不再花一分钱。单实例内存 LRU;多实例部署时换成 Redis,接口不变。
 */
interface Entry<T> {
  value: T;
  expiresAt: number;
}

export class LruCache<T> {
  private readonly map = new Map<string, Entry<T>>();

  constructor(
    private readonly maxEntries = config.cacheMaxEntries,
    private readonly ttlMs = config.cacheTtlMs,
  ) {}

  get(key: string): T | undefined {
    const e = this.map.get(key);
    if (!e) return undefined;
    if (e.expiresAt < Date.now()) {
      this.map.delete(key);
      return undefined;
    }
    // 触碰即移到末尾,实现 LRU
    this.map.delete(key);
    this.map.set(key, e);
    return e.value;
  }

  set(key: string, value: T): void {
    if (this.map.size >= this.maxEntries) {
      const oldest = this.map.keys().next().value;
      if (oldest !== undefined) this.map.delete(oldest);
    }
    this.map.set(key, { value, expiresAt: Date.now() + this.ttlMs });
  }

  get size(): number {
    return this.map.size;
  }
}

/** 稳定序列化(键排序)后取 sha256,保证同一内容不同键序也命中。 */
export function cacheKey(kind: string, payload: unknown): string {
  const stable = JSON.stringify(payload, (_k, v) =>
    v && typeof v === "object" && !Array.isArray(v)
      ? Object.fromEntries(Object.entries(v).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)))
      : v,
  );
  return `${kind}:${createHash("sha256").update(stable).digest("hex")}`;
}
