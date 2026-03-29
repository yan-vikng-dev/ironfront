import { eq } from "drizzle-orm";
import { Hono } from "hono";
import type { Context } from "hono";
import { importPKCS8, SignJWT } from "jose";
import type { AccountLoadout } from "@/db/schema.js";
import { config } from "@/config.js";
import { db } from "@/db/client.js";
import { accounts } from "@/db/schema.js";
import { requireBearerSession } from "@/api/require_bearer_session.js";
import type { BearerSessionVars } from "@/api/require_bearer_session.js";

type JoinArenaLoadoutPayload = {
  tank_id: string;
  shell_loadout_by_id: Record<string, number>;
};

function loadoutToJoinArenaPayload(loadout: AccountLoadout): JoinArenaLoadoutPayload {
  const tankId = loadout.selected_tank_id;
  const tankConfig = loadout.tanks[tankId];
  if (!tankConfig) throw new Error("loadout missing tanks for selected tank");
  const shellLoadoutById = tankConfig.shell_loadout_by_id;
  const hasAmmo = Object.values(shellLoadoutById).some((c) => c > 0);
  if (!hasAmmo) throw new Error("loadout has no ammunition for selected tank");
  return {
    tank_id: tankId,
    shell_loadout_by_id: shellLoadoutById
  };
}

export type PlayTicketResponse = {
  ticket: string;
  expires_at_unix: number;
};

async function postPlayTicketHandler(
  context: Context<{ Variables: BearerSessionVars }>
): Promise<Response> {
  if (!config.ticketSigningPrivateKey) {
    return context.json({ error: "TICKET_SIGNING_NOT_CONFIGURED" }, 503);
  }
  const accountId = context.var.accountId;
  const account = await db.query.accounts.findFirst({
    where: eq(accounts.account_id, accountId),
    columns: { account_id: true, username: true, loadout: true }
  });
  if (!account) {
    return context.json({ error: "PROFILE_NOT_FOUND" }, 404);
  }
  const loadoutPayload = loadoutToJoinArenaPayload(account.loadout);
  const exp = Math.floor(Date.now() / 1000) + config.ticketTtlSeconds;
  const privateKey = await importPKCS8(config.ticketSigningPrivateKey, "RS256");
  const ticket = await new SignJWT({
    account_id: account.account_id,
    username: account.username ?? "",
    loadout: loadoutPayload,
    server_allocation_id: null
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setExpirationTime(exp)
    .sign(privateKey);
  return context.json<PlayTicketResponse>({ ticket, expires_at_unix: exp });
}

export const route = new Hono<{ Variables: BearerSessionVars }>()
  .post("/", requireBearerSession, postPlayTicketHandler);
