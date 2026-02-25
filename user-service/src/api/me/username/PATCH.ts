import { zValidator } from "@hono/zod-validator";
import { eq } from "drizzle-orm";
import { Hono } from "hono";
import type { Context } from "hono";
import { z } from "zod";
import { db } from "../../../db/client.js";
import { accounts } from "../../../db/schema.js";
import { requireBearerSession } from "../../require_bearer_session.js";
import type { BearerSessionVars } from "../../require_bearer_session.js";
import type { PatchUsernameBody, PatchUsernameResponse } from "./types.js";

async function patchUsernameHandler(
  context: Context<{ Variables: BearerSessionVars }>
) {
  const accountId = context.var.accountId;
  const body = await context.req.json<PatchUsernameBody>();

  const username = body.username.trim();
  await db
    .update(accounts)
    .set({
      username,
      username_updated_at_unix: Math.floor(Date.now() / 1000),
      updated_at: new Date()
    })
    .where(eq(accounts.account_id, accountId));

  const account = await db.query.accounts.findFirst({
    where: eq(accounts.account_id, accountId)
  });
  if (!account) {
    return context.json({ error: "PROFILE_NOT_FOUND" }, 404);
  }

  return context.json<PatchUsernameResponse>({
    account_id: account.account_id,
    username: account.username,
    username_updated_at_unix: account.username_updated_at_unix
  });
}

export const route = new Hono<{ Variables: BearerSessionVars }>().patch(
  "/",
  requireBearerSession,
  zValidator(
    "json",
    z.object({
      username: z.string().trim().min(1).max(32)
    }),
    (result, context) => {
      if (!result.success) {
        return context.json(
          { error: "INVALID_REQUEST", details: z.flattenError(result.error) },
          400
        );
      }
    }
  ),
  patchUsernameHandler
);
