const fs = require("node:fs");

const path = process.env.OPENCLAW_CONFIG_PATH;
const config = JSON.parse(fs.readFileSync(path, "utf8"));
const gatewayReady = ["WONTON_MODEL_BASE_URL", "WONTON_MODEL_API_KEY", "WONTON_MODEL_DEFAULT"]
  .every((name) => (process.env[name] ?? "").trim());

config.models ??= {};
config.models.mode = "merge";
config.models.providers ??= {};
config.agents ??= {};
config.agents.defaults ??= {};
const defaults = config.agents.defaults;
const selected = typeof defaults.model === "string" ? defaults.model : defaults.model?.primary;
const usesGateway = !selected || selected.startsWith("wonton/");
const allow = new Set(["wonton/*"]);
for (const profile of Object.values(config.auth?.profiles ?? {})) {
  if (profile.mode === "oauth" && profile.provider) allow.add(`${profile.provider}/*`);
}
if (selected && !usesGateway) allow.add(selected);
defaults.modelPolicy = { ...defaults.modelPolicy, allow: [...allow] };

if (gatewayReady) {
  config.models.providers.wonton = {
    baseUrl: "${WONTON_MODEL_BASE_URL}",
    apiKey: "${WONTON_MODEL_API_KEY}",
    api: "openai-completions",
    models: [{
      id: "${WONTON_MODEL_DEFAULT}",
      name: "Wonton default",
      input: ["text"],
      contextWindow: 128000,
      maxTokens: 8192,
      compat: { supportsTools: true },
    }],
  };
  const reference = `wonton/${process.env.WONTON_MODEL_DEFAULT.trim()}`;
  defaults.models ??= {};
  defaults.models[reference] ??= {};
  defaults.models[reference].alias ??= "default";
  if (usesGateway) defaults.model = { primary: reference, fallbacks: [] };
} else {
  delete config.models.providers.wonton;
  if (usesGateway) defaults.model = { primary: "wonton/default", fallbacks: [] };
  console.error("Model gateway is not ready: open Models in Wonton to connect it.");
}

defaults.utilityModel ??= "";
fs.writeFileSync(path, JSON.stringify(config, null, 2) + "\n");
