import { eq } from "drizzle-orm";
import { Hono } from "hono";
import type { Context } from "hono";
import { z } from "zod";
import { db } from "../../../db/client.js";
import { accounts } from "../../../db/schema.js";
import type { AccountLoadout } from "../../../db/schema.js";
import { requireBearerSession } from "../../require_bearer_session.js";
import type { BearerSessionVars } from "../../require_bearer_session.js";
import type { PatchLoadoutResponse } from "./types.js";

const tankLoadoutSchema = z.object({
  unlocked_shell_ids: z.array(z.string()),
  shell_loadout_by_id: z.record(z.string(), z.number().int().min(0))
});

const patchBodySchema = z.object({
  selected_tank_id: z.string().optional(),
  tanks: z.record(z.string(), tankLoadoutSchema).optional()
});

async function patchLoadoutHandler(
  context: Context<{ Variables: BearerSessionVars }>
) {
  const accountId = context.var.accountId;
  const parseResult = patchBodySchema.safeParse(await context.req.json());
  if (!parseResult.success) {
    return context.json({ error: "INVALID_LOADOUT" }, 400);
  }
  const body = parseResult.data;

  const account = await db.query.accounts.findFirst({
    where: eq(accounts.account_id, accountId),
    columns: { loadout: true }
  });
  if (!account) {
    return context.json({ error: "PROFILE_NOT_FOUND" }, 404);
  }

  const newLoadout: AccountLoadout = {
    selected_tank_id: body.selected_tank_id ?? account.loadout.selected_tank_id,
    tanks: body.tanks ?? account.loadout.tanks
  };

  const [updated] = await db
    .update(accounts)
    .set({
      loadout: newLoadout,
      updated_at: new Date()
    })
    .where(eq(accounts.account_id, accountId))
    .returning({ loadout: accounts.loadout });

  if (!updated) {
    return context.json({ error: "PROFILE_NOT_FOUND" }, 404);
  }

  return context.json<PatchLoadoutResponse>({
    loadout: updated.loadout
  });
}

export const route = new Hono<{ Variables: BearerSessionVars }>().patch(
  "/",
  requireBearerSession,
  patchLoadoutHandler
);
