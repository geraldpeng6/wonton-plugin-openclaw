const modelVariables = ["WONTON_MODEL_BASE_URL", "WONTON_MODEL_API_KEY", "WONTON_MODEL_DEFAULT"];

export default {
  id: "wonton-model-hint",
  register(api) {
    api.on("before_agent_reply", (_event, context) => {
      if (context.modelProviderId === "wonton" &&
          !modelVariables.every((name) => (process.env[name] ?? "").trim())) {
        return {
          handled: true,
          reply: { text: "Model connection is not ready. Open Models in Wonton to connect it." },
        };
      }
    }, { eligibleTriggers: ["user"] });
  },
};
