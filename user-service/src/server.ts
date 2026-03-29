import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { route as authExchangeRoute } from "./api/auth/exchange/POST.js";
import { route as catalogGetRoute } from "./api/catalog/GET.js";
import { route as meGetRoute } from "./api/me/GET.js";
import { route as tankPatchRoute } from "./api/me/tank/[tank_id]/PATCH.js";
import { route as tankPostRoute } from "./api/me/tank/[tank_id]/POST.js";
import { route as tankShellPatchRoute } from "./api/me/tank/[tank_id]/shell/[shell_id]/PATCH.js";
import { route as tankShellPostRoute } from "./api/me/tank/[tank_id]/shell/[shell_id]/POST.js";
import { route as meUsernamePatchRoute } from "./api/me/username/PATCH.js";
import { route as playTicketPostRoute } from "./api/play/ticket/POST.js";
import { config } from "./config.js";

const app = new Hono();

app.get("/health", (context) => {
  return context.json({ ok: true, stage: config.stage });
});

app.route("/auth/exchange", authExchangeRoute);
app.route("/catalog", catalogGetRoute);
app.route("/me", meGetRoute);
app.route("/me/tank", tankPostRoute);
app.route("/me/tank", tankPatchRoute);
app.route("/me/tank/:tank_id/shell", tankShellPostRoute);
app.route("/me/tank/:tank_id/shell", tankShellPatchRoute);
app.route("/me/username", meUsernamePatchRoute);
app.route("/play/ticket", playTicketPostRoute);

app.onError((error, context) => {
  console.error("[http] unhandled error", error);
  return context.json({ error: "INTERNAL_ERROR" }, 500);
});

serve({
  fetch: app.fetch,
  port: config.port
});

console.log(`[user-service] listening on :${config.port} stage=${config.stage}`);
