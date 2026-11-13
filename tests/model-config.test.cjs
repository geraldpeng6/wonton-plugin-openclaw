const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const root = path.resolve(__dirname, "..");
const configScript = path.join(root, "model-config.cjs");
const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "wonton-model-config-test-"));
const configPath = path.join(tempDir, "config.json");

function apply(config) {
  fs.writeFileSync(configPath, JSON.stringify(config));
  const result = spawnSync(process.execPath, [configScript], {
    encoding: "utf8",
    env: { PATH: process.env.PATH, OPENCLAW_CONFIG_PATH: configPath },
  });
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

try {
  const configuredPolicy = apply({
    agents: {
      defaults: {
        model: { primary: "subscription/selected", fallbacks: [] },
        modelPolicy: { allow: ["subscription/selected"] },
      },
    },
    auth: { profiles: { owner: { provider: "subscription", mode: "oauth" } } },
  });
  assert.deepEqual(configuredPolicy.agents.defaults.modelPolicy.allow, [
    "subscription/selected", "wonton/*",
  ]);

  const freshConfig = apply({
    agents: { defaults: { model: "subscription/selected" } },
    auth: { profiles: { owner: { provider: "subscription", mode: "oauth" } } },
  });
  assert.ok(freshConfig.agents.defaults.modelPolicy.allow.includes("subscription/selected"));
  assert.ok(freshConfig.agents.defaults.modelPolicy.allow.includes("subscription/*"));
  console.log("Configured model restrictions are preserved; fresh config admits explicit selection and subscription login");
} finally {
  fs.rmSync(tempDir, { recursive: true, force: true });
}
