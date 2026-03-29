import type { AccountLoadout, accounts } from "#src/db/schema.js";

export type UnlockShellResponse = {
  economy: (typeof accounts.$inferSelect)["economy"];
  loadout: AccountLoadout;
};

export type SetShellAmmoBody = { count: number };
