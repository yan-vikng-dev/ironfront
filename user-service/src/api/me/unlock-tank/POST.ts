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
import type { UnlockTankResponse } from "./types.js";

const DEFAULT_SHELL_AMMO = 70;

const unlockTankBodySchema = z.object({
  tank_id: z.string().min(1)
});

async function postUnlockTankHandler(
  context: Context<{ Variables: BearerSessionVars }>
) {
  const accountId = context.var.accountId;
  const parseResult = unlockTankBodySchema.safeParse(await context.req.json());
  if (!parseResult.success) {
    return context.json({ error: "INVALID_TANK" }, 400);
  }
  const { tank_id: tankId } = parseResult.data;

  const catalog = loadCatalog();
  const tankSpec = catalog.tanks[tankId];
  if (!tankSpec) {
    return context.json({ error: "INVALID_TANK" }, 400);
  }

  const result = await db.transaction(async (tx) => {
    const account = await tx.query.accounts.findFirst({
      where: eq(accounts.account_id, accountId),
      columns: { economy: true, loadout: true }
    });
    if (!account) return null;

    const loadout = account.loadout;
    if (loadout.tanks[tankId]) {
      return { error: "ALREADY_OWNED" as const };
    }

    const cost = tankSpec.dollar_cost;
    const dollars = account.economy.dollars;
    if (dollars < cost) {
      return { error: "INSUFFICIENT_FUNDS" as const };
    }

    const firstShellId = tankSpec.allowed_shell_ids[0];
    if (!firstShellId) {
      return { error: "INVALID_TANK" as const };
    }

    const newLoadout: AccountLoadout = {
      ...loadout,
      tanks: {
        ...loadout.tanks,
        [tankId]: {
          unlocked_shell_ids: [firstShellId],
          shell_loadout_by_id: { [firstShellId]: DEFAULT_SHELL_AMMO }
        }
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

  return context.json<UnlockTankResponse>(result);
}

export const route = new Hono<{ Variables: BearerSessionVars }>().post(
  "/",
  requireBearerSession,
  postUnlockTankHandler
);
