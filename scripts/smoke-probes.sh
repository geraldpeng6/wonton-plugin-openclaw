# OpenClaw 是 Agent，不提供网页入口、应用账号体系或插件自己的 MCP 服务。
# shellcheck shell=bash disable=SC2034
# 网页、身份、插件工具三项不适用；Agent 本身（加密私聊、模型回答、Wonton MCP、名单外不应答）在附加检查里实测。
IDENTITY_NA=1
SMOKE_NOTE="OpenClaw 没有网页入口、应用账号体系或插件自己的 MCP 服务；网页、主人身份、插件工具三项不适用。"

# Agent 的附加检查（助手见套件的 scripts/agent-probes.sh）。OpenClaw 自带的 shell、文件工具在容器里直接跑，
# 不经确认卡片，也没有 /wonton interrupt，这两项不测。
EXTRA_TIMEOUT=1800
extra_check() {
  agent_check_chat '请用一句话回答：Agent 冒烟加密链路。'
  agent_check_model
  agent_check_mcp_bus
  agent_check_outsider
}

# 保数据：Agent 的用户数据是 Bot 数据目录（会话、加密密钥、工作区）。没有网页和应用 API，加密私聊要
# 专用 Matrix 客户端（专项冒烟管）；这里经应用容器把带随机标记的文件写进工作区——agent 的 shell 和
# 文件工具本来就写这个目录——升级后读回来核对，证明数据目录在升级中原样保留。exec 按容器配置的
# user（compose 配了 PUID:PGID）跑，和应用同一身份写文件。
# 只用冒烟契约里的 SMOKE_INSTANCE/SMOKE_STATE；网关容器名里的插件 id 是本仓库清单自己的 id。
oc_gw() {
  local inst="${SMOKE_INSTANCE:-}"
  # data_write 在装 tag 阶段跑，主流程可能还没导出 SMOKE_INSTANCE；SMOKE_BASE 那时已有——实例名是其主机名前缀。
  if [[ -z "$inst" && -n "${SMOKE_BASE:-}" ]]; then
    inst="${SMOKE_BASE#http://}"; inst="${inst%%.*}"
  fi
  [[ -n "$inst" ]] || { echo "拿不到实例名（SMOKE_INSTANCE/SMOKE_BASE 都没有）" >&2; return 1; }
  printf 'wonton-%s--%s--gateway--default\n' "$inst" "ai-openclaw-agent"
}

marker_file() { # SMOKE_STATE 在套件里是状态目录（e2e 传的是标记文件本身），标记放对应路径
  if [[ -d "$SMOKE_STATE" ]]; then printf '%s' "$SMOKE_STATE/openclaw-marker"; else printf '%s' "${SMOKE_STATE}.marker"; fi
}

data_write() {
  local gw user marker out
  gw="$(oc_gw)" || return 1
  user="$(docker inspect -f '{{.Config.User}}' "$gw")"
  marker="保数据-$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
  out="$(docker exec ${user:+-u "$user"} "$gw" sh -c 'printf %s "$1" > /home/node/.openclaw/workspace/smoke-data.txt && cat /home/node/.openclaw/workspace/smoke-data.txt' sh "$marker")" ||
    { echo "写不进工作区（容器 $gw）：$out"; return 1; }
  [[ "$out" == "$marker" ]] || { echo "写进去的内容不对：$out"; return 1; }
  printf '%s' "$marker" >"$(marker_file)"
}

data_check() {
  local gw user marker out
  gw="$(oc_gw)" || return 1
  user="$(docker inspect -f '{{.Config.User}}' "$gw")"
  marker="$(cat "$(marker_file)")"
  out="$(docker exec ${user:+-u "$user"} "$gw" cat /home/node/.openclaw/workspace/smoke-data.txt 2>&1)" ||
    { echo "工作区文件读不到（数据目录没保住？）：$out"; return 1; }
  [[ "$out" == "$marker" ]] || { echo "标记对不上：期待 $marker，看到 $out"; return 1; }
}
