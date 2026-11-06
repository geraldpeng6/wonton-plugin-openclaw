# OpenClaw 是 Agent，不提供网页入口、应用账号体系或插件自己的 MCP 服务。
# shellcheck shell=bash disable=SC2034
# 通用插件冒烟只验证清单能装上；Matrix 加密、模型和 Wonton MCP 在专项验收中实测。
IDENTITY_NA=1
SMOKE_NOTE="OpenClaw 没有网页入口、应用账号体系或插件自己的 MCP 服务；网页、主人身份、插件工具三项不适用。专项验收验证加密 Matrix 私聊、模型回答和 Wonton MCP 只读工具。"

# 保数据：Agent 的用户数据是 Bot 数据目录（会话、加密密钥、工作区）。没有网页和应用 API，加密私聊要
# 专用 Matrix 客户端（专项冒烟管）；这里经应用容器把带随机标记的文件写进工作区——agent 的 shell 和
# 文件工具本来就写这个目录——升级后读回来核对，证明数据目录在升级中原样保留。$SMOKE_STATE 和容器
# 名由冒烟主流程提供。
data_write() {
  local gw marker out
  gw="wonton-$SMOKE_INSTANCE--${SMOKE_PLUGIN_ID//./-}--gateway"
  marker="保数据-$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
  out="$(docker exec "$gw" sh -c 'printf %s "$1" > /home/node/.openclaw/workspace/smoke-data.txt && cat /home/node/.openclaw/workspace/smoke-data.txt' sh "$marker")" ||
    { echo "写不进工作区（容器 $gw）：$out"; return 1; }
  [[ "$out" == "$marker" ]] || { echo "写进去的内容不对：$out"; return 1; }
  printf '%s' "$marker" >"$SMOKE_STATE"
}

data_check() {
  local gw marker out
  gw="wonton-$SMOKE_INSTANCE--${SMOKE_PLUGIN_ID//./-}--gateway"
  marker="$(cat "$SMOKE_STATE")"
  out="$(docker exec "$gw" cat /home/node/.openclaw/workspace/smoke-data.txt 2>&1)" ||
    { echo "工作区文件读不到（数据目录没保住？）：$out"; return 1; }
  [[ "$out" == "$marker" ]] || { echo "标记对不上：期待 $marker，看到 $out"; return 1; }
}
