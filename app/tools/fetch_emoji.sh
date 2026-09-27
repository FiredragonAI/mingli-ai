#!/usr/bin/env bash
# 下载 SBTI 结果页用的 Noto Animated Emoji(Lottie JSON)到 assets/emoji/。
#
# 码点来自 lib/core/sbti/sbti.dart 里每个类型的 lottieCode,改类型的表情只需改那里再跑一次。
# 来源:https://fonts.gstatic.com/s/e/notoemoji/latest/<码点>/lottie.json
# 许可:CC BY 4.0(Google)—— app 内结果页与 docs/COMPLIANCE.md 已署名。
#
# 用法:bash tools/fetch_emoji.sh   (在 app/ 目录下)
set -euo pipefail
cd "$(dirname "$0")/.."

out=assets/emoji
mkdir -p "$out"
codes=$(grep -o "lottieCode: '[0-9a-f_]*'" lib/core/sbti/sbti.dart | sed "s/lottieCode: '\(.*\)'/\1/")
n=0; total=0
for cp in $codes; do
  f="$out/$cp.json"
  url="https://fonts.gstatic.com/s/e/notoemoji/latest/$cp/lottie.json"
  if curl -fsSL --retry 3 --max-time 60 -o "$f" "$url"; then
    # 起手必须是 JSON 对象,不是 HTML 错误页
    head -c1 "$f" | grep -q '{' || { echo "非 JSON:$cp"; rm -f "$f"; exit 1; }
    size=$(stat -c%s "$f"); total=$((total + size)); n=$((n + 1))
    printf '%-24s %7d B\n' "$cp" "$size"
  else
    echo "下载失败:$cp"; exit 1
  fi
done
echo "共 $n 个,合计 $((total / 1024)) KB"
