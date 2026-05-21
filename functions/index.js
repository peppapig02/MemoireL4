const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const OpenAI = require("openai");

admin.initializeApp();

function parseContent(content) {
  if (typeof content !== "string") {
    return { message: String(content ?? "") };
  }

  try {
    if (content.includes("{") && content.includes("}")) {
      const jsonStr = content.substring(
        content.indexOf("{"),
        content.lastIndexOf("}") + 1,
      );
      return JSON.parse(jsonStr);
    }
  } catch (error) {
    logger.warn("Unable to parse AI JSON payload", error);
  }

  return { message: content };
}

exports.generateChatResponse = onCall(
  { cors: true },
  async (request) => {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "OPENAI_API_KEY is missing on the server.",
      );
    }

    const prompt = request.data?.prompt;
    const context = request.data?.context;

    if (typeof prompt !== "string" || prompt.trim().length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "The prompt must be a non-empty string.",
      );
    }

    try {
      const client = new OpenAI({ apiKey });
      const messages = [
        ...(context ? [{ role: "system", content: context }] : []),
        { role: "user", content: prompt },
      ];

      const response = await client.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages,
        temperature: 0.7,
        max_tokens: 1000,
      });

      const content = response.choices?.[0]?.message?.content;
      return parseContent(content);
    } catch (error) {
      logger.error("generateChatResponse failed", error);
      throw new HttpsError("internal", "Unable to generate chat response.");
    }
  },
);
