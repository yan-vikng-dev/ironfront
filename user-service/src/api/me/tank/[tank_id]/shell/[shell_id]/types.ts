import type { AccountLoadout, accounts } from "@/db/schema.js";

export type UnlockShellResponse = {
  economy: (typeof accounts.$inferSelect)["economy"];
  loadout: AccountLoadout;
};

export type SetShellAmmoBody = { count: number };
