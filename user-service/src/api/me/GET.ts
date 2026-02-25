import { eq } from "drizzle-orm";
import { Hono } from "hono";
import type { Context } from "hono";
import { db } from "../../db/client.js";
import { accounts } from "../../db/schema.js";
import { requireBearerSession } from "../require_bearer_session.js";
import type { BearerSessionVars } from "../require_bearer_session.js";
import type { MeResponse } from "./types.js";

async function getMeHandler(context: Context<{ Variables: BearerSessionVars }>) {
  const accountId = context.var.accountId;
  const account = await db.query.accounts.findFirst({
    where: eq(accounts.account_id, accountId),
    columns: {
      account_id: true,
      username: true,
      username_updated_at_unix: true,
      economy: true,
      loadout: true
    }
  });
  if (!account) {
    return context.json({ error: "PROFILE_NOT_FOUND" }, 404);
  }
  return context.json<MeResponse>(account);
}

export const route = new Hono<{ Variables: BearerSessionVars }>()
  .get("/", requireBearerSession, getMeHandler);
