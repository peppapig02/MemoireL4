const admin = require("firebase-admin");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {defineString} = require("firebase-functions/params");

admin.initializeApp();

const botRoadCloudRunUrl = defineString("BOTROAD_CLOUD_RUN_URL");

exports.receiveBotRoadEvent = onRequest(
  {
    cors: true,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ok: false, error: "POST required"});
      return;
    }

    const cloudRunUrl = botRoadCloudRunUrl.value();
    if (!cloudRunUrl) {
      res.status(500).json({
        ok: false,
        error: "BOTROAD_CLOUD_RUN_URL is not configured",
      });
      return;
    }

    try {
      const response = await fetch(`${cloudRunUrl.replace(/\/$/, "")}/iot-event`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-BotRoad-Device-Token": req.get("X-BotRoad-Device-Token") || "",
        },
        body: JSON.stringify(req.body || {}),
      });

      const text = await response.text();
      res.status(response.status).type("application/json").send(text);
    } catch (error) {
      logger.error("receiveBotRoadEvent failed", error);
      res.status(502).json({
        ok: false,
        error: "Cloud Run forwarding failed",
      });
    }
  },
);
