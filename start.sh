#!/usr/bin/env sh
# cmc-proxy launcher (macOS / Linux)
# NOTE: Node 23 的 fetch 不读 *_PROXY 环境变量 (NODE_USE_ENV_PROXY 无效, 已实测),
# 上游走代理是靠 proxy.js 里的 undici ProxyAgent (dispatcher) 实现的, 这里的 export
# 只影响 node 拉起的子进程等, 保留无害。真正开关: CMC_UPSTREAM_PROXY / config.upstreamProxy。
cd "$(dirname "$0")"
export HTTPS_PROXY="http://127.0.0.1:7897"
export HTTP_PROXY="http://127.0.0.1:7897"
export NODE_USE_ENV_PROXY="1"
# 端口占用保护: 5411 已有实例在跑时直接退出, 避免双实例抢端口造成混乱
# (改端口启动时传 --port N, 本检查自动跟随)
PORT=5411
_prev=""
for _a in "$@"; do
  if [ "$_prev" = "--port" ]; then PORT="$_a"; break; fi
  _prev="$_a"
done
if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "[start.sh] 端口 $PORT 已被占用, 疑似已有 cmc-proxy 在运行, 本次不启动" >&2
  lsof -nP -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | head -3 >&2
  exit 2
fi
if [ -z "$CMDC_API_KEY" ]; then
  echo "[start.sh] ERROR: CMDC_API_KEY is empty, proxy will refuse to start" >&2
  exit 1
fi
exec node proxy.js
