# OpenClaw

开发流程见[插件开发指南](https://github.com/geraldpeng6/wonton-docs/blob/main/develop.md)。

OpenClaw 是一个住在云吞里的 Agent：用核心分配的 Matrix 身份和主人聊天，经 Wonton MCP 总线调用核心的只读工具。接了模型网关时模型默认走网关；模型网关是可选的，没接时 Agent 照常启动，只是还没有可用模型，发消息会得到模型未授权的报错（OpenClaw 回落到它内置的默认服务商），网关就绪后核心重建容器即自动接上。OpenClaw 的官方账号登录要在它自己的命令行里完成（Matrix 渠道没有聊天内的登录命令，容器用户也到不了终端），所以没有网关时没有替代的模型来源。

插件使用 OpenClaw 官方多架构镜像 `ghcr.io/openclaw/openclaw:2026.10.10`。首次启动由一次性 `init` 服务安装固定版本的官方 `@openclaw/matrix` 插件；OpenClaw 的受管 npm 安装会跳过生命周期脚本，因此 init 随后显式运行 Matrix crypto 的官方 `download-lib.js`，并要求对应平台的 `.node` 原生绑定已经落盘。安装包、原生绑定和 Matrix 加密状态都写在 Bot 数据目录，重启或重建容器不会重新生成设备密钥。
init 还会用核心注入的访问令牌调用 Matrix `/_matrix/client/v3/account/whoami`，把返回的 `device_id` 写入配置；这样加密客户端使用的设备身份与令牌一致，重启时可继续解密。

原生绑定下载失败时 init 失败，不回退到 WASM 或明文。

OpenClaw 没有网页入口、对外端口、ACP 接口或应用自己的账号登录。核心在安装时创建 Bot 身份和主人的加密私聊；模型凭据、MCP 地址和 Bot 数据路径由核心注入，不写进插件包。网关密钥在配置里只引用变量名，由 OpenClaw 读取配置时从环境替换，不落进数据目录。

## 开发与验证

检查插件包并用支持规范 0.4 的核心镜像启动开发环境：

```bash
WONTON_CORE_IMAGE=wonton-core:labels-test WONTON_PULL=never scripts/check.sh --official
WONTON_CORE_IMAGE=wonton-core:labels-test WONTON_PULL=never scripts/dev.sh up
WONTON_CORE_IMAGE=wonton-core:labels-test WONTON_PULL=never scripts/dev.sh install --yes
```

OpenClaw 没有网页入口、应用自己的登录或插件自己的 MCP 服务。通用 smoke 的网页、主人身份和插件工具三项标记为 N/A；专项验收要在核心的 Tuwunel 开发环境中验证：加密私聊收发、重启后仍能解密、经模型网关回答一句话、调用一个 Wonton MCP 只读工具。首次下载 Matrix 插件和原生 crypto 绑定需要 `network.egress`；不提供代理时应如实失败，不回退到明文。

容器里的 shell、文件和其他内置工具不经过 Wonton 确认卡片，只能触碰 Bot 数据目录以及容器自身可见的文件；没有 Docker socket、宿主 shell、网页入口或对外端口。

## 图标

`icon.svg` 是本仓库按插件规范手写的 OpenClaw 首字母图标，不使用上游官方标志，也不表示 OpenClaw Foundation 的认可或背书。许可证和依赖声明见 [NOTICE](NOTICE)。
