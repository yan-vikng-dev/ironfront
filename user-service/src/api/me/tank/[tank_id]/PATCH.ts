import { eq } from "drizzle-orm";
import { Hono } from "hono";
import type { Context } from "hono";
import { db } from "#src/db/client.js";
import { accounts } from "#src/db/schema.js";
import type { AccountLoadout } from "#src/db/schema.js";
import { requireBearerSession } from "#src/api/require_bearer_session.js";
import type { BearerSessionVars } from "#src/api/require_bearer_session.js";

async function patchSelectTankHandler(
  context: Context<{ Variables: BearerSessionVars }>
) {
  const accountId = context.var.accountId;
  const tankId = context.req.param("tank_id");
  if (!tankId) {
    return context.json({ error: "INVALID_TANK" }, 400);
  }

  const account = await db.query.accounts.findFirst({
    where: eq(accounts.account_id, accountId),
    columns: { loadout: true }
  });
  if (!account) {
    return context.json({ error: "PROFILE_NOT_FOUND" }, 404);
  }

  if (!account.loadout.tanks[tankId]) {
    return context.json({ error: "TANK_NOT_OWNED" }, 400);
  }

  const newLoadout: AccountLoadout = {
    ...account.loadout,
    selected_tank_id: tankId
  };

  await db
    .update(accounts)
    .set({
      loadout: newLoadout,
      updated_at: new Date()
    })
    .where(eq(accounts.account_id, accountId));

  return context.json({ ok: true });
}

export const route = new Hono<{ Variables: BearerSessionVars }>().patch(
  "/:tank_id",
  requireBearerSession,
  patchSelectTankHandler
);
