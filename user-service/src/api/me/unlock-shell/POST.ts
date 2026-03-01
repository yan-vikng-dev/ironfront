import { eq } from "drizzle-orm";
import { Hono } from "hono";
import type { Context } from "hono";
import { z } from "zod";
import { db } from "../../../db/client.js";
import { accounts } from "../../../db/schema.js";
import type { AccountLoadout } from "../../../db/schema.js";
import { loadCatalog } from "../../../catalog.js";
import { requireBearerSession } from "../../require_bearer_session.js";
import type { BearerSessionVars } from "../../require_bearer_session.js";
import type { UnlockShellResponse } from "./types.js";

const unlockShellBodySchema = z.object({
  tank_id: z.string().min(1),
  shell_id: z.string().min(1)
});

async function postUnlockShellHandler(
  context: Context<{ Variables: BearerSessionVars }>
) {
  const accountId = context.var.accountId;
  const parseResult = unlockShellBodySchema.safeParse(await context.req.json());
  if (!parseResult.success) {
    return context.json({ error: "INVALID_SHELL" }, 400);
  }
  const { tank_id: tankId, shell_id: shellId } = parseResult.data;

  const catalog = loadCatalog();
  const shellSpec = catalog.shells[shellId];
  if (!shellSpec) {
    return context.json({ error: "INVALID_SHELL" }, 400);
  }

  const tankSpec = catalog.tanks[tankId];
  if (!tankSpec || !tankSpec.allowed_shell_ids.includes(shellId)) {
    return context.json({ error: "SHELL_NOT_FOR_TANK" }, 400);
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

    const cost = shellSpec.unlock_cost;
    const dollars = account.economy.dollars;
    if (dollars < cost) {
      return { error: "INSUFFICIENT_FUNDS" as const };
    }

    const newTankLoadout = {
      ...tankLoadout,
      unlocked_shell_ids: [...tankLoadout.unlocked_shell_ids, shellId],
      shell_loadout_by_id: {
        ...tankLoadout.shell_loadout_by_id,
        [shellId]: tankLoadout.shell_loadout_by_id[shellId] ?? 0
      }
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
      dollars: dollars - cost
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
  "/",
  requireBearerSession,
  postUnlockShellHandler
);
