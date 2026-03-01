import type { AccountLoadout } from "../../../db/schema.js";

export type PatchLoadoutBody = {
  selected_tank_id?: string;
  tanks?: Record<string, { unlocked_shell_ids: string[]; shell_loadout_by_id: Record<string, number> }>;
};

export type PatchLoadoutResponse = {
  loadout: AccountLoadout;
};
