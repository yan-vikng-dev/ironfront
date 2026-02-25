export type PatchUsernameBody = {
  username: string;
};

export type PatchUsernameResponse = {
  account_id: string;
  username: string | null;
  username_updated_at_unix: number | null;
};
