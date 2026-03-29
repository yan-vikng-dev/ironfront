import type { accounts, AccountLoadout } from "#src/db/schema.js";

export type MeResponse = {
  account_id: string;
  username: string | null;
  username_updated_at_unix: number | null;
  economy: (typeof accounts.$inferSelect)["economy"];
  loadout: AccountLoadout;
};
