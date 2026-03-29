import { eq } from "drizzle-orm";
import { Hono } from "hono";
import type { Context } from "hono";
import { db } from "#src/db/client.js";
import { accounts } from "#src/db/schema.js";
import type { AccountLoadout } from "#src/db/schema.js";
import { catalog } from "#src/catalog.js";
import { requireBearerSession } from "#src/api/require_bearer_session.js";
import type { BearerSessionVars } from "#src/api/require_bearer_session.js";
import type { UnlockShellResponse } from "./types.js";

async function postUnlockShellHandler(
  context: Context<{ Variables: BearerSessionVars }>
) {
  const accountId = context.var.accountId;
  const tankId = context.req.param("tank_id");
  const shellId = context.req.param("shell_id");
  if (!tankId || !shellId) {
    return context.json({ error: "INVALID_SHELL" }, 400);
  }

  const shellSpec = catalog.shells[shellId];
  if (!shellSpec) {
    return context.json({ error: "INVALID_SHELL" }, 400);
  }

  const result = await db.transaction(async (tx) => {
    const account = await tx.query.accounts.findFirst({
      where: eq(accounts.account_id, accountId),
      columns: { economy: true, loadout: true }
    });
    if (!account) return null;

    const loadout = account.loadout;
    const tankLoadout = loadout.tanks[tankId];
    if (!tankLoadout) {
      return { error: "TANK_NOT_OWNED" as const };
    }

    if (tankLoadout.unlocked_shell_ids.includes(shellId)) {
      return { error: "ALREADY_OWNED" as const };
    }

    const cost = shellSpec.dollar_cost;
    if (account.economy.dollars < cost) {
      return { error: "INSUFFICIENT_FUNDS" as const };
    }

    const newTankLoadout = {
      ...tankLoadout,
      unlocked_shell_ids: [...tankLoadout.unlocked_shell_ids, shellId]
    };

    const newLoadout: AccountLoadout = {
      ...loadout,
      tanks: {
        ...loadout.tanks,
        [tankId]: newTankLoadout
      }
    };

    const newEconomy = {
      ...account.economy,
      dollars: account.economy.dollars - cost
    };

    const [updated] = await tx
      .update(accounts)
      .set({
        economy: newEconomy,
        loadout: newLoadout,
        updated_at: new Date()
      })
      .where(eq(accounts.account_id, accountId))
      .returning({ economy: accounts.economy, loadout: accounts.loadout });

    return updated
      ? { economy: updated.economy, loadout: updated.loadout }
      : null;
  });

  if (result === null) {
    return context.json({ error: "PROFILE_NOT_FOUND" }, 404);
  }
  if ("error" in result) {
    return context.json({ error: result.error }, 400);
  }

  return context.json<UnlockShellResponse>(result);
}

export const route = new Hono<{ Variables: BearerSessionVars }>().post(
  "/:shell_id",
  requireBearerSession,
  postUnlockShellHandler
);
