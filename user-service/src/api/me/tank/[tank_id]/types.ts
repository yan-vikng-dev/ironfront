import type { AccountLoadout, accounts } from "@/db/schema.js";

export type UnlockTankBody = { initial_shell_id: string };

export type UnlockTankResponse = {
  economy: (typeof accounts.$inferSelect)["economy"];
  loadout: AccountLoadout;
};
