import type { AccountLoadout } from "../../../db/schema.js";
import type { accounts } from "../../../db/schema.js";

export type UnlockTankBody = {
  tank_id: string;
};

export type UnlockTankResponse = {
  economy: (typeof accounts.$inferSelect)["economy"];
  loadout: AccountLoadout;
};
