import { eq } from "drizzle-orm";
import { Hono } from "hono";
import type { Context } from "hono";
import { z } from "zod";
import { db } from "#src/db/client.js";
import { accounts } from "#src/db/schema.js";
import type { AccountLoadout } from "#src/db/schema.js";
import { requireBearerSession } from "#src/api/require_bearer_session.js";
import type { BearerSessionVars } from "#src/api/require_bearer_session.js";

const setShellAmmoBodySchema = z.object({
  count: z.number().int().min(0)
});

async function patchSetShellAmmoHandler(
  context: Context<{ Variables: BearerSessionVars }>
) {
  const accountId = context.var.accountId;
  const tankId = context.req.param("tank_id");
  const shellId = context.req.param("shell_id");
  if (!tankId || !shellId) {
    return context.json({ error: "INVALID_SHELL" }, 400);
  }

  const parseResult = setShellAmmoBodySchema.safeParse(await context.req.json());
  if (!parseResult.success) {
    return context.json({ error: "INVALID_SHELL" }, 400);
  }
  const { count } = parseResult.data;

  const account = await db.query.accounts.findFirst({
    where: eq(accounts.account_id, accountId),
    columns: { loadout: true }
  });
  if (!account) {
    return context.json({ error: "PROFILE_NOT_FOUND" }, 404);
  }

  const tankLoadout = account.loadout.tanks[tankId];
  if (!tankLoadout) {
    return context.json({ error: "TANK_NOT_OWNED" }, 400);
  }

  if (!tankLoadout.unlocked_shell_ids.includes(shellId)) {
    return context.json({ error: "SHELL_NOT_UNLOCKED" }, 400);
  }

  const newLoadout: AccountLoadout = {
    ...account.loadout,
    tanks: {
      ...account.loadout.tanks,
      [tankId]: {
        ...tankLoadout,
        shell_loadout_by_id: {
          ...tankLoadout.shell_loadout_by_id,
          [shellId]: count
        }
      }
    }
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
  "/:shell_id",
  requireBearerSession,
  patchSetShellAmmoHandler
);
