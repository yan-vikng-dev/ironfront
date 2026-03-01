import type { AccountLoadout } from "../../../db/schema.js";
import type { accounts } from "../../../db/schema.js";

export type UnlockShellBody = {
  tank_id: string;
  shell_id: string;
};

export type UnlockShellResponse = {
  economy: (typeof accounts.$inferSelect)["economy"];
  loadout: AccountLoadout;
};
