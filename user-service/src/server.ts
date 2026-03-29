import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { route as authExchangeRoute } from "./api/auth/exchange/POST.js";
import { route as catalogGetRoute } from "./api/catalog/GET.js";
import { route as meGetRoute } from "./api/me/GET.js";
import { route as meLoadoutPatchRoute } from "./api/me/loadout/PATCH.js";
import { route as meUnlockShellPostRoute } from "./api/me/unlock-shell/POST.js";
import { route as meUnlockTankPostRoute } from "./api/me/unlock-tank/POST.js";
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
app.route("/me/loadout", meLoadoutPatchRoute);
app.route("/me/unlock-shell", meUnlockShellPostRoute);
app.route("/me/unlock-tank", meUnlockTankPostRoute);
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
