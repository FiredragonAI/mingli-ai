/**
 * 内容安全。
 *
 * 命理类产品最常见的下架/投诉原因不是"迷信",而是文案越界:预言疾病死亡、
 * 承诺改运、诱导消费、给投资医疗建议。提示词里已经禁止,这里再做一层输出兜底。
 */

const forbiddenOutput: RegExp[] = [
  /(必|会|将)(死|亡|夭折|短命)/,
  /寿命(只|仅)?(有|到|至)\s*\d+/,
  /(患|得|罹患)(癌|肿瘤|绝症|艾滋)/,
  /(一定|必定|肯定)(会|要)?(离婚|破产|坐牢|出事|车祸|大病)/,
  /(买|购买|购置)(法物|法器|开光|符咒|转运珠|貔貅)/,
  /(付费|花钱|捐|供养).{0,6}(化解|消灾|改运|转运)/,
  /(建议|推荐|应该)(买入|卖出|抄底|加仓|投资|炒股|买房)/,
  /(停药|不用吃药|不必就医|不要去医院)/,
];

/** 输入侧:拒绝把自由文本塞进结构化字段的注入尝试。 */
const forbiddenInput: RegExp[] = [
  /ignore (all|previous|above) instructions/i,
  /you are now/i,
  /忽略(以上|之前|所有)(指令|规则|要求)/,
  /system prompt/i,
];

export function inputLooksMalicious(payload: unknown): boolean {
  const text = JSON.stringify(payload);
  return forbiddenInput.some((r) => r.test(text));
}

export interface SafetyVerdict {
  ok: boolean;
  hits: string[];
}

export function checkOutput(text: string): SafetyVerdict {
  const hits = forbiddenOutput.filter((r) => r.test(text)).map((r) => r.source);
  return { ok: hits.length === 0, hits };
}

/** 生成内容统一加尾注(《生成式人工智能服务管理暂行办法》要求标识)。 */
export const aiFooter =
  "\n\n---\n*以上内容由 AI 依据传统文化资料生成,仅供娱乐参考,不构成医疗、法律、投资建议。*";
