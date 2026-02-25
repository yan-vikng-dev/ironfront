import { z } from "zod";

export const authProviderSchema = z.enum(["dev", "pgs"]);
export type AuthProvider = z.infer<typeof authProviderSchema>;

export const exchangeBodySchema = z.object({
  provider: authProviderSchema,
  proof: z.string().min(1)
});
export type ExchangeBody = z.infer<typeof exchangeBodySchema>;

export type AuthExchangeResponse = {
  account_id: string;
  session_token: string;
  expires_at_unix: number;
  is_new_account: boolean;
};
